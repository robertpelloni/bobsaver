#version 420

// original https://www.shadertoy.com/view/3slXRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "ShaderToy Tutorial - Ray Marching for Dummies!" 
// by Martijn Steinrucken aka BigWings/CountFrolic - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// This shader is part of a tutorial on YouTube
// https://youtu.be/PGtv-dBi2wE

#define MAX_STEPS 100
#define MAX_DIST 50.
#define SURF_DIST .001

#define WALL_AMP 1.0
#define LIGHTA_AMP 3.0
#define LIGHTB_AMP 3.0
#define LIGHTC_AMP 3.0

const float PI = 3.1457;

float bpm() { return 128.5; }
float beats_per_bar() { return 4.; }
float bar() { return time * bpm() / 60.0 / beats_per_bar(); }
float bar_phase() { return mod(bar(), 1.0); }
float bar2_phase() { return mod(bar(), 2.0) / 2.0; }
float bar4_phase() { return mod(bar(), 4.0) / 4.0; }
float bar8_phase() { return mod(bar(), 8.0) / 8.0; }
float bar16_phase() { return mod(bar(), 16.0) / 16.0; }
float beat() { return time * bpm() / 60.0; }
float beat_phase() { return mod(beat(), 1.0); }
float minim_phase() { return mod(beat()*0.5, 1.0); }
float quaver_phase() { return mod(beat()*2.0, 1.0); }
float semiquaver_phase() { return mod(beat()*4.0, 1.0); }

float max_dist() {
    //return bar8_phase() * MAX_DIST;
    //return pow(sin(bar16_phase()*PI*2.0)*0.5+0.5, 1.) * MAX_DIST;
    return MAX_DIST;
}

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sqr(float phase) {
    return float(int(phase * 2.0))*0.5;
}

float rand(float n){return fract(sin(n) * 43758.5453123);}

float noise(float p){
    float fl = floor(p);
    float fc = fract(p);
    return mix(rand(fl), rand(fl + 1.0), fc);
}

vec3 blackbody(float Temp) {
    vec3 col = vec3(255.);
   col.x = 56100000. * pow(Temp,(-3. / 2.)) + 148.;
      col.y = 100.04 * log(Temp) - 623.6;
      if (Temp > 6500.) col.y = 35200000. * pow(Temp,(-3. / 2.)) + 184.;
      col.z = 194.18 * log(Temp) - 1448.6;
      col = clamp(col, 0., 255.)/255.;
   if (Temp < 1000.) col *= Temp/1000.;
      return col;
}

float dBox(vec3 p, vec3 s) {
    return length(max(abs(p)-s, 0.));
}

float dSphere(vec3 p, float r) {
    return length(p)-r;
}

float wall_dist(vec3 p) {
    vec3 pos = vec3(0.0, 0.0, 10.0 + (sin(bar8_phase()*PI*2.0) * 0.5 + 0.5) * WALL_AMP);
    vec3 dim = vec3(1000.0, 1000.0, 1.0);
    return dBox(p-pos, dim);
}

float GetDist(vec3 p) {
    vec4 s = vec4(0, 1, 6, 1);
    float sphere_d =  dSphere(p-vec3(0, 1, 8), 1.);
    float wall_d = wall_dist(p);    
    float d = wall_d;
    d = min(d, sphere_d);
    return d;
}

float shadow_march(vec3 ro, vec3 rd, float min_light, float light_dist, float k) {
    float res = 1.0;
    float ph = 1e20;
    float maxt = min(max_dist(), light_dist);
    for (float t=min_light; t < maxt;) {
        vec3 p = ro + rd*t;
        float h = GetDist(p);
        if (h<SURF_DIST) {
            return 0.0;
        }
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>max_dist() || dS<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

float step_phase(float phase, int steps) {
    return float(int(phase * float(steps))) / float(steps);
}

float lighta_phase() {
    return bar4_phase();
}

float lightb_phase() {
    return bar16_phase();
}

float lightc_phase() {
    return bar8_phase();
}

float lighta_phase_stepped() {
    return float(int(lighta_phase() * 4.0))/4.0;
    //return bar4_phase();
}

vec3 lighta_pos() {
    vec3 p = vec3(0, 0, 4.0 + 2.*sin(bar16_phase()*PI*2.));
    float phase = lighta_phase();
    p.xy += vec2(sin(phase*PI*2.), cos(phase*PI*2.))* 20.0;
    p.xy += vec2(sin(phase*PI*2.), cos(phase*PI*2.))*2.;
    return p;
}

vec3 lightb_pos() {
    vec3 p = vec3(0, 0, 4. + 2.*sin(bar8_phase()*PI*2.));
    float phase = lightb_phase();
    p.xy += vec2(sin(phase*PI*2.), cos(phase*PI*2.))* 20.0;
    p.xy += vec2(sin(phase*PI*2.), cos(phase*PI*2.))*2.;
    return p;
}

vec3 lightc_pos() {
    vec3 p = vec3(0, 0, 4. + 2.*sin(bar4_phase()*PI*2.));
    float phase = lightc_phase();
    p.xy += vec2(sin(phase*PI*2.), cos(phase*PI*2.))* 20.0;
    p.xy += vec2(sin(phase*PI*2.), cos(phase*PI*2.))*2.;
    return p;
}

float GetLight(vec3 p, vec3 lp) {
    vec3 l = normalize(lp-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    float d = RayMarch(p+n*SURF_DIST*2., l);
    if(d<length(lp-p)) dif *= .1;
    
    
    float min_light = 0.1;
    float light_dist = 1.0;
    float k = 0.25;
    float s = shadow_march(p+n*SURF_DIST*2., l, min_light, light_dist, k);
    
    return dif * s;
}

vec3 render(vec2 uv) {
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 1, -10.);
    vec3 rd = normalize(vec3(uv.x, uv.y, (sin(bar4_phase()*PI*2.)*0.1+0.9)));

    float d = RayMarch(ro, rd);
    
    vec3 p = ro + rd * d;
    
    float la = GetLight(p, lighta_pos()) * LIGHTA_AMP;
    float lb = GetLight(p, lightb_pos()) * LIGHTB_AMP;
    float lc = GetLight(p, lightc_pos()) * LIGHTC_AMP;
    
    vec3 ca = vec3(la);
    vec3 cb = vec3(lb);
    vec3 cc = vec3(lc);
    
    ca = blackbody(la*2000.);
    cb = blackbody(lb*2000.);
    cc = blackbody(lc*2000.);
    
    col = ca + cb + cc;
    col = mix(col, vec3(length(col)), (sin(bar16_phase()*2.0*PI)*0.5+0.5));
    //col = vec3(length(col));
    return col;
}

vec3 render_msaa(vec2 uv, int samples) {
    int samples_per_side = samples / 2;
    int half_samples_per_side = samples_per_side / 2;
    int loop_end = samples_per_side - half_samples_per_side;
    int loop_start = loop_end - samples_per_side;
    float sample_step = 1.0 / resolution.x;
    vec3 acc = vec3(0.0);
    for (int x = loop_start; x < loop_end; x++) {
        for (int y = loop_start; y < loop_end; y++) {
            vec2 coords = uv + vec2(float(x) * sample_step, float(y) * sample_step);
            acc += render(coords);
        }
    }
    return acc / float(samples_per_side * 2);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    //vec3 col = vec3(render_msaa(uv, 4));
    vec3 col = vec3(render(uv));
    glFragColor = vec4(col,1.0);
}
