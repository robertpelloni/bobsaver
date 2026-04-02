#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Ziad 27 / 05 /2019 
//-----------------------------------------------------

// --- Heartbreaker ---
// https://www.shadertoy.com/view/MtVyWz

//-----------------------------------------------------
// Ziad 06 / 09 / 2018   http://glslsandbox.com/e#48854
// Leon 05 / 07 / 2017
// using lines of code of IQ, Mercury, LJ, Koltes, Duke

#define D 0.6

#define PI 3.14159
#define TAU PI*2.

#define DITHER 
#define STEPS 50.
#define BIAS 0.0001
#define DIST_MIN 0.0001

float wave(vec2 p)
{
  float v = sin(p.x + sin(p.y*2.) + sin(p.y * 0.43));
  return v * v;
}

const mat2 rot1 = mat2(0.5, 0.86, -0.86, 0.5);

float map(vec2 p)
{
  float v = wave(p);
  p.x += time * 0.224;  p *= rot1;  v += wave(p);
  p.x += time * 0.333;  p *= rot1;  v += wave(p);
  return abs(1.5 - v);
}

vec3 Mucous_Membrane (vec2 pos)
{
  vec2 uv = (pos * 2.0 - resolution.xy) / resolution.y;
  vec2 mp = mouse.xy / resolution.xy;
  uv.y += mp.y;
  float zoom = 18.0 - 14.0 * mp.x;
  vec2 p = normalize(vec3(uv.xy, 2.3)).xy * zoom;
  p.y += time * 0.2;
  float v = map(p);
  vec3 c = mix(vec3(0.3, 0.0, 0.1), vec3(1.0, 0.3 + map(p * 3.5) * 0.6, 0.5), v);
  vec3 n = normalize(vec3(v - map(vec2(p.x + D, p.y)), v - map(vec2(p.x, p.y + D)), -D));
  vec3 l = normalize(vec3(0.1, 0.2, -0.5));
  v = dot(l, n) + pow(dot(l, n), 88.0);
  c.y *= dot (v,v);
  
  return vec3(1.);
  //return c;         // can_'t be saved ?????
    
}

mat2 m =mat2(0.8,0.6, -0.6, 0.8);

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
      vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float fbm(vec2 p)  // Fractional Brownian Motion
{
  float f  = .5000*noise(p); p*= m*2.02;
    f += .2500*noise(p); p*= m*2.03;
    f += .1250*noise(p); p*= m*2.01;
    f += .0625*noise(p); p*= m*2.04;
    return f / 0.9375;
}

mat2 rot (float a) { float c=cos(a),s=sin(a);return mat2(c,-s,s,c); }

//float sphere (vec3 p, float r) { return length(p)-r; }

float cyl (vec2 p, float r) { return length(p)-r; }

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
  //  p.yz *= rot((PI*(mouse.y/resolution.y-.5)*step(0.5,mouse.x)));
   // p.xz *= rot((PI*(mouse.x/resolution.x-.5)*step(0.5,mouse.x)));
    p.yz *= rot(-PI*.5);
    return p;
}

float map (vec3 p, out vec3 color) 
{
    vec3 p1 = p;
    float geo = 1.;
    float cy = 0.2;
    const float repeat = 19.;
    p1.xy *= rot(length(p)*.5);
    float t = time*.03;
    
    for (float i = 0.; i < repeat; ++i) 
    {
        p1.yz *= rot(0.30+t*1.5);
        //p1.xy *= rot(0.20-t);
        p1.xz *= rot(0.15+t*2.);
           //p1.xz *= rot(p.x*.5+t);
        
        // gyroscope
        geo = smin(geo, (sdTriPrism(p1,vec2(1.+i*.2,.9))), .5);
        
        // torus along the cylinders
        vec3 p2 = p1;
        p2.y = mod(p2.y,cy)-cy/2.;
        geo = smin(geo, atan(cyl(p2.xz,.2)), .5);
    }
    color = Mucous_Membrane (p1.xy);
    return geo;    
}

void main( void ) 
{
   float flicker = noise(vec2(time * 3.0)) * 1.9 + 0.14;
    vec2 uv = (gl_FragCoord.xy -0.5*resolution.xy)/resolution.y;
    vec3 eye = camera(vec3(uv,-3));
    vec3 ray = camera(normalize(vec3(uv,.5)));
    vec3 pos = eye;
    float shade = 0.;
    vec2 dpos = ( gl_FragCoord.xy / resolution.xy );
    vec2 seed = dpos + fract(time);
    vec3 color = vec3 (0);
    for (float i = 0.; i < STEPS; ++i) 
    {
    float dist = map(pos, color);
        if (dist < BIAS)
      shade += 1.;
      //  dist = abs(dist)*(.8+0.2*rand(seed*vec2(i)));
        dist = max(DIST_MIN,abs(dist));
        pos += ray*dist;
    }
    glFragColor = vec4(shade/(STEPS-1.));
    glFragColor = vec4(color*flicker*.9, 1.0) * shade/(STEPS-1.);
}
