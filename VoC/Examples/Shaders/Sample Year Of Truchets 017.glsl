#version 420

// original https://www.shadertoy.com/view/mld3Wj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #017
    05/05/2023  @byt3_m3chanic
    
    - music just for effect -
    
    All year long I'm going to just focus on truchet tiles and the likes!
    Truchet Core \M/->.<-\M/ 2023 
    
*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy

#define PI         3.14159265359
#define PI2        6.28318530718

float hash21(vec2 a) { return fract(sin(dot(a, vec2(27.609, 57.583)))*43758.5453);}
mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a));}
//@iq hue palettes 
vec3 hue(float t){ return .35 + .4*cos(PI2*t*(vec3(.95,.97,.98)*vec3(0.098,0.345,0.843))); }

float ck = 0., d2 = 0.;
vec2 g = vec2(0), id = vec2(0);

float makeTile(vec2 uv){

    id = floor(uv);
    vec2 q = fract(uv)-.5;
    g = q;
  
    ck = mod(id.x+id.y,2.)*2.-1.;
    float hs = hash21(id);

    float wd = .12+.1*sin(uv.x*.75+T*2.5);
    if(hs>.5) q *= rot(1.5707);
    
    vec2 sp = vec2(length(q-.5),length(q+.5));
    vec2 p = sp.x<sp.y? q-.5 : q+.5;

    // main pattern
    float d = length(p)-.5;
    d = abs(d)-wd;
    
    float c = min(length(q.x)-wd,length(q.y)-wd);
    if (hs>.9) d = c;
    
    hs = fract(hs*413.372);
    if (hs>.9) d = min(length(abs(q)-vec2(.5,0))-wd,length(q.x)-wd);
    if (hs<.1) d = min(abs(length(q)-.2)-wd,max(c,-(length(q)-.2)));

    d2 = abs(max(abs(q.x),abs(q.y))-.5)-.005;

    return d;
}

void main(void) { //WARNING - variables void ( out vec4 O, in vec2 F ) { need changing to glFragColor and gl_FragCoord.xy

    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0); 

    vec3 C = vec3(.01);
    
    vec2 uv = (2.*F-R.xy)/max(R.x,R.y);
    vec2 vv = uv;
   
    float fd = (uv.y+.25)*1.35;
    fd = clamp(1.,0.,fd);

    
    uv *= rot(-T*.11);
    uv = vec2(log(length(uv)), atan(uv.y, uv.x))*5.41;  //3.5;//2.545;//1.91;//1.2726;//.63;
    uv.x -= T*.35;
        
    vec3 clr = hue((uv.x+2.)*.209);
    vec3 clx = hue((uv.x+2.)*.41);

    float px = fwidth(uv.x); 
    float d = makeTile(uv);

    float s = smoothstep(.075+px,-px,d);
    d2 = smoothstep(px,-px,d2);

    C = mix(C,vec3(.125),d2);
    C = mix(C,C*.3,s);
    
    float d3 = smoothstep(px,-px,abs(d)-.04);
    float d4=mix(d,0.,fd);
    
    d4 = smoothstep(px,-px,d4+.1);
    d = smoothstep(px,-px,d);
    
    C = mix(C,clr,d);
    C = mix(C,C*.1,d3);
    C = mix(C,clamp(C+.3,C,vec3(1)),d4);
    
    float v = length(vv)-.0005;
    v = smoothstep(.2,.0,v);
    C = mix(C,vec3(.01),clamp(0.,.7,v));
    C = pow(C,vec3(.4545));
    O = vec4(C,1.);
    
    glFragColor=O*1.5;
}

    
    
        
    
        
    
        
    
        
    
    