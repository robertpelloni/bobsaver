#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Ziad 06 / 09 / 2018
// Leon 05 / 07 / 2017
// using lines of code of IQ, Mercury, LJ, Koltes, Duke

#define PI 3.14159
#define TAU PI*2.

#define DITHER
#define STEPS 30.
#define BIAS 0.01
#define DIST_MIN 0.01

mat2 m =mat2(0.8,0.6, -0.6, 0.8);

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
      vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float fbm(vec2 p){
    float f=.0;
    f+= .5000*noise(p); p*= m*2.02;
    f+= .2500*noise(p); p*= m*2.03;
    f+= .1250*noise(p); p*= m*2.01;
    f+= .0625*noise(p); p*= m*2.04;
    
    f/= 0.9375;
    
    return f;
}

mat2 rot (float a) { float c=cos(a),s=sin(a);return mat2(c,-s,s,c); }
float sphere (vec3 p, float r) { return length(p)-r; }
float cyl (vec2 p, float r) { return length(p)-r; }
float torus( vec3 p, vec2 s ) {
  vec2 q = vec2(length(p.xz)-s.x,p.y);
  return length(q)-s.y;
}
float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}
float smin (float a, float b, float r) {
    float h = clamp(.5+.5*(b-a)/r,0.,1.);
    return mix(b,a,h)-r*h*(1.-h);
}
vec3 camera (vec3 p) {
    p.yz *= rot((PI*(mouse.y/resolution.y-.5)*step(0.5,mouse.x)));
    p.xz *= rot((PI*(mouse.x/resolution.x-.5)*step(0.5,mouse.x)));
    p.yz *= rot(-PI*.5);
    return p;
}

float map (vec3 p) {
    vec3 p1 = p;
    float geo = 1.;
    float cy = 0.2;
    const float repeat = 8.;
    p1.xy *= rot(length(p)*.5);
        
    
    float t = time*.2;
    
    for (float i = 0.; i < repeat; ++i) {
        p1.yz *= rot(0.3+t*0.5);
        p1.xy *= rot(0.2+t);
        p1.xz *= rot(.15+t*2.);
        
           p1.xy *= rot(p.x*.5+t);
        
        
        // gyroscope
        geo = smin(geo, cos(sdTriPrism(p1,vec2(1.+i*.2,.9))), .5);
    //geo = smoothstep(0.1,.5,cos(geo));
       // geo = smin(geo, cos(cyl(p1.xz,.2)), .5);
        
        // torus along the cylinders
        vec3 p2 = p1;
        p2.y = mod(p2.y,cy)-cy/2.;
        geo = smin(geo, atan(cyl(p2.xz,.2)), .5);

        
    
        
    }
    return geo;
}

void main( void ) {

    
    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 eye = camera(vec3(uv,-3));
    vec3 ray = camera(normalize(vec3(uv,.5)));
    vec3 pos = eye;
    float shade = 0.;
    #ifdef DITHER
    vec2 dpos = ( gl_FragCoord.xy / resolution.xy );
    vec2 seed = dpos + fract(time);
    #endif 
    for (float i = 0.; i < STEPS; ++i) {
        float dist = map(pos);
        if (dist < BIAS) {
            shade += 1.;
        }
        #ifdef DITHER
        dist=abs(dist)*(.8+0.2*rand(seed*vec2(i)));
        #endif 
        dist = max(DIST_MIN,dist);
        pos += ray*dist;
    }
    glFragColor = vec4(shade/(STEPS-1.));
}
