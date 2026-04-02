#version 420

// original https://www.shadertoy.com/view/flcSWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**

    Cubic Blender V2
    12/15/21 - byt3_m3chanic
    Just playing while waiting for Blender to render out.
 
    https://twitter.com/byt3m3chanic/status/1471029268994043907
    
    also tidbits from @blackle for domain rep/refraction.

*/

#define R   resolution
#define M   mouse*resolution.xy
#define T   time

#define PI          3.14159265358
#define PI2         6.28318530718

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
float hash21(vec2 p){return fract(sin(dot(p,vec2(23.43,84.21)))*4832.3234); }
float lsp(float b,float e,float t) { return clamp((t-b)/(e-b),0.,1.); }
float eoc(float t){return (t=t-1.)*t*t+1.; }

float box(vec3 p,vec3 b){
    vec3 q = abs(p)-b;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.);
}

vec2 edge(vec2 p) {
    vec2 p2 = abs(p);
    return (p2.x > p2.y) ? vec2((p.x<0.)?-1.:1.,0.) : vec2(0.,(p.y<0.)?-1.:1.);
}

// globals & const
vec3 hit,hitPoint;
vec4 gtile,stile;
float glow,ftime,ga1,ga2,ga3,ga4;
mat2 rxt;

const float size = .85;
const float hlf = size/2.;
const vec3 bs = vec3(hlf*.96);

const float zoom = 5.;
const float cp = 3.;

vec2 map(vec3 p, float sg){
    vec2 res = vec2(1e5,0.);

    float zp = p.z+(ga4*16.);
    float zd = floor((zp+8.)/16.);
    p.z+=(ga1*16.);
    p.z=mod(p.z+8.,16.)-8.;
    
    vec3 q = p;
    //domain rep by @blackle https://www.shadertoy.com/view/3lcBD2
    vec2 center = floor(q.xz) + .5;
    vec2 nghbor = center + edge(q.xz - center);
    
    float dist = mod(zd,3.)==0.?center.x+center.y:mod(zd,2.)==0.?center.x:length(center);
    float ht = 1.5*sin((dist*.55)+ftime);
    ht=clamp(ht,0.,3.);
    float oyf = .25;
    
    float me   = box(p - vec3(center.x,ht-oyf,center.y),vec3(bs*.35));
    float next = box(p - vec3(nghbor.x,ht-oyf,nghbor.y),vec3(bs.x*.35,bs.y*2.,bs.z*.35));

    float bx = (abs(q.x)>cp||abs(q.z)>cp) ? next : min(me, next);
    if(sg>0.&&ht>.5) glow += mix(0.,.0001/(.001+bx*bx),clamp(ht-.55,0.,1.)*1.5);
    if(bx<res.x) {
       res = vec2(bx,3.);
       gtile.xyz = vec3(center,zd);
       gtile.w=3.;
       hit = p;
    } 

    float distortion = 28.;
    float dsn = sin(distortion * p.x*.7) * sin(distortion * p.y-oyf) * sin(distortion * p.z*.7) * 0.01;
    float dst = .01;
    float blx = box(p-vec3(center.x,-oyf,center.y),vec3(bs.x*.65,bs.y*.65,bs.z*.65));
    next = box(p-vec3(nghbor.x,-oyf,nghbor.y),vec3(bs.x*.65,bs.y*.65,bs.z*.65));
    blx = max(blx,-box(p-vec3(center.x,-oyf,center.y),vec3(bs.x*.45,bs.y*.85,bs.z*.45)));
    blx-=dsn;

    float ice = (abs(q.x)>cp||abs(q.z)>cp) ? next : min(blx, next);
    if(ice<res.x) {
       res = vec2(ice,5.);
       gtile.xyz = vec3(center,dist);
       hit = p;
    } 
    
    float flr = box(p-vec3(center.x,-.5-oyf,center.y),vec3(bs.x,.075,bs.z));
    next = box(p-vec3(nghbor.x,-.5-oyf,nghbor.y),vec3(bs.x,5.,bs.z));
    
    float gnd = (abs(q.x)>cp||abs(q.z)>cp) ? next : min(flr, next);
    if(gnd<res.x) {
       res = vec2(gnd,7.);
       gtile.xyz = vec3(center,dist);
       hit = p;
    } 

    return res;
}

