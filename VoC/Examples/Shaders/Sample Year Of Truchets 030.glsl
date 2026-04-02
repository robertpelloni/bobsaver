#version 420

// original https://www.shadertoy.com/view/ml3XzX

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #030
    06/01/2023  @byt3_m3chanic
    Truchet Core \M/->.<-\M/ 2023 

    (mouseable) - AA for good systems = turn AA on with 2 or more.
    
*/

#define ZERO (min(frames,0))
#define AA 2

#define R           resolution
#define T           time
#define M           mouse*resolution.xy

#define P9          1.57078
#define PI          3.14159265359
#define PI2         6.28318530718

#define MIN_DIST    .0001
#define MAX_DIST    35.

// globals
vec3 hit=vec3(0),hitpoint=vec3(0);
vec4 FC=vec4(.267,.443,.635,0);
mat2 turn,spin;
float glow,move,px,stime;

// standard bag of tricks
mat2 rot(float a){ return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){return fract(sin(dot(p,vec2(23.43,84.21)))*4832.3234);}
//@iq torus
float torus(vec3 p,vec2 t){vec2 q=vec2(length(p.xz)-t.x,p.y);return length(q)-t.y;}
//@iq of hsv2rgb
vec3 hsv2rgb( in vec3 c ){
    vec3 rgb = clamp( abs(mod(c.x*6.+vec3(0,4,2),6.)-3.)-1.,0.,1.);
    return c.z * mix(vec3(1),rgb,c.y);
}
float trigger,stored;

float tile(vec3 hp, float type){
    //@Fabrice - based off https://www.shadertoy.com/view/sdtGRn
    float angle = atan(hp.z,hp.x)/PI2;
    float d =  atan(hp.y,length(hp.zx)-2.)/PI2;
    vec2 uv = vec2(angle,d);
 
    vec2 scale = vec2(24.,12);
    float thick = .045;
    
    if(type==2.) {
        uv=hp.xz;
        scale=vec2(1);
        thick = .1;
    }

    vec2 grid = fract(uv.xy*scale)-.5;
    vec2 id   = floor(uv.xy*scale);

    float hs = hash21(id);
    if (hs>.45) grid.x=-grid.x;

    vec2 gplus = grid+.5,gmins = grid-.5;
    vec2 d2 = vec2(length(gmins), length(gplus));
    vec2 q = d2.x<d2.y? vec2(gmins) : vec2(gplus);
    float c = length(q)-.5;

    if(hs>.8) c =  min(length(grid.x)-.001,length(grid.y)-.001);
    c = abs(c)-thick;

    return c;
}

vec2 map(vec3 p, float sg) {
    vec2 res = vec2(1e5,0.);
    vec3 q = p-vec3(0,.5,move-1.);

    q.xy*=spin;
    q.zx*=turn;
    float d1 = torus(q,vec2(2.,.85));
    float d2=max(abs(d1)-.1,d1);

    float t1 = tile(q,1.);
    
    d2=max(d2,-t1);
    
    if(d2<res.x) {
        res=vec2(d2,d1<d2?3.:1.);
        hit=q;
    }
    
    float d3 = torus(q,vec2(2.,.075));
    if(sg==1.) { glow += .001/(.0002+d3*d3);}
    if(d3<res.x) {
        res=vec2(d3,4.);
        hit=q;
    }
    
    float ff = .2*sin(p.x*.4+stime) + .2*cos(p.z*.73+stime);
    float d4 = p.y-ff+2.;
    if(d4<res.x) {
        res=vec2(d4,2.);
        hit=p;
    }

    return res;
}

vec3 normal(vec3 p, float t) {
    float e = MIN_DIST*t;
    vec2 h =vec2(1,-1)*.5773;
    vec3 n = h.xyy * map(p+h.xyy*e,0.).x+
             h.yyx * map(p+h.yyx*e,0.).x+
             h.yxy * map(p+h.yxy*e,0.).x+
             h.xxx * map(p+h.xxx*e,0.).x;
    return normalize(n);
}

