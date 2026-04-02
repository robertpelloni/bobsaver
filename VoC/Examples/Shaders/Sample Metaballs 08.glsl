#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/MlByzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
 * Here are very simple if not lame 2D/3D blobs, without any kind of perspective projection.  
 * Greetz to all members of PROXiUM: guys, coding of shaders is a real fun, just like in good ol' dayz =)
 *
 *  -={   Asman   }=-
 *  -={ mr.Dsteuz }=-
 *  -={  Markoos  }=-
 *
 *  More greetz to Manwe/SandS, and all folks from Moscow scene...
 * 
 */

#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

// CONTROLS
// Set to 1 for simple bumpmapping
#define BUMP_NOISE 0
// Set to 1 for stupid scanlines
#define SCANLINES 0

// CONSTANTS
#define SPHERES 10
#define BISECT_LIMIT 50
#define BISECT_GOAL 0.001
#define LIGHTS 2
#define SCENE_ROTATION    -0.2

uniform sampler2D backbuffer;
uniform sampler2D noise;

float scale;

struct FieldPoint {
    vec3 pos;
    float field;
};

FieldPoint uvp;

vec3[SPHERES] s = vec3[SPHERES](
    vec3(0.1, -0.02, 0.024),
    vec3(0.04, 0.06, 0.007),
    vec3(-0.02, -0.02, 0.018),
    vec3(-0.017, 0.045, 0.012),
    vec3(0.1, 0.31, 0.017),
    vec3(0.032, -0.012, 0.019),
    vec3(0.08, -0.042, 0.021),
    vec3(-0.067, -0.01, 0.0141),
    vec3(0.029, -0.032, 0.0119),
    vec3(-0.028, 0.054, 0.0229));

vec2[SPHERES] ms;
float[SPHERES] frc;

vec4[SPHERES] clr = vec4[SPHERES] (
    vec4(0.98, 0.21, 0.17, 1.0),
    vec4(0.09, 0.2, 0.75, 1.0),
    vec4(0.45, 0.32, 0.12, 1.0),
    vec4(0.02, 0.78, 0.92, 1.0),
    vec4(0.98, 0.21, 0.17, 1.0),
    vec4(0.09, 0.2, 0.75, 1.0),
    vec4(0.45, 0.32, 0.12, 1.0),
    vec4(0.98, 0.21, 0.17, 1.0),
    vec4(0.09, 0.2, 0.75, 1.0),
    vec4(0.02, 0.78, 0.92, 1.0));

vec3[SPHERES] offset = vec3[SPHERES] (
    vec3(0.25, -0.32, 1.7),
    vec3(-0.13, 0.02, 2.4),
    vec3(-0.07, 0.3, 0.2),
    vec3(0.26, -0.168, 1.92),
    vec3(0.12, 0.22, 0.7),
    vec3(0.25, -0.63, 0.4),
    vec3(0.185, 0.19, 3.2),
    vec3(-0.092, -0.075, 0.9),
    vec3(0.03, 0.17, 1.5),
    vec3(0.014, -0.08, 0.82));

struct Light {
    vec3 p;
    vec3 pr;
    vec3 c;
    float i;
    float fuzz;
    float rotSpd;
};

Light[LIGHTS] l = Light[LIGHTS] (
        Light(
                vec3(-1.0, 1.0, 2.0),
                vec3(0.0),
                vec3(1.0, 0.8, 0.6),
                0.65, 1500.0, 1.0),
        Light(
                vec3(1.0, -1.0, 1.0),
                vec3(0.0),
                vec3(0.0, 0.0, 0.9),
                .93, 90.0, -0.32)
    );

// RASTER DATA
#define PROXiUM_LOGO_X_SIZE 64
#define PROXiUM_LOGO_Y_SIZE 11

struct Sprite {
    int w;
    int h;
    int x;
    int y;
};

Sprite PROXiUM_Logo = Sprite( 
    PROXiUM_LOGO_X_SIZE,
    PROXiUM_LOGO_Y_SIZE,
    0,0
);

int[] PROXiUM_LogoBitmap = int[](
        0x1ffffeed, 0xb77ffffc, 0x30000000, 0x00000006, 
        0x6639c000, 0x00022923, 0x694a4000, 0x00036903, 
        0xc94a4000, 0x0002a931, 0xc94a4000, 0x00022921, 
        0x6939c000, 0x00022923, 0x69484000, 0x00022923, 
        0x66484000, 0x00022673, 0x30000000, 0x00000006, 
        0x1ffffeed, 0xb77ffffc);

// PROCEDURES AND FUNCTIONS

int getLogoPixel(Sprite s, vec2 t){
    int addr = int(floor(t.y)) * (s.w / 32) + (int(t.x) / 32);
    int raster = PROXiUM_LogoBitmap[addr];
    int b = (raster >> (int(t.x) % 32)) & 0x01;
    return b;
}

int displayLogo(vec2 scr){
    scr = floor(scr);
    int b = 0;
    if ((int(scr.x) >= PROXiUM_Logo.x) && 
        (int(scr.y) >= PROXiUM_Logo.y) &&
        (int(scr.x) < PROXiUM_Logo.x + PROXiUM_Logo.w) && 
        (int(scr.y) < PROXiUM_Logo.y + PROXiUM_Logo.h)) {
           b = getLogoPixel(
            PROXiUM_Logo,
            vec2(scr.x - float(PROXiUM_Logo.x), float(PROXiUM_Logo.h - 1) - (scr.y - float(PROXiUM_Logo.y))));
    }
    return b;
}

