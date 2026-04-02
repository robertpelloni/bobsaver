#version 420

// original https://www.shadertoy.com/view/mdXyD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #044
    06/27/2023  @byt3_m3chanic
    Truchet Core \M/->.<-\M/ 2023 
    
*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy
#define PI          3.141592653

mat2 rot(float a) {return mat2(cos(a),sin(a),-sin(a),cos(a));}
float hash21(vec2 a) {return fract(sin(dot(a,vec2(27.609,57.583)))*43758.5453);}

void main(void) {
    mat2 r45 = rot(.785398);
    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
 
    // upscale
    float scale = .6365;

    // warp and turn
    uv *= rot(-T*.3);
    uv = vec2(log(length(uv)), atan(uv.y, uv.x))*scale;
    uv.x -= T*.7;
    
    vec2 vv = uv;

    // background patterns
    vec3  C = fract(6.*(vv.x+T*.6))<.5 ? vec3(.1,0,0):vec3(0,0,.075);

    float px = fwidth(uv.x); 
    
    vec2 id = floor(uv), q = fract(uv)-.5;
    float hs = hash21(id.xy);

    if(hs>.5) q = vec2(-q.y,q); 
    hs = fract(hs*575.913);
    
    float wd = .015, mv = .095;
    vec2 q2 = q;

    vec2 pq = length(q.xy-vec2(-.5,.5))<length(q.xy+vec2(-.5,.5))? q.xy-vec2(-.5,.5) : q.yx+vec2(-.5,.5);
  
    pq *= r45;
    q2 *= r45;
 
    // main pattern
    float d = length(pq.x);
    d=abs(d)-mv;
    
    // alt pattern
    if(hs>.85) d = min(length(q2.x),length(q2.y))-mv;
    
    // posts
    float b = length(abs(q)-.5)-(mv*1.75);
    d = min(b,d);
    d = max(d,-(b+.075));
    float md = d;
    
    d=abs(d)-wd;
    
    // grid lines
    float d2 = abs(max(abs(q.x),abs(q.y))-.5)-.01;
    d2 = max(d2,-(b+.075));
    vec3 clr = vec3(.4);

    // color mixdown
    C = mix(C,vec3(.3),smoothstep(px,-px,d2));

    C = mix(C,C*.35,smoothstep(.075+px,-px,d-.015));
    C = mix(C,clr,smoothstep(px,-px,d));
    C = mix(C,vec3(.0025),smoothstep(px,-px,md));

    // gamma and output
    C = pow(C,vec3(.4545));
    glFragColor = vec4(C,1.);
}