vec2 marcher(vec3 ro, vec3 rd) {
    float d = 0., m = 0.;
    for(int i=0;i<112;i++){
        vec2 ray = map(ro + rd * d,1.);
        if(ray.x<MIN_DIST*d||d>MAX_DIST) break;
        d += i<32?ray.x*.25:ray.x*.85;
        m  = ray.y;
    }
    return vec2(d,m);
}

vec4 render(inout vec3 ro, inout vec3 rd, inout vec3 ref, float last, inout float d, vec2 uv) {

    vec3 C = vec3(0);
    vec2 ray = marcher(ro,rd);
    float m =ray.y; d=ray.x;
    
    hitpoint=hit;

    if(d<MAX_DIST)
    {
        vec3 p = ro + rd * d;
        vec3 n = normal(p,d);
        // light
        vec3 lpos =vec3(-25.,15.,10.);
        vec3 l = normalize(lpos-p);
        // difused
        float diff = clamp(dot(n,l),.09,.99);

        // color
        vec3 h = vec3(1.);
        vec3 hp = hitpoint;
        
        if(m==1.) {
            float d = tile(hp,1.);
            vec3 fd = mix(vec3(.2),vec3(.7),clamp(hp.y*2.,0.,1.));
            d=smoothstep(px,-px,abs(d-.15)-.025);
            h = mix(fd,vec3(.6),d);
            ref = h*.1;
        }
        if(m==2.) {
            hp.z-=T*8.;
            float d = tile(hp*.5,2.);
            d=smoothstep(px,-px,abs(abs(d)-.05)-.025);
            vec3 clr = hsv2rgb(vec3((hp.x-hp.z)*.1,1.,.5));
            h = mix(vec3(.6),clr,d);
            ref = vec3(d*.9);
        }
        if(m==3.) {
            h = hsv2rgb(vec3((hp.x+T)*.2,1.,.5));
            ref = h;
        }
        if(m==4.) h = vec3(1);
  
        C = diff*h;
        ro = p+n*.005;
        rd = reflect(rd,n);
    } 
    if(last>0.) C = mix(FC.rgb,C,exp(-.0008*d*d*d));
    return vec4(C,d);
}

vec3 renderALL( in vec2 uv, in vec2 F )
{   

    // standard setup uv/ro/rd
    //vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    vec3 ro = vec3(0,0,5.5);
    vec3 rd = normalize(vec3(uv,-1));

    // mouse
    float x = 0.;
    float y = 0.;

    float pf = .5*sin(T*.35);
    
    mat2 rx = rot(-.58-x), ry = rot(y-pf);
    ro.zy *= rx; ro.xz *= ry; 
    rd.zy *= rx; rd.xz *= ry;
    
    // reflection loop (@BigWings)
    vec3 C = vec3(0);
    vec3 ref=vec3(0), fil=vec3(.95);
    float d =0.,a=0.;

    for(float i=0.; i<2.; i++) {
        vec4 pass = render(ro, rd, ref, i, d, uv);
        C += pass.rgb*fil;
        fil*=ref;
        if(i==0.)a=pass.w;
    }
           
    C = mix(FC.rgb,C,exp(-.00015*a*a*a));
    C = mix(C,vec3(.89),clamp(glow*.5,0.,1.));
   // C=pow(C, vec3(.4545));
    return C;
}

// AA from @iq https://www.shadertoy.com/view/3lsSzf
void main(void) //WARNING - variables void ( out vec4 O, in vec2 F ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0);

    turn = rot(T*.35);
    spin = rot(.2*sin(T*1.15));
    move = -3.*cos(T*.3);
    px  = 10./R.x;
    stime=T*.1;
    vec3 C = vec3(0.0);
#if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 uv = (-R.xy + 2.0*(F+o))/max(R.x,R.y);
#else    
        vec2 uv = (-R.xy + 2.0*F)/max(R.x,R.y);
#endif

        vec3 color = renderALL(uv,F);
        // compress        
        color = 1.35*color/(1.0+color);
        // gamma
        color = pow( color, vec3(0.4545) );

        C += color;
        glow=0.;
#if AA>1
    }
    C /= float(AA*AA);
#endif
    // Output to screen
    O = vec4(C,1.);
    
    glFragColor=O;
}
//end