// normal
vec3 normal(vec3 p, float t, float md) {
    float e = md*t;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( 
        h.xyy*map( p + h.xyy*e,0. ).x + 
        h.yyx*map( p + h.yyx*e,0. ).x + 
        h.yxy*map( p + h.yxy*e,0. ).x + 
        h.xxx*map( p + h.xxx*e,0. ).x );
}

float ptn_d(vec3 p){
    vec2 uv = p.xz;
    uv*=rot(.785);
    vec2 ff = floor(uv);
    float f = clamp(mod(ff.x,2.)*1.-.5,0.,1.);
    float h = mix(1.,.0,f);
    return h;
}
vec3 hue(float t) { 
    vec3 d = vec3(0.220,0.576,0.961);
    return .45 + .375*cos(PI2*t*(vec3(.985,.98,.95)*d)); 
}

vec3 shade(vec3 p, vec3 rd, float d, float m, inout vec3 n, inout vec3 ref) {
    n = normal(p,d,.1);

    vec3 l = normalize(vec3(-15.,25,15)-p);
    float diff = clamp(dot(n,l),.1,.8);
    float spec = pow(max(dot(reflect(l, n), rd ), .1), 32.)*.75;

    vec3 h = vec3(.01);

    if(m==1.) {h=vec3(.5);ref=h;}

    if(m==3.) {h = hue(stile.z*1.5);ref=h*.5;}
    
    if(m==5.) {h = vec3(0.718,0.843,0.816);ref=vec3(.65);}

    if(m==7.) {h=vec3(.01);ref=vec3(.2);}
    
    h*=diff+spec; 
    return h;
}

vec3 renderAll( vec2 PX )
{

    ftime = (T*2.35);
    float tmod = mod(T,10.);
    float t3 = lsp(5.0, 10.0, tmod);
    ga1 = eoc(t3);
    ga1 = ga1*ga1*ga1;

    ga4 = (t3)+floor(T*.1);
    
    vec2 uv = (2.*PX.xy-R.xy)/max(R.x,R.y);
    vec3 C=vec3(.001);

    vec3 ro = vec3(uv*zoom,-zoom-10.);
    vec3 rd = vec3(0,0,1.);

    float x = -.48;

    mat2 rx =rot(.62);
    mat2 ry =rot(x);
    ro.zy*=rx;rd.zy*=rx;
    ro.xz*=ry;rd.xz*=ry;

    float atten=1.,k=1.,alpha=1.;
    vec3 p = ro + rd * .1;
    vec3 fill=vec3(1), ref=vec3(0);
    
    float bt =2.,ct =6.;

    float fA = 0.;
    for(int i=0;i<100;i++)
    {
        vec2 ray = map(p,bt>1.?1.:0.);
        float d = ray.x;
        float m = ray.y;

        p += rd * d *k;

        if (d*d < 1e-6) {
            hitPoint=hit;
            stile=gtile;
            
            alpha *=1e-1;
            
            vec3 h=vec3(0);
            vec3 n=vec3(0);
            
            C+=shade(p,rd,d,ray.y,n,ref)*fill;
            if(bt<1.&&ct<1.)break;

            p += rd*.015;
            k = sign(map(p,0.).x);

            if(m!=5.&&m!=3.){
                fill *= ref;
                rd=reflect(-rd,n);
                p+=n*.02;
                ct--;
            }else if (bt>0.){
                fill *= ref;
                rd=refract(rd,n,.79);
                bt--;
            }
        }  
        if(distance(p,rd)>25.) { break; }
    }

    float mask = smoothstep(.1,.6,length(uv)-.4);
    vec3 clr = mix(vec3(0.282,0.349,0.557),vec3(0.012,0.086,0.310)*.05 ,mask );
    C+=clamp(max(glow,-mask),0.,.95);
    uv*=rot(.785);
    vec2 ff = floor(uv*45.);
    float f = clamp(mod(ff.x,1.5)*1.-.15,0.,1.);
    clr = mix(clr,clr*.7,f);
    C = mix(C,clr,alpha);
  
    return C;
}

// baby AA - make 2 for some kind of smoothness
#define AA 1
void main(void) {
    vec2 F = gl_FragCoord.xy;
    vec3 C = renderAll(F);
    #if AA>1
        C +=renderAll(F+vec2(.5,.5));
        C /= 2.;    
    #endif
    C = pow(C, vec3(.4545));  
    glFragColor = vec4(C,1.);
}
