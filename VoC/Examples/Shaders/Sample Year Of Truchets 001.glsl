#version 420

// original https://www.shadertoy.com/view/ctB3Dt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #001
    01/18/2023  @byt3_m3chanic
    
    All year long I'm going to just focus on truchet tiles and the likes!
    Truchet Core \M/->.<-\M/ 2023 
    
*/

#define R resolution
#define T time
#define M mouse*resolution.xy

#define PI          3.14159265359
#define PI2         6.28318530718

#define MIN_DIST    .0001
#define MAX_DIST    50.

float hash21(vec2 p) {return fract(sin(dot(p,vec2(23.43,84.21)))*4832.3234);}
mat2 rot(float a){ return mat2(cos(a),sin(a),-sin(a),cos(a)); }

float torus( vec3 p, vec2 a ){
  return length(vec2(length(p.xy)-a.x,p.z))-a.y;
}
//@iq https://iquilezles.org/articles/distfunctions/
float cap( vec3 p, float h, float r ){
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.) + length(max(d,0.));
}

vec3 hp,hitpoint;
vec2 gid, sid;

const float sz = 2.35;
const float hf = sz/2.;
const float zz = 4.25;

float truchet(vec3 p, float id) {
    float res =1e5;
    
    p.xy*=rot(T*.025);
    p.y+=T*1.5;
    
    vec3 q=p;
    vec2 gid = floor((p.xy+hf)/sz);
    p.xy  = mod(p.xy+hf,sz)-hf;
    
    float rnd = hash21(gid+id);
    if(rnd>.5) p.y *=-1.;
    
    float thk = .35;
    
    thk += .1*sin(q.y*1.3);
    thk += .1*sin(q.x*1.3);
    
    vec2 d2 = vec2(length(p.xy-hf), length(p.xy+hf));
    vec2 gx = d2.x<d2.y ? vec2(p.xy-hf) : vec2(p.xy+hf);
    vec3 pv = vec3(gx.xy,p.z);
    hp=pv;
    float d = torus(pv,vec2(hf,thk));
    
    if(rnd>.9) { d=min(length(p.xz)-thk,length(p.yz)-thk); }
    if(d<res) { res=d; hp=p; }

    return res;
}

vec2 map(vec3 p) {
    vec2 res = vec2(1e5,0.);

    float d = 1e5;
    float m = 0.;
    
    for(float i=0.;i<3.;i++){
        float e = truchet(p,i);
        p.z+=zz;
        d=min(e,d);
        m+=.15;

        if(d<res.x) res=vec2(d,m);

    }

    return res;
}

vec3 normal(vec3 p, float t) {
    t*=MIN_DIST;
    float d = map(p).x;
    vec2 e = vec2(t,0);
    vec3 n = d - vec3(
        map(p-e.xyy).x,
        map(p-e.yxy).x,
        map(p-e.yyx).x
    );
    return normalize(n);
}

vec2 marcher(vec3 ro, vec3 rd, inout vec3 p, int steps) {
    float d=0.,m=0.;
    for(int i=0;i<steps;i++){
        vec2 t = map(p);
        d += i<32? t.x*.5:t.x;
        m  = t.y;  
        p = ro + rd * d;
        if(abs(t.x)<d*MIN_DIST||d>75.) break;
    } 
    return vec2(d,m);
}

//@iq https://iquilezles.org/articles/palettes/
vec3 hue(float t){ 
    t+=T*.06;
    return .75+.75*cos(PI2*t*(vec3(1.,.99,.95)+vec3(.1,.34,.27))); 
}

void main(void) { //WARNING - variables void ( out vec4 O, in vec2 F ) { need changing to glFragColor and gl_FragCoord.xy
	vec2 F = gl_FragCoord.xy;
	vec4 O = vec4(0.0);
	
    // uv ro + rd
    vec2 uv = (2.* F.xy-R.xy)/max(R.x,R.y);
    vec3 ro = vec3(0,0,10);
    vec3 rd = normalize(vec3(uv, -1.));

    vec3 C = vec3(0);
    vec3 p = ro;

    vec2 ray = marcher(ro,rd,p,100);
    
    float d = ray.x;
    float m = 23.+(ray.y*.7);
    
    gid = sid;
    hitpoint = hp;
    
    if(d<MAX_DIST) {
  
        vec3 n = normal(p,d);
        vec3 lpos = vec3(5.5,-3,13.);
        vec3 l = normalize(lpos-p);

        float diff = clamp(dot(n,l),0.,1.);

        float shdw = 1.;
        for( float t=.01;t<24.; ) {
            float h = map(p + l*t).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 24.*h/t);
            t += h * .95;
            if( shdw<MIN_DIST || t>24. ) break;
        }
        
        diff = mix(diff,diff*shdw,.35);
        float spec = .75 * pow(max(dot(normalize(p-ro),reflect(normalize(lpos),n)),0.),24.);
        
        vec3 h = hue(m+hitpoint.x*.2);
        vec3 h2 = hue(2.52+(m*2.));
        float px = 8./R.x;
        
        float f = length(hitpoint.xy)-(hf*.75);
        float fs=smoothstep(.1+px,-px,abs(abs(f)-.15)-.07);
        
        f=smoothstep(px,-px,abs(abs(f)-.15)-.07);
        h=mix(h,h*.4,fs);
        h=mix(h,h2,f);
        C = h * diff+spec;
    }

    C = mix(C,vec3(.04), 1.-exp(-.00045*d*d*d));
    C = pow(C, vec3(.4545));
    O = vec4(C,1.);

	glFragColor = O;
}
