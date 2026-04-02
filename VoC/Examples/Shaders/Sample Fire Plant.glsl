#version 420

// original https://www.shadertoy.com/view/4s2yDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// training for modeling shapes
// using koltes code as base https://www.shadertoy.com/view/XdByD3
// using iq articles
// using Mercury library
// using Sam Hocevar stackoverflow answer
#define PI 3.14159
#define TAU PI*2.
#define t time
struct Info { float dist; vec4 color; };
Info info;
mat2 rz2 (float a) { float c=cos(a),s=sin(a); return mat2(c,s,-s,c); }
float lfo (float o, float s) { return .5+.5*sin(t*s+o); }
float sphere (vec3 p, float r) { return length(p)-r; }
float cyl (vec2 p, float r) { return length(p)-r; }
float cyli (vec3 p, float r, float h) { return max(length(p.xz)-r, abs(p.y)-h); }
float iso (vec3 p, float r) { return dot(p,normalize(sign(p)))-r; }
float cube (vec3 p, vec3 r) { return length(max(abs(p)-r,0.)); }
float scol (float a, float b, float r) { return clamp(.5+.5*(b-a)/r,0.,1.); }
float smin (float a, float b, float r) { float h = scol(a,b,r); return mix(b,a,h)-r*h*(1.-h); }
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
vec3 moda (vec2 p, float c) {
    float ca = TAU/c;
    float a = atan(p.y,p.x)+ca*.5;
    float ci = floor(a/ca);
    a = mod(a,ca)-ca*.5;
    return vec3(vec2(cos(a),sin(a))*length(p), ci);
}

float leaf (vec3 p, float radius, float cycle, float index, vec2 scale) {
    p.xz *= rz2(index*.5);
    p.xz *= scale+lfo(index*5.,1.);
    p.y -= sin(p.z*1.5)*.3;
    p.z -= radius;
    p.y -= sin(abs(p.x)*3.)*.1;
    p.y = mod(p.y,cycle)-cycle*.5;
    return cyli(p, radius, 0.01);
}

vec3 torsade (vec3 p, float offset, float scale) {
    p.xz *= rz2(t+offset);
    float a = p.y * scale;
    p.xz -= vec2(cos(a),sin(a));
    return p;
}

float map (vec3 p) {
    
    float wave1 = lfo(p.y*.2,1.);
    vec3 pball = p;
    vec3 pk = p;
    
    p.yz *= rz2(sin(t*.5)*.5);
    p.xz *= rz2(t*.3);
    
    vec3 mosaic = moda(p.xz, 7.);
    mosaic.z *= 5.;
    float torsadeScale = (0.1 + lfo(mosaic.z,0.)) * wave1;
    p.xz = mosaic.xy;
    p.x -= 8.- 4.*wave1;
    //float cyclem = 5.;
    //p.x = mod(p.x-t, cyclem)-cyclem*.5;
    
    // leaves
    float radius = 1.*wave1;
    float cycle = 1.;
    float index = 0.;
    vec2 scale = vec2(1.2,.75);
    float offset = mosaic.z;
    index = floor(p.y/cycle) + mosaic.z;
       vec3 pleaves = torsade(p,offset, torsadeScale)+vec3(0,.5,0);
    float leaf1 = leaf(pleaves, radius, cycle, index, scale);
    float leaf2 = leaf(pleaves, radius, cycle, index+4., scale);
    float leaf3 = leaf(pleaves, radius, cycle, index+8., scale);
    float leaves = min(leaf1, min(leaf2, leaf3));
    
    // rod
    vec3 p2 = torsade(p,offset, torsadeScale);
    float rod = cyl(p2.xz, .05+.05*lfo(p.y*4.,0.));
    
    // ball
    float cycleb = 1.9;
    float cycled = 1.55;
    float speedb = 1.;
    float indexb = floor((pball.y+t*speedb)/cycleb);
    pball.y = mod(pball.y+t*speedb, cycleb)-cycleb*.5;
    pball.xz *= rz2(pball.y*.6);
    vec3 pdots = mod(pball,cycled)-cycled*.5;
    float ball = cyl(pball.xz, .5+5.*(1.-wave1));
    ball = mix(max(ball, -sphere(pdots, 1.)), ball, smoothstep(.0,0.5,wave1));
    ball = max(ball, -cyl(pball.xz, 5.*(1.-wave1)));
    
    // red ball
    float redb = cyl(pball.xz, 4.*(1.-wave1));
    
    // iso
    vec3 mosab = moda(pball.xz, 15.);
    pball.xz = mosab.xy;
    pball.x -= 4.*(1.-wave1);
    pball.xy *= rz2(t*.3+indexb);
    pball.yz *= rz2(t*.6+indexb*5.);
    pball.xz *= rz2(t*.9+indexb*10.);
    pball.y = mod(pball.y+t*5., cycleb)-cycleb*.5;
    float iso1 = iso(pball, 0.75*(1.-wave1));
    iso1 = max(-iso1, redb);
    
    // colors
    vec4 red = vec4(hsv2rgb(vec3(.0,.9,1.)),1);
    vec4 green = vec4(hsv2rgb(vec3(.25,.7,.8)),1);
    vec4 green2 = vec4(hsv2rgb(vec3(.25,.5,.3)),1);
    vec4 blue = vec4(hsv2rgb(vec3(.5,.3,.9)),1);
    vec4 orange = vec4(hsv2rgb(vec3(.12,.5,.8)),1);
    info.color = mix(green2, green, scol(leaves, rod, .1));
    
    float scene = smin(leaves, rod, .1);
    info.color = mix(info.color, orange, scol(ball, scene, .1));
    
    scene = min(scene, ball);
    info.color = mix(info.color, red, scol(iso1, scene, .1));
    scene = min(scene, iso1);
    
    return scene;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 ro = vec3(uv,-15.-5.*lfo(0.,0.3))+vec3(0,.5,0), rd = vec3(uv,1), mp = ro;
    int ri = 0;
    for (int i=0;i<50;++i) {
        ri = i;
        float md = map(mp);
        if (md < 0.01) {
            break;
        }
        mp += rd*md*.5;
    }
    float l = length(mp);
    
    float r = float(ri)/50.;
    glFragColor = info.color;
    glFragColor *= 1.-r;
}
