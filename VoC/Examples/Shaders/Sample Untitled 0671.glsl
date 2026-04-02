#version 420

// original https://www.shadertoy.com/view/NtfBWs

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

    Daily Practice
    05/05/22 | byt3_m3chanic

    Just experimenting with things
    
*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy

#define PI          3.14159265359
#define PI2         6.28318530718

#define MIN_DIST    .001
#define MAX_DIST    45.

//@dean_the_coder
#define sat(x)clamp(x, 0., 1.)
#define S(a, b, c) smoothstep(a, b, c)
#define S01(a) S(.4, 1., a)

float hash21(vec2 a){ return fract(sin(dot(a, vec2(27.609, 57.583)))*43758.5453); }
mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

//@iq https://iquilezles.org/articles/palettes
vec3 hue(float t){ 
    vec3 d = vec3(0.110,0.949,0.780);
    return .75+.4*cos( PI2*t*vec3(0.969,0.875,0.875)*d ); 
}

float box(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float cap( vec3 p, float h, float r ){
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}
// globals
vec3 hp,hitPoint;
vec2 sid,gid;
mat2 rt1,rt2,rt3,turn;
float glow,sticks,flame,mtime;

// constants
const float amount = 18.;
float rrt = 4.;

vec2 map(vec3 p, float sg) {
    vec2 res = vec2(1e5,0.);

    float d = length(p-vec3(0,2.+1.*sin(T*.3),0))-1.25;
    d = min(length(p+vec3(0,2,0))-1.75,d);
    vec3 q=p;
    
    if(sg>0.) {
        glow = sat(glow+(.001/(.1+d*d)));
    }
    q.xz*=turn;

    float a = atan(q.z, q.x);
    float ia = floor(a/PI2*amount);
    ia = (ia + .5)/amount*PI2;

    q.xz *= rot(ia);
    q-=vec3(4,2,0);
    q.y=abs(q.y-.55)-2.25;

    float t = box(vec3(q.xy,abs(q.z)-.15),vec3(.65,.125,.035))-.0025;
    d=min(box(vec3(q.x+.5,q.y,abs(q.z)-1.15),vec3(.1,.225,1.))-.0025,d);
    q-=vec3(.65,0,0);
    rt2 = rot(T*.5-(ia*rrt));
    q.xy*=rt2;
    q+=vec3(.5,0,0);

    float g = box(vec3(q.xy,abs(q.z)-.075),vec3(.5,.125,.05))-.0025;
    if(g<res.x) {
        res=vec2(g,4.);
        hp=q;
    }
    
    q+=vec3(.5,0,0);
    rt3 = rot(T*.3+(ia*rrt));
    q.xy*=rt3;
    
    if(t<res.x) {
        res = vec2(t,3.);
        hp=q;
        sid=vec2(ia);
    }

    float t2 = cap(q,.9,.05);
    float t3 = length(q-vec3(0,.9,0))-.25;
    float hss = hash21(vec2(ia)+mtime);
    if(sg>0.) {
       if(hss>.75){
           flame = sat(flame+(.001/(.1+t3*t3)));
       }else{
           sticks = sat(sticks+(.001/(.1+t3*t3)));
       }
    }
    t2=min(t2,t3);
    if(t2<res.x) {
        res = vec2(t2,5.);
        hp=q;
        sid=vec2(ia);
    }

    // delayed 
    if(d<res.x) {
        res = vec2(d,2.);
        hp=p;
    }

    float f = p.y+2.;
    if(f<res.x) {
        res = vec2(f,1.);
        hp=p;
    }
    
    return res;
}

// Tetrahedron technique @iq
// https://iquilezles.org/articles/normalsSDF
vec3 normal(vec3 p, float t) {
    float e = MIN_DIST*t;
    vec2 h =vec2(1,-1)*.5773;
    vec3 n = h.xyy * map(p+h.xyy*e,0.).x+
             h.yyx * map(p+h.yyx*e,0.).x+
             h.yxy * map(p+h.yxy*e,0.).x+
             h.xxx * map(p+h.xxx*e,0.).x;
    return normalize(n);
}

vec2 marcher(vec3 ro, vec3 rd, inout vec3 p, inout bool hit, int steps) {
    hit = false; float d=0., m = 0.;
    for(int i=0;i<steps;i++) {
        p = ro + rd * d;
        vec2 t = map(p,1.);
        if(abs(t.x)<d*MIN_DIST) hit = true;
        d += i<32? t.x*.5:t.x;
        m  = t.y;
        if(d>MAX_DIST) break;
    } 
    return vec2(d,m);
}

const vec3 FC = vec3(0.122,0.122,0.122);
vec3 render(inout vec3 ro, inout vec3 rd, inout vec3 ref, int bnc, inout float d) {
        
    vec3 RC=vec3(0);
    vec3 p = ro;
    float m = 0., fA = 0., f = 0.;
    bool hit = false;
    
    vec2 ray = marcher(ro,rd,p, hit, 128);
    d = ray.x;
    m = ray.y;
    hitPoint = hp;
    gid=sid;
    if(d<MAX_DIST)
    {
        vec3 n = normal(p,d);
        vec3 lpos = vec3(12.5,15,-15.5);
        vec3 l = normalize(lpos-p);

        float diff = clamp(dot(n,l),0.,1.);
        
        float shdw = 1.0;
        //@Shane
        for( float t=.01;t<16.; ) {
            float h = map(p + l*t,0.).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 18.*h/t);
            t += h;
            if( shdw<MIN_DIST || t>42. ) break;
        }
        diff = mix(diff,diff*shdw,.5);

        vec3 view = normalize(p - ro);
        vec3 ret = reflect(normalize(lpos), n);
        float spec =  0.75 * pow(max(dot(view, ret), 0.), 24.);

        vec3 h = vec3(.25);

        if(m==1.) h=FC;
        if(m==3.) {
            gid.x=mod(floor(gid.x*amount),4.);
            
            h=hue(hash21(gid.xx)+6.4);
        }
        
        if(m==4.) {
            h=vec3(.001); 
            vec2 uv = hitPoint.xy;
            vec2 f=fract(uv);
            if(mod(uv.x,.05)<.025) h=vec3(.1);
        }
        ref=h;
        
        if(m==5.) {
            gid.x=mod(floor(gid.x*amount)+2.,4.);
            
            h=hue(hash21(gid.xx)+6.4);
            ref=vec3(0);
        }

        RC = h * diff + min(spec,shdw);
        if(bnc<2) RC = mix(RC,FC, 1.-exp(-.0015*d*d*d));
        
        ro = p+n*.1;
        rd = reflect(rd,n);
        
    } 
    
    glow = S01(sat(glow));
    flame = S01(sat(flame));
    sticks = S01(sat(sticks));

    RC += vec3(0.506,0.859,0.914)*glow; 
    RC += vec3(1.000,0.894,0.200)*sticks; 
    RC += vec3(0.831,0.298,0.067)*flame; 
    
    RC=clamp(RC,vec3(0),vec3(1));
    
    return RC;
}

