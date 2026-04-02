#version 420

// original https://www.shadertoy.com/view/ctG3WG

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #021
    05/19/2023  @byt3_m3chanic
    Can't stop - won't stop | Truchet Core \M/->.<-\M/ 2023 
    
*/

#define R           resolution
#define M           mouse*resolution.xy
#define T           time

#define PI          3.14159265358
#define PI2         6.28318530718

#define MIN_DIST    1e-4
#define MAX_DIST    35.

// globals & const
mat2 r90,spin;
const vec3 size = vec3(1.);
const vec3 sz2 = size*2.;
const vec3 hlf =  size/2.;
const float thick = .0275;

mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){return fract(sin(dot(p,vec2(23.73,59.71+date.z)))*4832.3234); }

float box(vec3 p,vec3 b){
    vec3 q = abs(p)-b; return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.);
}

float cap(vec3 p,float r,float h){
    vec2 d = abs(vec2(length(p.xy),p.z))-vec2(h,r);
    return min(max(d.x,d.y),0.)+length(max(d,0.));
}
 
float trs( vec3 p,vec2 t){
    vec2 q = vec2(length(p.zx)-t.x,p.y); return length(q)-t.y;
}

vec3 hp,hit;
vec2 map(vec3 p) {
    vec2 res = vec2(1e5,0.);
    
    //@mla inversion
    float k = 5.0/dot(p,p); 
    p *= k;
    p +=vec3(hlf.xy,T*.3);

    vec3 q = p;
    vec3 id = floor((q + hlf)/size);
    q = mod(q+hlf,size)-hlf;
    
    //3D every other
    float chk = mod(id.y+mod(id.z+id.x,2.),2.)*2.-1.;

    float hs = hash21(id.xz+id.y);
    if(hs>.85) { q.yz*=r90; } else if(hs>.65) { q.xz*=r90; } else if(hs>.45) { q.xy*=r90; }

    vec2 d3 = vec2(length(q.xy-hlf.xy), length(q.xy+hlf.xy));
    vec2 gy = d3.x<d3.y ? vec2(q.xy-hlf.xy) : vec2(q.xy+hlf.xy);
    vec3 tz = vec3(gy.xy,q.z);
    
    float xhs = fract(2.31*hs+id.y);
    float trh = 1e5, trx = 1e5, srh = 1e5, dre = 1e5, jre=1e5;

    if(chk>.5){
        trh = min(cap(q.zyx,hlf.z,thick),cap(q,hlf.x,thick));
        trh = max(trh,-(length(q)-(hlf.x*.45)));
        trh = min(trs(q,vec2(hlf.x*.45,thick)),trh);
        dre = length(q.xz)-thick;
        trx = min(dre,trh);
    } else{
       jre = trs(tz.yzx,vec2(hlf.x,thick));
       dre = length(q.xy)-thick;
       srh = min(dre,jre);
    }

    if(trx<res.x ) {
        float mt = xhs>.725?5.:xhs>.61?4.:xhs>.25?2.:3.;
        hp = q;
        if(dre<trh) { mt = mt+5.; hp = q;}
        res = vec2(trx,mt);
        
    } 
    
    if(srh<res.x ) {
        float mt = xhs>.725?5.:xhs>.61?4.:xhs>.25?2.:3.;
        hp = tz;
        if(dre<jre){ mt = mt+5.; hp = q.xzy;}
        res = vec2(srh,mt);
    } 

    float ck = thick*.65, cr = thick*2.;
    float crt = cap(vec3(q.xy,abs(q.z))-vec3(0,0,hlf),ck,cr);  
    crt = min(cap(vec3(q.zy,abs(q.x))-vec3(0,0,hlf),ck,cr),crt);
    crt = min(cap(vec3(q.xz,abs(q.y))-vec3(0,0,hlf),ck,cr),crt);

    if(crt<res.x) {
       res = vec2(crt,1.);
    } 

    // compensate for the scaling that's been applied
    float mul = 1./k;
    res.x = res.x* mul / 1.5;
    return res;
}

// Tetrahedron technique @iq
// https://iquilezles.org/articles/normalsSDF
vec3 normal(vec3 p, float t) {
    float e = MIN_DIST*t;
    vec2 h =vec2(1,-1)*.5773;
    vec3 n = h.xyy * map(p+h.xyy*e).x+
             h.yyx * map(p+h.yyx*e).x+
             h.yxy * map(p+h.yxy*e).x+
             h.xxx * map(p+h.xxx*e).x;
    return normalize(n);
}

void main(void) //WARNING - variables void ( out vec4 O, in vec2 F ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0);

    vec2 uv = (2.* F.xy-R.xy)/max(R.x,R.y);

    r90 = rot(1.5707);
    spin = rot(T*.1);
    
    float vv = uv.y+.3+(.05*sin(uv.x*6.));
    vec3 fog = mix(vec3(.025,.1,.2),vec3(.5),clamp(vv,0.,1.));
    
    vec3 ro = vec3(0,0,1);
    vec3 rd = normalize(vec3(uv,-1));

    ro.xy *= spin; rd.xy *= spin;

    vec3 C = vec3(.0), p = ro;
    float m = 0., d = 0.;
    
    for(int i=0;i<128;i++) {
        p = ro + rd * d;
        vec2 ray = map(p);
        if(ray.x<d*MIN_DIST||d>MAX_DIST)break;
        d += i<32? ray.x*.3: ray.x*.8;
        m  = ray.y;
    } 
    
    hit=hp;
    
    if(d<MAX_DIST)
    {
        vec3 n = normal(p,d);
        vec3 lpos =  vec3(-hlf.x,sz2.y+hlf.y,sz2.z);
        vec3 l = normalize(lpos-p);
        
        float diff = clamp(dot(n,l),.0001,.99);
        float spec = pow(max(dot(reflect(l, n),rd),.001),14.)*2.;

        vec3 h = vec3(.0);

        if(m==1.) {h=vec3(.25);}
        if(m==2.) {h=vec3(.89,.37,.03);}
        if(m==3.) {h=vec3(.22,.44,.77);}
        if(m==4.) {h=vec3(1);}
        if(m==5.) {h=vec3(.025);}
        
        if(m>5.) {
            vec3 hp = hit;
            //@Fabrice uv for the cylinder 
            vec2 uv   = vec2(atan(hp.z,hp.x)/PI2,hp.y);

            float px  = .01;
            vec2 scale= vec2(8.,42.);
            vec2 grid = fract(uv.xy*scale)-.5;
            vec2 id   = floor(uv.xy*scale);
            float rnd = hash21(id);
            if(rnd>.5) grid.x*=-1.;
            float chk = mod(id.y + id.x,2.) * 2. - 1.;
            vec2 d2 = vec2(length(grid-.5),length(grid+.5));
            vec2 gx = d2.x<d2.y? vec2(grid-.5):vec2(grid+.5);

            float xck = length(gx)-.5;
            float center = (rnd>.5 ^^chk>.5)? smoothstep(-px,px,xck):smoothstep(px,-px,xck);
            h = mix(h, vec3(.2),center);
            C = h*diff;
        } else {
            C =clamp(h*diff+spec,vec3(0),vec3(1));
        }
    }

    C = mix(C,fog,1.-exp(-20.*d*d*d));
    C = pow(C, vec3(.4545));
    O = vec4(C,1.);
    
    glFragColor=O;
}