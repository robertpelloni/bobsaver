#version 420

// original https://www.shadertoy.com/view/ct23Dd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #002
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

//@iq https://iquilezles.org/articles/palettes/
vec3 hue(float t){ 
    t+=T*.06;
    return .55+.75*cos(PI2*t*(vec3(1.,.99,.95)+vec3(.1,.34,.27))); 
}
//@iq https://iquilezles.org/articles/distfunctions2d/
float line( in vec2 p){
    vec2 a = vec2(.2,.5),b = vec2(.8,.5);
    vec2 ba = b-a, pa = p-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0., 1. );
    float d = length(pa-h*ba);
    return d-.1;
}

const float scale = 8.;

void main(void) { //WARNING - variables void ( out vec4 O, in vec2 F ) { need changing to glFragColor and gl_FragCoord.xy

	vec2 F = gl_FragCoord.xy;
	vec4 O = vec4(0.0);

    // uv 
    vec2 uv = (2.* F.xy-R.xy)/max(R.x,R.y);
    uv.x-=T*.05;
    
    // colors 
    vec3 h1 = hue(uv.y*.04+T*.01);
    vec3 h2 = hue((15.+uv.y)*.04+T*.05);
    vec3 h3 = hue(uv.x*.04+T*.01);
    
    vec3 C = hue((10.-uv.x)*.04+T*.1);
    
    // base grid and ids
    vec2 id = floor(uv*scale);
    vec2 gv = fract(uv*scale)-.5;
    float px = scale/R.x;

    float check = mod(id.y+id.x,2.)*2.-1.;
    float rnd = hash21(id);
    if(rnd>.5) gv.x *= -1.;
    
    // setup for truchet path
    vec2 d2 = vec2(length(gv-.5),length(gv+.5));
    vec2 g2 = d2.x<d2.y? gv-.5 : gv+.5;

    float ft = .2+.1*sin(uv.y*5.2+T);
    float d = length(g2)-.5;
    float dl= smoothstep(px,-px,abs(abs(d)-ft)-.02);
    d = smoothstep(-px,px,abs(d)-ft);

    C = mix(C,h3,d);
    C = mix(C,vec3(.8),dl);
    
    
    // moving truchet parts
    vec2 arc = gv-sign(gv.x+gv.y+.001)*.5;
    float angle = atan(arc.x, arc.y);
    d = length(arc);

    float x = fract(3.*check*angle/PI+T*1.15);
    float y = (d/.5)-.5;
    
    if(rnd<.5 ^^ check>0.) y=1.-y;
    vec2 tuv = vec2(x,y);
    
    float ts = length(tuv-vec2(.5))-.25;
    ts = smoothstep(.05+px,-px,abs(ts)-.125);
    C = mix(C,vec3(.01),ts);
    
    float t = length(tuv-vec2(.5))-.25;
    t = smoothstep(px,-px,abs(t)-.075);
    C = mix(C,h2,t);
    
    ts = min(line(tuv-vec2(.5,0)),line(tuv+vec2(.5,0)));
    ts = smoothstep(.05+px,-px,abs(ts)-.05);
    C = mix(C,vec3(.01),ts);
    
    t = min(line(tuv-vec2(.5,0)),line(tuv+vec2(.5,0))); 
    t = smoothstep(px,-px,t);
    C = mix(C,h1,t);
    
    C = pow(C, vec3(.4545));
    O = vec4(C,1.);

	glFragColor = O;
}

