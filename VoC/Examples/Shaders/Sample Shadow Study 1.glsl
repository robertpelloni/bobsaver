#version 420

// original https://www.shadertoy.com/view/tslXR2

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

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001

// 0.0 no lights, 1.0 all lights.
#define LIGHTS_AMP 1.0

// 0.0 no light, 10.0 powerful light.
#define LIGHT1_AMP 5.0
#define LIGHT2_AMP 2.0
#define LIGHT3_AMP 0.

// 0.0 no pillar, 1.0 default.
#define PILLAR_WIDTH 1.0
// 0.0 no pillar, 30.0 can't see top.
//#define PILLAR_HEIGHT 30.0
#define PILLAR_HEIGHT 1.0
// 0.0 no pillar, 6.0 fully sealed.
#define PILLAR_LENGTH 3.7

// Multiplier for the subtle humanish gimble movement.
// 0.0 is none, 5.0 is max.
#define GIMBLE_MOVEMENT 1.0
// 0.0 is none, 10.0 is weird shakey.
#define GIMBLE_FREQ 1.0

// Light RGBs
#define LIGHT1_COL vec3(0.2, 0.5, 0.8)
#define LIGHT2_COL vec3(0.0, 1.0, 1.0)
#define LIGHT3_COL vec3(1.0)

#define MODULO_STEP_Z 10.0
#define MODULO_STEP_X 20.0

const float PI = 3.1457;

float bpm() { return 126.0; }
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

float light1_z_phase() { return bar_phase(); }
float light2_z_phase() { return bar4_phase(); }
float light_z_max() { return MODULO_STEP_Z * 16.0; }
float cam_z_phase() { return bar16_phase(); }

#define NUM_SHAPES 2
float shape_shift_phase() { return minim_phase(); }
int shape_index() { return int(floor(shape_shift_phase() * float(NUM_SHAPES))); }

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 ab = b-a;
    vec3 ap = p-a;
    float t = dot(ab, ap) / dot(ab, ab);
    t = clamp(t, 0., 1.);
    vec3 c = a + t*ab;
    return length(p-c)-r;
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r) {
    vec3 ab = b-a;
    vec3 ap = p-a;
    float t = dot(ab, ap) / dot(ab, ab);
    //t = clamp(t, 0., 1.);
    vec3 c = a + t*ab;
    float x = length(p-c)-r;
    float y = (abs(t-.5)-.5)*length(ab);
    float e = length(max(vec2(x, y), 0.));
    float i = min(max(x, y), 0.);
    return e+i;
}

float sdTorus(vec3 p, vec2 r) {
    float x = length(p.xz)-r.x;
    return length(vec2(x, p.y))-r.y;
}

float dBox(vec3 p, vec3 s) {
    return length(max(abs(p)-s, 0.));
}

float sdSphere(vec4 s) {
    return length(s.xyz) - s.w;
}

