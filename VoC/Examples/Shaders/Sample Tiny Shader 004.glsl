#version 420

// original https://www.shadertoy.com/view/fd3fz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
   
    Tiny Menger Shader 004 | an isometric view of a menger spong iterations.
    06/29/22 | byt3_m3chanic

    Some golfing tricks from @dean_the_coder @Fabrice @iq
*/

#define T           time
#define PI          3.14159265359
#define PI2         6.28318530718

#define S smoothstep
#define L length

#define N(p,e) vec3(map(p-e.xyy),map(p-e.yxy),map(p-e.yyx))
#define Q(a)      mat2(cos(a+vec4(0,11,33,0)))
#define H(hs)     .5 + .4* cos( PI2*hs + vec3(4,8.7,1.6) )
#define lsp(b,e,t) clamp((t-b)/(e-b),0.,1.)
#define box(p,d) L(max(abs(p)-d,0.))-.025

vec3 hit,hp;
float tmod,ga1,ga2,ft;

const float size =12.;
const float hlf =size/2.;

float map(vec3 p) {

    p.y+=ga1*size;
    float id =floor((p.y+hlf)/size);
    if(ft==id-1.) p.xz*=Q(PI*ga2);
    p.y=mod(p.y+hlf,size)-hlf;

    float r = 1e5;
    float scale = 3.;
     vec3 cxz = vec3(scale);
    float ss=.75;
    hit=p;
    int iz = int(id)%4 + 1;
    for (int i = 0;i<iz;i++) {
        p=abs(p);
        
        if (p.x<p.y) p.yx = p.xy;
        if (p.x<p.z) p.zx = p.xz;
        if (p.y<p.z) p.zy = p.yz;
        if(i==iz-2)hit=p;

        p.x=scale * p.x-cxz.x*(scale-1.);
        p.y=scale * p.y-cxz.y*(scale-1.);
        p.z=scale * p.z;

        if (p.z>0.5*cxz.z*(scale-1.)) p.z-=cxz.z*(scale-1.);
        ss /= scale;
    }
    
    r = box(p,scale);
    return r*ss;
}

void main(void)
{
    //time = T;
    ft = floor(time*.1);
    tmod = mod(time, 10.);
    float t1 = lsp(0.0, 5.0, tmod);
    float t2 = lsp(5.25, 9.75, tmod);
    ga1 = (t1)+ft;
    ga2 = (t2);
    
    vec2  R = resolution.xy,
         uv = ( gl_FragCoord.xy+gl_FragCoord.xy - R ) / max(R.x,R.y);
    vec3 C = vec3(.0),
         p = vec3(0),
         c = vec3(0),
        ro = vec3(uv*10.,-15.),
        rd = vec3(0,0,1);

    mat2 rx = Q(-.78),
         ry = Q(-.78);

    ro.yz*=rx; ro.xz*=ry; 
    rd.yz*=rx; rd.xz*=ry;

        float d=0.,fm=0.;

        for(int i=0; i++<100 && d<100.;) {
            p = ro + rd * d;
            float x = map(p);
            d+=x;
        }
        
        hp=hit;
        float t = map(p);
        vec2 e = vec2(d*.001,0);
        vec3 l = normalize(vec3(2,5,-5)-p),
             n = t - N(p,e);
             n = normalize(n);
        vec3 clr = H(floor(hp.z*.25)),
             fg  = H(abs(uv.x*.75));
        float diff = clamp(dot(n,l),.1,.9);

        float px = 8./R.x;
        float f = length(hp.z)-1.;
        f=S(px,-px,f);
        clr=mix(clr, H(12.-floor(hp.z*5.25)),f);

        C = d<30. ? diff*clr : fg;

    glFragColor = vec4(pow(C,vec3(.4545)),1);
}
