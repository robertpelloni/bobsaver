#version 420

// original https://www.shadertoy.com/view/3dlSRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "ShaderToy Tutorial - Ray Marching Primitives" 
// by Martijn Steinrucken aka BigWings/CountFrolic - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// This shader is part of a tutorial on YouTube
// https://youtu.be/Ff0jJyyiVyw

#define MAX_STEPS 200
#define MAX_DIST 100.
#define SURF_DIST .001

// Light RGBs
#define LIGHT_COL vec3(1.0, 1.0, 1.0)
#define LIGHT_SPREAD 64.

#define BOX_SIZE 0.25

const float PI = 3.1457;

float bpm() { return 128.5; }
float beats_per_bar() { return 4.; }
float bar() { return time * bpm() / 60.0 / beats_per_bar(); }
float bar_phase() { return mod(bar(), 1.0); }
float bar4_phase() { return mod(bar(), 4.0) / 4.0; }
float bar8_phase() { return mod(bar(), 8.0) / 8.0; }
float bar16_phase() { return mod(bar(), 16.0) / 16.0; }
float beat() { return time * bpm() / 60.0; }
float beat_phase() { return mod(beat(), 1.0); }
float minim_phase() { return mod(beat()*0.5, 1.0); }
float quaver_phase() { return mod(beat()*2.0, 1.0); }
float semiquaver_phase() { return mod(beat()*4.0, 1.0); }

float light_rot_phase() { return beat_phase(); }
float light_spread_phase() { return bar16_phase(); }
float box_size() { return sin(bar_phase()*2.*PI)*BOX_SIZE; }

float light_spread() {
    return LIGHT_SPREAD - pow(sin(light_spread_phase()*PI*2.0)*0.5+0.5, 0.5) * LIGHT_SPREAD;
    //return LIGHT_SPREAD;
}

vec3 light_position() {
    vec3 pos = vec3(0, 5, 6);
    float spread = light_spread();
    float phase = light_rot_phase() * PI * 2.0;
    pos.xz += vec2(sin(phase), cos(phase))*spread;
    pos.y += sin(bar4_phase()*PI*2.0)*2.0;
    return pos;
}

float dBox(vec3 p, vec3 s) {
    return length(max(abs(p)-s, 0.));
}

float GetDist(vec3 p) {
    vec4 s = vec4(0, 1, 6, 1);
    
    float sphereDist = length(p-s.xyz)-s.w;//*sin(bar_phase()*PI*2.0);
    float planeDist = p.y;
    
    vec3 p_for_box = p;
    //p_for_box.z = mod(p_for_box.z, 10.0);
    p_for_box.x = mod(p_for_box.x, 8.0);
    p_for_box.y = mod(p_for_box.y, 2.0);
    vec3 boxp = vec3(4.0, 1.0, 10.0);
    vec3 boxdim = vec3(1., 1., 1.)*BOX_SIZE;
    float boxDist = dBox(p_for_box-boxp, boxdim);
    
    float d = min(sphereDist, planeDist);
    d = min(d, boxDist);
    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || dS<SURF_DIST) break;
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

float shadow_march(vec3 ro, vec3 rd, float min_light, float light_dist, float k) {
    float res = 1.0;
    float ph = 1e20;
    float maxt = min(MAX_DIST, light_dist);
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

float invert_phase() {
    return beat_phase();
}

float invert_lightness(float l) {
    return mix(l, 1.0-l, cos(invert_phase()*PI*2.));
}

float GetLight(vec3 p) {
    vec3 light_pos = light_position();

    vec3 l = normalize(light_pos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    float d = RayMarch(p+n*SURF_DIST*2., l);
    if(d<length(light_pos-p)) dif *= .1;
    float min_light = 0.2;
    float light_dist = 1.0;
    float k = 0.5;
    float s = shadow_march(p+n*SURF_DIST*2., l, min_light, light_dist, k);
    //s = 1.;
    
    return dif*s;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 1, 0);
    vec3 rd = normalize(vec3(uv.x, uv.y, 1.));//*bar16_phase()));

    float d = RayMarch(ro, rd);
    
    vec3 p = ro + rd * d;
    
    float dif = GetLight(p);
    float fade_dist = 1.0 - pow(d / MAX_DIST, 2.);
    //dif = invert_lightness(dif);
    col = LIGHT_COL * dif * fade_dist;
    
    
    glFragColor = vec4(col,1.0);
}