float GetDist(vec3 p) {
    float plane_dist = p.y;
    
    // Position modulo for box.
    vec3 p_for_box = p;
    p_for_box.z = mod(p.z, MODULO_STEP_Z);
    p_for_box.x = mod(p.x, MODULO_STEP_X);
    p_for_box.y = mod(p.y, 2.0);
    vec3 pillar_dim = vec3(PILLAR_WIDTH, PILLAR_HEIGHT, PILLAR_LENGTH);
    vec3 pillar_pos = vec3(MODULO_STEP_X*0.5, 1.0, 6);
    float pillar_dist = dBox(p_for_box-pillar_pos, pillar_dim);
    
    // Position modulo for shape.
    vec3 p_for_shape = p;
    p_for_shape.z = mod(p.z, light_z_max() * 0.5);
    float shape_dist = 0.0;
    int shape_ix = shape_index();
    if (shape_ix == 0) {
          vec4 s = vec4(0, 1, 6, 0.5);
        shape_dist = sdSphere(vec4(p_for_shape-s.xyz, s.w));
    } else if (shape_ix == 1) {
        vec3 bpos = vec3(0, 1, 6);
        vec3 bdim = vec3(1, 1, 1) * 0.5;
        shape_dist = dBox(p_for_shape-bpos, bdim);
    } else {
        // TODO: Add more shapes?
        //float cd = sdCapsule(p, vec3(3, .5, 6), vec3(3, 2.5, 6), .5); 
        //float td = sdTorus(p-vec3(0,.5,6), vec2(1.5, .4));
        //float cyld = sdCylinder(p, vec3(0, .3, 3), vec3(3, .3, 5), .3);
    }    
    
    
    float d = plane_dist;
    d = min(d, pillar_dist);
    d = min(d, shape_dist);
    
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

float shadow_march(vec3 ro, vec3 rd, float min_light, float light_dist, float k) {
    float res = 1.0;
    float ph = 1e20;
    for( float t=min_light; t < light_dist; ) {
        vec3 p = ro + rd*t;
        float h = GetDist(p);
        if(h<SURF_DIST)
            return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}

vec3 GetNormal(vec3 p) {
        //p.z = mod(p.z, 10.0);

    float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 light1() {
    //vec3 pos = vec3(-.625*MODULO_STEP_X, 6, -0.5*MODULO_STEP_Z);
    vec3 pos = vec3(-.625*MODULO_STEP_X, 6, 0.0);
    pos.z += light1_z_phase() * light_z_max();
    return pos;
}

vec3 light1_col() {
    return LIGHT1_COL;
}

vec3 light2() {
    vec3 pos = vec3(.625*MODULO_STEP_X, 10, 0.0);
    pos.z += light2_z_phase() * light_z_max();
    return pos;
}

vec3 light2_col() {
    return LIGHT2_COL;
}

vec3 light3() {
    vec3 pos = vec3(1, 4, light_z_max()*0.5+2.);
    pos.xz += vec2(sin(time), cos(time))*2.;
    return pos;
}

vec3 light3_col() {
    return LIGHT3_COL;
}

float GetLight(vec3 p, vec3 light_p) {
    p.z = mod(p.z, light_z_max());
    vec3 l = normalize(light_p-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    float d = RayMarch(p+n*SURF_DIST*2., l);
    if(d<length(light_p-p)) dif *= .1;

    float s = shadow_march(p+n*SURF_DIST*2., l, 0.1, 1., 0.5);
    //s = 1.;

    return dif*s;
}

vec3 render(vec2 uv) {
    vec3 col = vec3(0);
    
    vec3 cam_pos = vec3(0, 2, 0);
    cam_pos.xyz += vec3(sin(time*0.4*GIMBLE_FREQ), cos(time*0.37*GIMBLE_FREQ), sin(time*GIMBLE_FREQ)*0.5)*0.25*GIMBLE_MOVEMENT;
    
    cam_pos.z += cam_z_phase() * light_z_max();
    
    
    float cam_yaw = uv.x-.07;
    float cam_pitch = uv.y-.2;
    
    //cam_yaw += mouse*resolution.xy.x * PI * 4.0 / resolution.x - PI * 2.0;
    //cam_pitch += mouse*resolution.xy.y * PI * 2.0 / resolution.y - PI;
    
    vec3 rd = normalize(vec3(cam_yaw, cam_pitch, 1));

    float d = RayMarch(cam_pos, rd);
    
    vec3 p = cam_pos + rd * d;
    
    vec3 l1 = light1_col() * GetLight(p, light1());
    vec3 l2 = light2_col() * GetLight(p, light2());
    vec3 l3 = light3_col() * GetLight(p, light3());

    float fade_dist = 1.0 - pow(d / MAX_DIST, 2.);
    col = (l1*LIGHT1_AMP + l2*LIGHT2_AMP + l3*LIGHT3_AMP) * LIGHTS_AMP * fade_dist;
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

    
    
    //glFragColor = vec4(render_msaa(uv, 4),1.0);
    glFragColor = vec4(render(uv),1.0);
}
