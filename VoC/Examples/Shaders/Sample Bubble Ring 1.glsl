#version 420

// original https://www.shadertoy.com/view/XsByWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// training for modeling shapes
// using koltes code as base https://www.shadertoy.com/view/XdByD3
// using iq articles
// using mercury library

#define PI 3.14159
#define TAU PI*2.
#define t time

mat2 rz2 (float a) { float c=cos(a), s=sin(a); return mat2(c,s,-s,c); }
float sphere (vec3 p, float r) { return length(p)-r; }
float iso (vec3 p, float r) { return dot(p, normalize(sign(p)))-r; }
float cyl (vec2 p, float r) { return length(p)-r; }
float cube (vec3 p, vec3 r) { return length(max(abs(p)-r,0.)); }
vec2 modA (vec2 p, float count) {
    float an = TAU/count;
    float a = atan(p.y,p.x)+an*.5;
    a = mod(a, an)-an*.5;
    return vec2(cos(a),sin(a))*length(p);
}
float smin (float a, float b, float r)
{
    float h = clamp(.5+.5*(b-a)/r,0.,1.);
    return mix(b, a, h) - r*h*(1.-h);
}

float map (vec3 p)
{
    
    p.xz *= rz2(.5);
    p.xy *= rz2(t*.5);
    p.yz *= rz2(t*.3);
    
    float cyl2wave = .1+.7*(sin(p.z+t*2.)*.5+.5);
    float cylfade = 1.-smoothstep(.0,6.,abs(p.z));
    float cyl2r = 0.02*cyl2wave*cylfade;
    float cylT = 2.;
    float cylC = 8.;
    vec2 cyl2p = modA(p.xy*rz2(p.z*cylT), cylC)-vec2(cyl2wave, 0)*cylfade;
    float cyl2 = cyl(cyl2p, cyl2r);
    cyl2p = modA(p.xy*rz2(-p.z*cylT), cylC)-vec2(cyl2wave, 0)*cylfade;
    cyl2 = smin(cyl2, cyl(cyl2p, cyl2r),.1);
    cyl2p = modA(p.xy*rz2(-p.z*cylT), cylC*.5)-vec2(cyl2wave, 0)*cylfade;
    cyl2 = smin(cyl2, iso(vec3(cyl2p,mod(p.z*2.,1.)-.5), .2*cyl2wave),.1);
    
    vec3 cubP = p;
    float cubC = 0.5;
    cubP.z -= t*2.;
    float cubI = floor(cubP.z / cubC);
    cubP.z = mod(cubP.z, cubC)-cubC*.5;
    cubP.xy *= rz2(t*2.+cubI*4.);
    cubP.yz *= rz2(t*3.+cubI*8.);
    cyl2 = min(cyl2, cube(cubP,vec3(.35*cyl2wave*cylfade)));
    
    float a = atan(p.y,p.x);
    float l = length(p.xy)-2.;
    p.xy = vec2(l,a);
    
    //p.z += a;
    
    float wave = (sin(p.y+t)*.5+.5);
    
    float sphR = wave*0.5;
    float sphC = 1.;
    float sph1 = sphere(vec3(p.x,mod(3.*(p.y/TAU+t),sphC)-sphC*.5,p.z), sphR);
    
    float iso1 = iso(p, 0.2);
    
    p.xz *= rz2(p.y*3.*wave);
    p.xz = modA(p.xz, 3.);
    p.x -= wave*(.85-.5*(.5+.5*sin(6.*(p.y+t))));
    float cyl1 = cyl(p.xz, 0.02);
    float sph2 = sphere(vec3(p.x,mod(p.y*2.,1.)-.5,p.z), .2*wave);
    
    return min(cyl2, smin(sph1, smin(cyl1,sph2,.1), .1));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 ro = vec3(uv,-4), rp = vec3(uv,1), mp = ro;
    int i = 0;
    const int count = 50;
    for(;i<count;++i) {
        float md = map(mp);
        if (md < 0.001) {
            break;
        }
        mp += rp*md*.5;
    }
    float r = float(i)/float(count);
    glFragColor = vec4(1);
    glFragColor *= 1.-smoothstep(.0,5.,length(mp));
    glFragColor *= 1.-smoothstep(5.,10.,length(mp-ro));
    glFragColor *= 1.-r;
}
