#version 420

// original https://www.shadertoy.com/view/dd3SRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #007
    04/02/2023  @byt3_m3chanic
    
    All year long I'm going to just focus on truchet tiles and the likes!
    Truchet Core \M/->.<-\M/ 2023 
    
*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy

float scale = 8.;

float hash21(vec2 a) { return fract(sin(dot(a, vec2(27.609, 57.583)))*43758.5453);}
mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a));}

//@iq sdfs
float box(vec2 p, vec2 a) {
    vec2 q = abs(p)-a;
    return length(max(q,0.)) + min(max(q.x,q.y),0.);
}

float ck = 0., d2 = 0.;
vec2 g = vec2(0), id = vec2(0);

float makeTile(vec2 uv){

    id = floor(uv);
    vec2 q = fract(uv)-.5;
    g=q;
    
    ck = mod(id.x+id.y,2.)*2.-1.;
    float hs = hash21(id);

    float wd = .125+.065*sin(uv.x*.5+T*.75);
    if(hs>.5) q.x=-q.x;
    
    vec2 sp = vec2(length(q-.5),length(q+.5));
    vec2 p = sp.x<sp.y? q-.5 : q+.5;

    // main pattern
    float d = length(p)-.5;
    d = abs(d)-wd;
    
    float c = min(length(q.x)-wd,length(q.y)-wd);
    if (hs>.9) d = c;
    
    hs = fract(hs*413.372);
    if (hs>.9) d = min(length(abs(q)-vec2(.5,0))-wd,length(q.x)-wd);
    if (hs<.1) d = min(abs(length(q)-.3)-wd,max(c,-(length(q)-.3)));
    
    if(ck<.5 && hs>.925) d = min(length(q)-(wd*1.8),d);

    d2 = abs(max(abs(q.x),abs(q.y))-.5)-.005;

    return d;
}

void main(void) {
	vec2 F = gl_FragCoord.xy;

    vec3 C = vec3(.1);
    vec2 uv = (2.*F-R.xy)/max(R.x,R.y);
    vec3 clr = mix(vec3(.0,.48,.64),vec3(1.,.5,.1),uv.x);
    vec3 clx = mix(vec3(1,.5,0),vec3(1,.1,0),uv.x);
    
    uv*=scale;    
    float px = fwidth(uv.x); 
    
    uv*=rot(T*.035);
    uv.x -= .25*T;

    float d = makeTile(uv);
    float hs = hash21(id);
    float h2 = fract(hs*32.233);
    
    float b = box(g,vec2(.31))-.15;
    float h = box(g,vec2(.28))-.13;
    float s = smoothstep(.05+px,-px,b);
    if(h2>.4) C = mix(C,C*.1,s);
    
    b = smoothstep(px,-px,b);
    if(h2>.4) C = mix(C,ck>.5?clx:vec3(0.212,0.227,0.227),b);
 
    h=max(h,clamp((g.y+.25)*.02,0.,1.));
    h = smoothstep(px,-px,h);
    if(h2>.4) C = mix(C,C+.25,h);
        
    d2 = smoothstep(px,-px,d2);
    //if(M.z>0.) C = mix(C,vec3(1.),d2);
    
    s = smoothstep(.075+px,-px,d);
    C = mix(C,C*.3,s);

    float d3 = smoothstep(px,-px,abs(d)-.01);
    d = smoothstep(px,-px,d);
    C = mix(C,clr,d);
    C = mix(C,C*.1,d3);
    
    C = pow(C,vec3(.4545));
    glFragColor = vec4(C,1.);
}
