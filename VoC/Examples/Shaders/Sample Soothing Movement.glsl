#version 420

// original https://www.shadertoy.com/view/fsscWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

    Soothing Movement | Twitter Replication
    01/18/22 @byt3_m3chanic 
    
    Saw this done in Blender / Geometry nodes and wanted to see if 
    I could make it in a shader! https://twitter.com/frktnv/status/1484167941025316867

    Using ABS to mirror movement - not sure I have it totally correct. Still stumped on
    how to do the coloring as in the tweet... but I like the movement.
*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy

#define PI          3.14159265359
#define PI2         6.28318530718

#define MIN_DIST    .001
#define MAX_DIST    175.
float hash21(vec2 a){ return fract(sin(dot(a, vec2(27.609, 57.583)))*43758.5453); }
mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

float lsp(float b,float e,float t) { return clamp((t-b)/(e-b),0.,1.); }
float eoc(float t){return (t=t-1.)*t*t+1.; }

float box(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float capp( vec3 p, float h, float r ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

//global
vec3 hp,hitPoint;
float tmod,ga1,ga2,ga3,ga4,ga5;
mat2 rpi,rnp,rg1,rg2,rg3,rg4,rg1a,rg2a,rg3a,rg4a;

const float scale = 4.;
const float quad = scale/2.;
const float cell = quad/2.;
const float spce = cell/2.;
const vec2 l = vec2(scale,scale);
const vec2 s = l*2.;

vec2 map(vec3 q3) {
    q3.y+=1.5;
    q3.x+=T*.4;
    vec2 res = vec2(1e5,0.);

    vec2 p,
         ip,
         id = vec2(0),
         ct = vec2(0);

    const vec2[4] ps4 = vec2[4](vec2(-.5, .5), vec2(.5),   vec2(.5, -.5), vec2(-.5));
    
    float ld=1e5,lf=1e5,lb=1e5,bx=1e5;
    
    // Multi Tap distance map picked up from @Shane
    // https://www.shadertoy.com/view/WtffDS
    for(int i = 0; i<4; i++) {
    
        ct = ps4[i]/2. -  ps4[0]/2.;    // Block center.
        p = q3.xz - ct*s;                // Local coordinates. 
        ip = floor(p/s) + .5;            // Local tile ID. 
        p -= (ip)*s;                     // New local position.           
        vec2 idi = (ip + ct)*s;            // Correct position & tile ID.

        vec3 q = vec3(p.x,q3.y,p.y);

        vec3 q1 = vec3(p.x+cell,q3.y,p.y+cell);
        q1.xz=abs(abs(q1.xz)-scale)-quad;
 
        if(tmod<1.){
            q1.z+=ga1*quad;
            q1.yz*=rg2;
        }else if(tmod<2.){
            q1.z+=quad;
            q1.x+=ga2*quad;
            q1.yz*=rnp;
            q1.yx*=rg3;

        }else if(tmod<3.){
            q1.z-=quad;
            q1.x-=quad;
            q1.z+=ga3*quad;
            q1.yz*=rg2a;
        } else {
            q1.x+=quad;
            q1.x-=ga4*quad;
            q1.yx*=rpi;
            q1.yx*=rg3a;
        }

        float s1 = length(q1)-.65;

        s1=max(box(q1+vec3(spce,0,spce),vec3(.5,1,.5)),s1);
        ld = min(ld,s1);

        if(ld<res.x) {
            res = vec2(ld,1.);hp=q1;
        }

        q.xz=abs(abs(q.xz)-quad)-cell;
        lb = min( capp(q,.05,1.), bx); 
        lb = min( capp(q,.05,1.), lb);
    }

    if(lb<res.x) {
        res = vec2(lb,5.);
        hp=q3;
    }
        
    float fx = q3.y+.575;
    if(fx<res.x) {
        res = vec2(fx,6.);
        hp=q3;
    }
    
    return res;
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF
vec3 normal(vec3 p, float t) {
    float e = MIN_DIST*t;
    vec2 h =vec2(1,-1)*.5773;
    vec3 n = h.xyy * map(p+h.xyy*e).x+
             h.yyx * map(p+h.yyx*e).x+
             h.yxy * map(p+h.yxy*e).x+
             h.xxx * map(p+h.xxx*e).x;
    return normalize(n);
}

vec2 marcher(vec3 ro, vec3 rd, inout vec3 p, inout bool hit, int steps) {
    hit = false; float d=0., m = 0.;
    for(int i=0;i<steps;i++)
    {
        vec2 t = map(p);
        t.x *= .8;
        if(t.x<1e-4) hit = true;
        d += t.x;
        m  = t.y;
        p = ro + rd * d;
        if(d>175.) break;
    } 
    return vec2(d,m);
}

vec3 render(inout vec3 ro, inout vec3 rd, inout vec3 ref, int bnc, inout float d) {
        
    vec3 RC=vec3(0);
    vec3 p = ro;
    float m = 0., fA = 0., f = 0.;
    bool hit = false;
    
    vec2 ray = marcher(ro,rd,p, hit, 128);
    d = ray.x;
    m = ray.y;
    hitPoint = hp;

    if(d<MAX_DIST)
    {
        vec3 n = normal(p,d);
        vec3 lpos =  vec3(-1.5,8,-2.5);
        vec3 l = normalize(lpos);

        float diff = clamp(dot(n,l),0.,1.);

        float shdw = 1.0;
        float t=.025;
        for( int i =0; i<16; i++ ) {
            float h = map(p + l*t).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 18.*h/t);
            t += h * .9;
            if( shdw<MIN_DIST || t>32. ) break;
        }
        diff = mix(diff,diff*shdw,.75);

        float fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 11.);
        fresnel = mix(.0, .9, fresnel);

        vec3 view = normalize(p - ro);
        vec3 ret = reflect(normalize(lpos), n);
        float spec =  0.75 * pow(max(dot(view, ret), 0.), 24.);

        vec3 h = vec3(.5);

        
        if(m==1.) {
           vec2 uv = fract((hitPoint.xz+cell)*spce)-.5;
           //vec2 id = floor((hitPoint.xz+cell)/quad);
           h=vec3(0.004,0.322,0.616);
           
           //if(mod(id.x+id.y,2.)<1.) h = (fl.x<fl.y)?vec3(0.180,0.761,0.216):vec3(0.180,0.569,0.761);
           float cir=length(uv)-.25;
           cir=abs(abs(abs(abs(cir)-.04)-.02)-.01)-.0045;
           
           cir=smoothstep(.0011,.001,cir);
           h=mix(h,vec3(1.000,0.584,0.000),cir);
           ref = clamp(h-fresnel,vec3(0),vec3(1));
        }
        if(m==5.) {
            h=vec3(.3);
            ref = clamp(vec3(.3)-fresnel,vec3(0),vec3(1));
        }

        if(m==6.) {
            vec2 uv = fract(hitPoint.xz*.5)-.5;
            h=vec3(0.796,0.737,0.584);
            ref=vec3(.0);
            if(uv.x*uv.y>0.) {
                h = vec3(.2);
                ref = clamp(h-fresnel,vec3(0),vec3(1));
           }
        }

        RC = h * diff + min(spec,shdw);
        if(bnc<2) RC = mix(RC,vec3(.05), 1.-exp(-.0025*d*d*d));
        
        ro = p+n*.1;
        rd = reflect(rd,n);
        
    } else {
        RC = vec3(.05);
    } 

    return RC;
}

const vec3 FC = vec3(0.149,0.157,0.173);
void main(void)
{
    tmod = mod(T*.5,4.);
    float t1 = lsp(0.0, 1.0, tmod);
    ga1 = eoc(t1);
    ga1 = ga1*ga1*ga1;

    float t2 = lsp(1.0, 2.0, tmod);
    ga2 = eoc(t2);
    ga2 = ga2*ga2*ga2;
    
    float t3 = lsp(2.0, 3.0, tmod);
    ga3 = eoc(t3);
    ga3 = ga3*ga3*ga3;

    float t4 = lsp(3.0, 4.0, tmod);
    ga4 = eoc(t4);
    ga4 = ga4*ga4*ga4;
    
    rpi = rot(PI);
    rnp = rot(-PI);

    rg2 = rot(-ga1*PI);
    rg3 = rot(ga2*PI);

    rg2a = rot(-ga3*PI);
    rg3a = rot(ga4*PI);

    // uv ro + rd
    vec2 uv = (2.* gl_FragCoord.xy-R.xy)/max(R.x,R.y);

    float zoom = 5.;
    vec3 ro = vec3(uv*zoom,-zoom-2.);
    vec3 rd = vec3(0.,0.,1.);

    mat2 rx =rot(.58);
    mat2 ry =rot(-.68);
    
    ro.zy*=rx;rd.zy*=rx;
    ro.xz*=ry;rd.xz*=ry;

    vec3 C=vec3(0), RC=vec3(0), ref=vec3(0), fill=vec3(1);
    vec3 p = ro;
    float m = 0., d = 0., fA = 0., f = 0.;
    bool hit = false;
 
    int bnc = 2;
    for(int i = 0; i < bnc; i++){
        RC = render(ro,rd,ref,bnc-i,d);
        C += RC*fill;
        fill *= ref; 
        if(i==0)fA=d;
    }
    C = mix(C,vec3(.05), 1.-exp(-.00015*fA*fA*fA));
    C = mix(C,FC,smoothstep(0.,1.,f*0.015));
    C = pow(C, vec3(.4545));
    glFragColor = vec4(C,1.0);
}
