#version 420

// original https://www.shadertoy.com/view/3lSyDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Simple Hexagon Truchet tiling
//
// Not the best code so please forgive the mess!
// trying to figure out the truchet tile part
// using rotation - but unspooled
// need to figure a better way but this what I 
// came up with...

#define PI          3.1415926
#define PI2         6.2831
#define R             resolution
#define M             mouse*resolution.xy
#define T             time
#define S             smoothstep
#define r2(a)  mat2(cos(a), sin(a), -sin(a), cos(a))
// I havent made my own good hash function yet...
// https://www.shadertoy.com/view/wsjfRD
// A white noise function.
float rand(vec3 p) {
    return fract(sin(dot(p, vec3(12.345, 67.89, 412.12))) * 42123.45) * 2.0 - 1.0;
}
// A perlin noise function.
float perlin(vec3 p) {
    vec3 u = floor(p);
    vec3 v = fract(p);
    vec3 s = smoothstep(0.0, 1.0, v);
    
    float a = rand(u);
    float b = rand(u + vec3(1.0, 0.0, 0.0));
    float c = rand(u + vec3(0.0, 1.0, 0.0));
    float d = rand(u + vec3(1.0, 1.0, 0.0));
    float e = rand(u + vec3(0.0, 0.0, 1.0));
    float f = rand(u + vec3(1.0, 0.0, 1.0));
    float g = rand(u + vec3(0.0, 1.0, 1.0));
    float h = rand(u + vec3(1.0, 1.0, 1.0));
    return mix(mix(mix(a, b, s.x), mix(c, d, s.x), s.y),
               mix(mix(e, f, s.x), mix(g, h, s.x), s.y),
               s.z);
}

// hex functions
float hd(vec2 p) {return max(dot(abs(p),normalize(vec2(1.,1.73))),abs(p.x)); }

vec4 hx(vec2 p) {
    vec2 r = vec2(1.,1.73),
         hr = r*.5,
         GA = mod(p,r)-hr,
         GB = mod(p-hr,r)-hr,
         Gz = dot(GA,GA)<dot(GB,GB) ? GA : GB; 
    return vec4(atan(Gz.x,Gz.y),0.5-hd(Gz),Gz);
}

float circle(vec2 pt, float r, vec2 center, float lw) {
      float len = length(pt - center);
      float hlw = lw / 2.;
      float edge = .005;
      return S(r-hlw-edge,r-hlw, len)-S(r+hlw,r+hlw+edge, len);
}

float circle(vec2 pt, float r, vec2 center) {
      float edge = .005;
      return 1.-S(r-edge,r+edge, length(pt - center));
}

// outline arm
float tout(vec2 p, float a) {
    vec2 sz = vec2(.45,.13);
    float pzx = .58; // circle center offset.
    float thk = .02;  // I like them thick and I cannot lie 
    p.xy*=r2(a*PI/180.); 
    
    float sum = circle(p.xy,sz.x,vec2(0.,pzx),thk);
    sum += circle(p.xy,sz.y,vec2(0.,pzx),thk);
    return sum;
}

// solid arm
float tarm(vec2 p, float a) {
    float sz = .29;
    float pzx = .58; // circle center offset.
    float thk = .2;  // I like them thick and I cannot lie

    p.xy*=r2(a*PI/180.); 
    return circle(p.xy,sz,vec2(0.,pzx),thk);
}

vec3 pattern(in vec2 p) {
    p.y+=T*.15;
    p = p*3.5;
    
    vec4 H = hx(p);
    vec2 Hid = (p-H.zw);
    vec4 G = hx(p+vec2(.0,1.173));
    vec2 Gid = (p-G.zw);
    vec3 C = vec3(0.);
    
    float hex = S(.011,.012,H.y);

    float h2 = perlin(vec3(Gid.x,Gid.y,T*.2));
    float h3 = perlin(vec3(Hid.x,Hid.y,256.)); 
    
    float gz = h3-h2;

    vec3 h = .5 + .35*cos(PI2*gz/.5 + vec3(0.,2., 2.));
    vec3 hf = .5 + .45*cos(PI2*h3/.25 + vec3(2.,0., 2.));
    
    float sz = .29;
    float pzx = .58; // circle center offset.
    float thk = .2;  // I like them thick and I cannot lie
    float csum = 0.; //sum of main pattern
    float lsum = 0.; //sum of outlines
    if(h3>.05){
        csum += tarm(H.zw,60.);
        csum += tarm(H.zw,180.);
        csum += tarm(H.zw,300.);
        lsum += tout(H.zw,60.);
        lsum += tout(H.zw,180.);
        lsum += tout(H.zw,300.);

    } else {

        csum += tarm(H.zw,120.);
        csum += tarm(H.zw,240.);
        csum += tarm(H.zw,360.);
        lsum += tout(H.zw,120.);
        lsum += tout(H.zw,240.);
        lsum += tout(H.zw,360.);
    }
    C = h/hex; 
    // uncomment to just see truchet
    //C = vec3(1.)*hex;
    
    C += -1.*lsum;
    C += -1.*csum*hf;
    return 1.-C;
}

void main(void) {
    vec2 U = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    vec3 C = vec3(0.);
    
    C = pattern(U);
    glFragColor = vec4(pow(max(C,0.), vec3(0.4545)),1.);
}