void main(void)
{

    turn = rot(T*.3);
    mtime = floor(T*3.);
    rrt=4.+3.*sin(T*.3);
    // mouse //
    float x = 0.0; //M.xy==vec2(0) ? 0. : -(M.y/R.y*.5-.25)*PI;
    float y = 0.0; //M.xy==vec2(0) ? 0. : -(M.x/R.x*2.-1.)*PI;

    rt1 = rot(T*.215);
    rt2 = rot(cos(T*.195)*PI2);
    rt3 = rot(sin(T*.175)*PI2);
    
    // uv ro + rd
    vec2 uv = (2.* gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    vec3 ro = vec3(0, 1.5, 10.25);
    vec3 rd = normalize(vec3(uv, -1.0));

    // camera //
    mat2 rx =rot(.3-(.3+.2*sin(T*.1) ));
    mat2 ry =rot(.78+y);
    
    ro.zy*=rx;rd.zy*=rx;
    ro.xz*=ry;rd.xz*=ry;

    vec3 C=vec3(0), RC=vec3(0), ref=vec3(0), fill=vec3(1);
    vec3 p = ro;
    float m = 0., d = 0., fA = 0., f = 0.;
    bool hit = false;
 
    int bnc = 3;
    for(int i = 0; i < bnc + min(frames, 0); i++){
        RC = render(ro,rd,ref,bnc-i,d);
        C += RC*fill;
        fill *= ref; 
        if(i==0)fA=d;
    }
    C = mix(C,FC, 1.-exp(-.00045*fA*fA*fA));
    C = pow(C, vec3(.4545));
    C = clamp(C,vec3(.0),vec3(1));
    glFragColor = vec4(C,1.0);
}
