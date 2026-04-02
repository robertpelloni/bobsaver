#version 420

// original https://www.shadertoy.com/view/ss3BR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
   
    tiny shader 003 | 06/25/22 | byt3_m3chanic
    
    Just playing around - trying to make something smol.
    some golfing tricks from @dean_the_coder @Fabrice @iapafoto 
*/

#define R           resolution
#define T           time
#define PI2         6.28318530718

#define S smoothstep
#define L length

#define H21(a) fract(sin(dot(a,vec2(21.23,41.32)))*43758.5453)
#define N(p,e) vec3(M(p-e.xyy),M(p-e.yxy),M(p-e.yyx))
#define H(hs) .45+.4*cos(PI2*hs+2.*vec3(.95,.97,.90)*vec3(.15,.48,.90))
#define M(p) L(max(abs(p)-hz,0.))-.075

mat2 Q(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
const float sz=1.25,hf=sz/2.,hz=hf*.875;

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y),
         id = vec2(0);

    vec3 p = vec3(0),
        ro = vec3(0,0,6),
        rd = normalize(vec3(uv,-1));

    mat2 rx = Q(-2.25),
         ry = Q(T*.1);

    ro.yz*=rx; ro.xz*=ry; 
    rd.yz*=rx; rd.xz*=ry;

    float d=0.;
    
    for(int i=0; i++<128 && d<50.; ){
        p = ro + rd * d;
        p.xz-=vec2(.5,1.5)*T;
        id=floor((p.xz-hf)/sz);
        p.xz=mod(p.xz+hf,sz)-hf;
        float x = M(p);
        d+=x;
    }
    
    float t = M(p);
    vec2 e = vec2(d*.001,0);
    vec3 l = normalize(vec3(5,-5,-5)),
         n = t - N(p,e);
         n = normalize(n);

    float diff = clamp(dot(n,l),.05,.9),
          hs = H21(id),
          px = 4./R.x,
          cx = mod(id.x+id.y,2.)*2.-1.;

    vec3 h = H(id.x*.1+id.y*.1);
    if(hs>.5) p.z=-p.z;

    vec2 pd = vec2(L(p.xz-hz),L(p.xz+hz)),
          q = pd.x<pd.y ? vec2(p.xz-hz):vec2(p.xz+hz);
    
    float f=L(q)-hz,
          j=S(px,-px,abs(f)-.1);
        
    f =(cx>.5 ^^ hs>.5) ? S(px,-px,f) : S(-px,px,f);

    d = clamp(1.-d*.005,0.,1.);
    h = mix(mix(h,vec3(.3),j),vec3(.02),f);
    glFragColor = vec4(pow(diff*h,vec3(.4545)),1);
}
