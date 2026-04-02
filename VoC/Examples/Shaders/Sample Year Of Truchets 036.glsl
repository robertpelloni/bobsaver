#version 420

// original https://www.shadertoy.com/view/mdscRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #036
    06/13/2023  @byt3_m3chanic
    Truchet Core \M/->.<-\M/ 2023 
    
*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy
#define PI         3.14159265359
#define PI2        6.28318530718

mat2 rot(float a) {return mat2(cos(a),sin(a),-sin(a),cos(a));}
float hash21(vec2 a) {return fract(sin(dot(a,vec2(27.609,57.583)))*43758.5453);}

//@iq of hsv2rgb
vec3 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.+vec3(0,4,2),6.)-3.)-1., 0., 1.0 );
    return c.z * mix( vec3(1), rgb, c.y);
}

void main(void) {
    mat2 r45 = rot(.7853981634);
    
    vec3 C = vec3(.085);
    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    vec2 vv = uv;

    uv = uv-vec2(.3535,0);
    if(vv.x>-.3) {
        // background patterns
        vec2 ft = fract((vv*8.+vec2(T*.2,0))*rot(.78))-.5;
        C = mix(vec3(.1),vec3(.075),mod(floor(ft.x),3.)==0.?1.:0.);
        // warp and turn
        float scale = 1.91;   //7.//5.41//3.5;//2.545;//1.91;//1.2726;//.6365;
        uv *= rot(-T*.035);
        uv = vec2(log(length(uv)), atan(uv.y, uv.x))*scale;
        uv.x -= T*.3;
    
    }else{
        vec2 ft = fract((vv*32.)*rot(.78))-.5;
        C = mix(vec3(.075),vec3(.1),mod(floor(ft.x),3.)==0.?1.:0.);
        uv *= 10.;
        uv.x -= T*.3;
    }

    float px = fwidth(uv.x); 
    
    vec2 id = floor(uv), q = fract(uv)-.5;
    float hs = hash21(id.xy);

    if(hs>.5)  q.xy *= rot(1.5707);
    hs = fract(hs*575.913);
    
    float wd = .01, mv = .12;

    //q *= r45;
    vec2 spc = vec2(-.5,.0);
    vec2 p2 = vec2(length(q+spc),length(q-spc));
    vec2 pq = p2.x<p2.y? q+spc : q-spc;
  
    pq *= r45;
 
    // main pattern
    float d = length(pq.x);
    d=abs(d)-mv;
    //d=1e5;
    // alt pattern
    if(hs>.85) d = min(length(q.x)-mv,length(q.y)-mv);
    
    // posts
    float b = length(vec2(abs(q.x)-.5,q.y))-(mv*1.5);
    b = min(length(vec2(q.x,abs(q.y)-.5))-(mv*1.5),b);
    d = min(b,d);
    d = max(d,-(b+.1));
    float md = d;
    
    d=abs(d)-wd;
    
    // grid lines
    float d2 = abs(max(abs(q.x),abs(q.y))-.5)-.01;
    d2 = max(d2,-(b+.075));
    vec3 clr = hsv2rgb(vec3((uv.x*.035),1.,.5));

    // color mixdown
    C = mix(C,vec3(.3),smoothstep(px,-px,d2));

    C = mix(C,C*.35,smoothstep(.075+px,-px,d));
    C = mix(C,clr,smoothstep(px,-px,d));
    C = mix(C,vec3(.0025),smoothstep(px,-px,md));
    
    if(vv.x<-.3&&vv.x>-.305) C = vec3(.25);
    
    // gamma and output
    C = pow(C,vec3(.4545));
    glFragColor = vec4(C,1.);
}
