#version 420

// original https://www.shadertoy.com/view/sldfzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Creative Commons Licence Attribution-NonCommercial-ShareAlike 
 * phreax 2022
 *
 * Special thanks to: iq, evvvvil, nusan, bigwings, fabrice, flopine, yx 
 * for their amazing content and learning material.
 * 
 */
#define PI 3.141592
#define TAU PI*2.
#define SIN(x) (.5+.5*sin(x))

#define EDGE_DETECTION 1

float tt;
vec3 ro;
vec2 beamId;
float hexId;
float gMatId;

// from "Palettes" by iq. https://shadertoy.com/view/ll2GD3
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 getPal(int id, float t) {

    id = id % 7;

    vec3          col = pal( t, vec3(.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,-0.33,0.33) );
    if( id == 1 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) );
    if( id == 2 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.3,0.20,0.20) );
    if( id == 3 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,0.5),vec3(0.8,0.90,0.30) );
    if( id == 4 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,0.7,0.4),vec3(0.0,0.15,0.20) );
    if( id == 5 ) col = pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(2.0,1.0,0.0),vec3(0.5,0.20,0.25) );
    if( id == 6 ) col = pal( t, vec3(0.8,0.5,0.4),vec3(0.2,0.4,0.2),vec3(2.0,1.0,1.0),vec3(0.0,0.25,0.25) );
    
    return col;
}

float box(vec3 p, vec3 r) {
    vec3 q = abs(p) - r;
    return max(max(q.x, q.y),q.z);
}

mat2 rot(float a) { return mat2(cos(a), sin(a), -sin(a), cos(a));}

float pModSingle(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    if (p >= 0.)
        p = mod(p + halfsize, size) - halfsize;
    return c;
}

float repeat(inout float x, float n) {
    float id = floor(n*x)/n;
    x = fract(n*x);
    return id;
}

vec3 colorStripeTexture(vec3 p, int palId, float off) {
    float dim = p.y*6.;
    
    float id = repeat(dim, 5.2) + tt + off;
    vec3 col = getPal(palId, id);
    return col;
}

// from https://mercury.sexy/hg_sdf/
float pModPolar(inout vec2 p, float repetitions) {
    float angle = 2.*PI/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = mod(a,angle) - angle/2.;
    p = vec2(cos(a), sin(a))*r;
    // For an odd number of repetitions, fix cell index of the cell in -x direction
    // (cell index would be e.g. -5 and 5 in the two halves of the cell):
    if (abs(c) >= (repetitions/2.)) c = abs(c);
    return c;
}

// Repeat only a few times: from indices <start> to <stop> (similar to above, but more flexible)
float pModInterval1(inout float p, float size, float start, float stop) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p+halfsize, size) - halfsize;
    if (c > stop) { //yes, this might not be the best thing numerically.
        p += size*(c - stop);
        c = stop;
    }
    if (c <start) {
        p += size*(c - start);
        c = start;
    }
    return c;
}

void transform(inout vec3 p) {
    
    float repz = 8.;

    float idz = pModSingle(p.z,8.);  
    p.xy *= rot(.25*PI*mod(idz, repz));
}

// by Nusan
float curve(float t, float d) {
  t/=d;
  return mix(floor(t), floor(t)+1., pow(smoothstep(0.,1.,fract(t)), 10.));
}

// kaleidoscopic function
vec3 kalei(vec3 p) {
  float w = 1.;
  p = abs(p) -.3;
  
  float tc = curve(tt, 2.)*2.414+curve(.57*tt, 6.)*3.212;
  for(float i=0.; i < 2.; i++) {
        float t1 = 2.+sin(i+tc) + sin(.7*tc)*.4;
        p.xy *= rot(.34*t1);
        p -= 0.1 + .1*i;
        p.y -= 0.1;
        p = abs(p);
 
    }
    p /= w;
    return p;
}

float sdHexPrism( vec3 p, vec2 h )
{
  const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
  p = abs(p);
  p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
  vec2 d = vec2(
       length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
       p.z-h.y );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float map(vec3 p) {

    vec3 bp = p;
    float repz = 1.5;

    float hexCount = 8.;
    
    if(tt > 8.) p = kalei(p);
   
    float segId = pModSingle(p.z, repz);
    hexId = pModInterval1(p.z, .15, 0., hexCount);
    

    p.xy *= rot(PI*1./2.);
    float pid = pModPolar(p.xy, 6.);
    
    gMatId = segId + abs(pid);
    p.x -= .4;
    p.xy *= rot(PI*1./2.);
  
  
    float sizeMod = (hexId/hexCount)*.1;
    float width = .09-sizeMod;
    float size = .2-sizeMod;
    float thickness = .04;
    float hex = max(sdHexPrism(p, vec2(size, width)), -sdHexPrism(p, vec2(size-thickness, width+.1)));
    
    float d = hex*.6;
    
    d = max(d, -sdHexPrism(bp-ro, vec2(.2, 10)));

    return d;
   
}

void cam(inout vec3 p) {
    p.z += 1.*tt;;

}

// numeric edge detection by kali
float edge;
vec3 normal(vec3 p) { 
    vec3 e = vec3(0.0,0.0035,0.0);

    float d1=map(p-e.yxx),d2=map(p+e.yxx);
    float d3=map(p-e.xyx),d4=map(p+e.xyx);
    float d5=map(p-e.xxy),d6=map(p+e.xxy);
    float d=map(p);
    edge=abs(d-0.5*(d2+d1))+abs(d-0.5*(d4+d3))+abs(d-0.5*(d6+d5));//edge finder
    edge=min(1.,pow(edge,.7)*20.);
    return normalize(vec3(d1-d2,d3-d4,d5-d6));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.x;
    tt = time;
         ro = vec3(0, 0, -4.);
    vec3 rd = normalize(vec3(uv, 1.5)),
         lp = vec3(0., 0., 2.);
    
    cam(ro);
    cam(lp);
  
    float i, t, d = 0.1;

    vec3 p = ro;

    float matId;
    for(i=0.; i<300.; i++) {
    
          
        d = map(p);
        matId = hexId; // save id
        
        if(d < 0.001 || t > 200.) break;
            
        p += rd*d;
        t += d;
    }
    
    vec2 e = vec2(0.0035, -0.0035);
    
    vec3 fo, co;
    co = fo = vec3(0.965,0.945,0.918);
    
    if(d < 0.001) {
        vec3 al;
        
        vec3 n = normal(p);
                            
        int palId = 0;
        if(tt > 16.) palId = mod(tt, 16.) <8. ? 4 : 3;
        
        al = getPal(palId, .5-matId*.15+.5*tt+gMatId+.5)*1.3;
        
        if(tt > 32.)  al = mix(al, (vec3(0.867,1.000,0.780)-abs(n))*1.4, .8*SIN(tt));
        
        //if(mod(hexId, 2.) == 1. && tt > 16.) al = colorStripeTexture(p, palId, hexId);
        vec3 l = normalize(lp-p);
        float dif = max(dot(n, l), .0);
        float spe = pow(max(dot(reflect(-rd, n), -l), .0), 40.);
        float sss = smoothstep(0., 1., map(p+l*.4))/.4; 
        
        co =  al*mix(1., .4*spe+(.4*dif+1.5*sss), .45);
        
        #if EDGE_DETECTION
        co *= max(0.,1.-edge);
        #endif
        co = mix(co, fo, 1.-exp(-.0003*t*t*t))*.9+.1*fo;   
    }

    // Output to screen
    glFragColor = vec4(co, 1.);
}