highp float rand(vec2 co) {
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return abs(fract(sin(sn) * c));
}

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec2 movedS(int idx) {
    float t = time * 0.5;
    return vec2(s[idx].x + sin(t) * offset[idx].x,
        s[idx].y + cos(t * offset[idx].z) * offset[idx].y);
}

void moveSpheres() {
    mat4 rm = rotationMatrix(vec3(0.0, 0.0, 1.0), time * SCENE_ROTATION);
    for (int i = 0; i < SPHERES; i++){
        ms[i] = (vec4(movedS(i), 0.0, 1.0) * rm).xy;
    }
}

void rotateLights() {
    mat4 rm;
    for (int i = 0; i < LIGHTS; i++) {
        rm = rotationMatrix(vec3(0.0, 0.0, 1.0), time * l[i].rotSpd);
        l[i].pr = (vec4(l[i].p, 1.0) * rm).xyz;
    }
}

float force(vec2 coord, int idx) {
    return s[idx].z / distance(ms[idx], coord);
}

float force3D(vec3 coord, int idx) {
    float f = 0.0;
    f  = s[idx].z / distance(vec3(ms[idx], 0.0), coord);
    return f;
}

void calcForce() {
    for (int i = 0; i < SPHERES; i++) {
        frc[i] = force(uvp.pos.xy, i);
    }
}

float field(vec2 coord) {
    float f = 0.0;
    for (int i = 0; i < SPHERES; i++) {
        f += frc[i];
    }
  return f;
}

float field3D(vec3 coord){
    float f = 0.0;
    for (int i = 0; i < SPHERES; i++) {
        f += force3D(coord, i);
    }
    return f;
}

float height(vec2 coord){
  float h = 0.0;
  float hb = 0.0;
  float ht = 1.0;
  float pb = field3D(vec3(coord.xy, hb));
  if (pb <= 1.0) return 0.0;
  float pm;
  float pt = field3D(vec3(coord.xy, ht));

  for (int i = 0; i < BISECT_LIMIT; i++) {
      float hm = hb + (ht - hb) * 0.5;
      float pm = field3D(vec3(coord.xy, hm));
    if (pm < 1.0) {
        ht = hm;
        pt = pm;
    } else {
      hb = hm;
      pb = pm;
    }
    if (pb - pt < BISECT_GOAL) break;
  }

  h = hb + (ht - hb) * ((pb - 1.0) / (pb - pt));
  return h;
}

vec3 getN() {
   vec3 n;
    
   n = vec3(
       field3D(vec3(uvp.pos.x - scale, uvp.pos.yz)) - field3D(vec3(uvp.pos.x + scale, uvp.pos.yz)),
       field3D(vec3(uvp.pos.x, uvp.pos.y - scale, uvp.pos.z)) - field3D(vec3(uvp.pos.x, uvp.pos.y + scale, uvp.pos.z)),
       field3D(vec3(uvp.pos.xy, uvp.pos.z - scale)) - field3D(vec3(uvp.pos.xy, uvp.pos.z + scale)));

   #if BUMP_NOISE > 0
   n += rand(uvp.pos.xy) * 0.001;
   #endif 
    
   return normalize(n);
}

vec4 colorize(){
    vec4 c = vec4(0);
    for (int i = 0; i < SPHERES; i++) {
        c +=  clr[i] * pow(frc[i], 1.2);
    }
  return c;
}

vec3 getLight() {
    float light = 0.0;
    vec3 color = vec3 (0.0);
    vec3 normal = getN();

    for (int i = 0; i < LIGHTS; i++) {
        vec3 lv = normalize(l[i].pr - uvp.pos);
        vec3 specv = normalize(lv + normal);
        float k = pow(dot(lv, specv), l[i].fuzz);
        light += dot(normal, lv) * l[i].i;
        color += (l[i].c * (k + light)) / float(LIGHTS);
    }

    return color;
}

void main(void) {
    int logoScale = 4;
    if (resolution.x <= 450.0) logoScale = 2;
    
    PROXiUM_Logo.x = (int(floor(resolution.x)) / logoScale) - (PROXiUM_LOGO_X_SIZE + 5);
    PROXiUM_Logo.y = (8 + PROXiUM_LOGO_Y_SIZE) / logoScale;
    
    float aspect = resolution.x / resolution.y;
    if (aspect >= 1.0) {
        scale = 1.0 / resolution.x;
    } else {
        scale = 1.0 / resolution.y;
    }
    
    vec2 uv = (gl_FragCoord.xy * scale) - (resolution.xy * scale * 0.5);
    
    moveSpheres();
    rotateLights();
    uvp.pos = vec3(uv, 0.0);
    calcForce();
    uvp.field = field(uv);
    
    vec4 c;
    
    if (uvp.field < 1.0)
        c = vec4(vec3(uvp.field), 1.0) * colorize();
    else {
        uvp.pos.z = height(uv);
        float tr = uvp.pos.z * 4.0;
        vec4 transDiffuseSpec = vec4(getLight(), 1.0) + vec4(tr * 0.4, tr * 0.87, tr * 0.99, 1.0);
        c = (transDiffuseSpec) + (colorize() / 8.0);
    }
    
    if (displayLogo(gl_FragCoord.xy / float(logoScale)) > 0) {
        //RASTER LOGO
        c = vec4(1.0);
    } else {
        //POSTPROCESSING
        c = c + rand(time * uv) * 0.02;
#if SCANLINES > 0        
        if (int(floor(gl_FragCoord.y / 4.0)) % 2 == 0) {
            c *= 0.7;
        }
#endif        
    }
    
    glFragColor = c;
}
