#version 420

// original https://www.shadertoy.com/view/NsdfzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
   
    tiny shader 005 | 06/26/22 | byt3_m3chanic
    
    Just playing around - trying to make something smol. 
    some golfing tricks from @dean_the_coder @Fabrice @iapafoto @Shane
*/

#define M           mouse*resolution.xy
#define R           resolution
#define T           time
#define PI2         6.28318530718

#define S           smoothstep
#define L           length
#define Nz          normalize
#define V           vec2(1,0)

#define H21(a) fract(sin(dot(a,vec2(21.23,41.32)))*43758.5453)
#define N(p,e) vec3(map(p-e.xyy),map(p-e.yxy),map(p-e.yyx))
#define H(hs) .5+.4*cos(PI2*hs+2.*vec3(.95,.97,.90)*vec3(.15,.75,.95))
#define B(a,b,c,d,uv) mix(a,b,u.x)+(c-a)*u.y*(1.-u.x)+(d-b)*u.x*u.y

mat2 Q(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float ns(vec2 uv) {
    vec2 i=floor(uv),u=fract(uv);
    u=u*u*(3.-2.*u);
    return B(H21(i),H21(i+V.xy),H21(i+V.yx),H21(i+V.xx),uv);
}

float FB(vec2 p) {    
    float h=.5,w=2.5,m=.25,i;
    for (i=0.;i<4.;i++) {h+=w*ns((p*m));w*=.5;m*=2.;}
    return h;
}

float map(vec3 p) { return L(p.y-1.2-.5*sin(p.z*1.5+p.x*.5))-FB(p.xz*1.5)*.65;}

void main(void) {
    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    vec3 C = vec3(.1),
         p = V.yyy,
         c = V.yyy,
        ro = vec3(0,1,6),
        rd = Nz(vec3(uv,-1));

    mat2 rx = Q(-2.8),
         ry = Q(0.0); //Q((M.x/R.x)*PI2);

    ro.yz*=rx; ro.xz*=ry; 
    rd.yz*=rx; rd.xz*=ry;

    float d=0.;
    for(int i=0; i++<80 && d<75.; ){
        p = ro+rd * d;
        p.x-=1.5*T;
        float x = map(p);
        d+=i<20?.5*x:.75*x;
    }

    float t = map(p);
    vec2 e = vec2(d*.001,0);
    vec3 l = Nz(vec3(2,-15,-5)),
         n = t - N(p,e);
         n = Nz(n);
    vec3 h = H(floor(p.y*5.)*.85);

    C = clamp(dot(n,l),.02,.9)*h;
    C = mix(C,H(.39),1.-exp(-.00025*d*d*d));
    glFragColor = vec4(pow(C,vec3(.4545)),1);
}
