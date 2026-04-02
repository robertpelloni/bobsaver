#version 420

// original https://www.shadertoy.com/view/WtcXWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time .7 * time
#define ZPOS -10.

float PI = acos(-1.);

float wave(float tempo) {
    return .5 * sin(time * tempo) + .5;
}

mat2 rot2d(float a) {
    float c = cos(a), s = sin(a);
    
    return mat2(c, s, -s, c); 
}

vec3 kifs(vec3 p) {
    float s = 1.;
//    float t = floor(time) + smoothstep(.0, 1., fract(time));
      float t = time * .3;
    for (float i = 0.; i < 1.; i++) {
        p.xy *= rot2d(t);
        p.yz *= rot2d(.9 * t + i * .7);
        p = abs(p);
        p -= s;
//        s *= .6 + .2 * sin(time / 1.5);
        s *= .7;
    }
    
    return p;
}

float sphere(vec3 p, float r) {
    return length(p) - r;
}

float tube(vec3 p, vec3 a, vec3 b, float r) {
    vec3 ab = b - a;
    vec3 ap = p - a;
    float t = dot(ab, ap) / dot(ab, ab);
//    t = clamp(t, 0., 1.);
    vec3 c = a + ab * t;
    
    return length(p - c) - r;
}

vec3 rep(vec3 p, vec3 r) {
    vec3 q = mod(p, r) - .5 * r;
    
    return q;
}

float at = 0.;
float map(vec3 p) {
//    p.xy *= rot2d(cos(time) * sin(p.z / 3.));
    vec3 rawP = p;
//    p = kifs(p);
    p = rep(p, vec3(1. + wave(.65), 2. + wave(.6), 1.5 + wave(.7)));
    
    float d = 5000.;

//    d = min(d, sphere(p, 1.));
    d = min(d, tube(p, vec3(0, -2, 0), vec3(0, 2, 0), .1));
    d = min(d, tube(p, vec3(-2, 0, 0), vec3(2, 0, 0), .1));
    d = min(d, tube(p, vec3(0, 0, 2), vec3(0, 0, -2), .1));
//    d = max(d, -sphere(rawP, 10.));
    
    at += .05 / (.1 + 5. * d);
    
    return d;
}

vec3 glow = vec3(0);
float rm(vec3 ro, vec3 rd) {
    float d = 0.;
    
    for (int i = 0; i < 300; i++) {
        vec3 p = ro + d * rd;
        float ds = map(p);
        
        if (ds < 0.01 || ds > 100.) {
            break;
        }
        
        d += ds * .5;
//        glow += .015 * at * vec3(.8, .5 * sin(time / 1.) + .5, .5 * cos(time / 5.) + .5);
        glow += .001 * at * vec3(.8, wave(.5) * cos(.1 * p.z), 0);
    }
    
    return d;
}

vec3 normal(vec3 p){
    vec2 e = vec2(0.01, 0);
    
    vec3 n = normalize(map(p) - vec3(
        map(p - e.xyy),
        map(p - e.yxy),
        map(p - e.yyx)
    ));
  
   return n;                 
}

float light(vec3 p) {
    vec3 lp = vec3(0, 0, ZPOS);
    vec3 tl = lp - p;
    vec3 tln = normalize(tl);
    vec3 n = normal(p);
    float dif = dot(n, tln);
    float d = rm(p + .01 * n, tln);
    
    if (d < length(tl)) {
        dif *= .1;
    }
    
    return dif;
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    vec3 ro = vec3(0, 0, ZPOS);
    vec3 rd = normalize(vec3(uv, 1.));
    float d = rm(ro, rd);
    vec3 p = ro + d * rd;
    float dif = light(p);
    
    vec3 col = dif * glow;
//    vec3 col = vec3(dif);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
