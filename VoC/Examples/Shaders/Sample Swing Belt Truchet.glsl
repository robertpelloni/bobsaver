#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3tGfz1

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Swing Belt Truchet || @pjkarlik
    
    More self learning, posting to share. Trying to 
    figure out how to move without deforming objects,
    add id's to objects on tracks that is deformed, 
    texture map to moving objects, add rotation on things.. 
    
    There is a glitch in my PI or PI2 or however 
    I am doing the math but - yay symtery in objects, 
    so you don't notice.. 
*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy
#define S           smoothstep

#define PI          3.14159265359
#define PI2         6.28318530718

#define MAX_DIST    25.
#define MIN_DIST    .001

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))

//The hash functions
float hash(float n) {  return fract(sin(n)*43.54); }
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43.5453); }
//Sum noise
float noise(in vec2 x){
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.-2.*f);
    float n = p.x + p.y*57.;
    float res = mix(mix( hash(n+  0.1), hash(n+  1.1),f.x),
                    mix( hash(n+ 57.1), hash(n+ 58.1),f.x),f.y);
    return res;
}
vec3 getMouse( vec3 ro ) {
    float x = 0.0;//M.xy==vec2(0) ? .0 : -(M.y / R.y * .25 - .125) * PI;
    float y = 0.0;//M.xy==vec2(0) ? .0 :  (M.x / R.x * .25 - .125) * PI;
    ro.zy *= r2(x);
    ro.zx *= r2(y);
    return ro;
}
//http://mercury.sexy/hg_sdf/
float vmax(vec3 v) {
    return max(max(v.x, v.y), v.z);
}
float fBox(vec3 p, vec3 b, float r) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)))-r;
}
//@iq
float sdCap( vec3 p, float h, float r ){
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}
// lazy globals
vec3 g_hp,s_hp;
vec2 g_id,s_id,g_uv,s_uv,p_id;
float g_hsh,s_hsh;
float ga1,ga2,ga3,ga4,ga5,ga6,sft,rft;

const vec2 sc = vec2(.5), hsc = .5/sc; 
const float amt = 10.;
const float dbl = amt*2.;

vec2 map(in vec3 p) {
    vec2 res=vec2(100.,0.);
    p -=vec3(13.5+sft,.15,0.);
    vec3 op = p;
    op.y += .075+.075*sin(p.x*2.13+p.z*1.8);
    vec2 iq = floor(p.xz*sc) + .5;    
    vec2 q = p.xz - iq/sc;
    vec3 pd = vec3(q.x,op.y,q.y);
    
    // Flip random cells
    float rnd = hash21(iq);
    if(rnd<.5) q.y = -q.y;
    
    // @Shane - truchet construction 
    // Circles on opposite square vertices.
    vec2 d2 = vec2(length(q - hsc), length(q + hsc));  
    // Using the above to obtain the closest arc.
    float crv = abs( min(d2.x, d2.y) - hsc.x);
    float dir = mod(iq.x + iq.y, 2.)<.5? -1. : 1.;
    
    vec2 pp = d2.x<d2.y? vec2(q - hsc) : vec2(q + hsc);
    pp *= r2(sft*dir);

    //Polar angle.
    float a = atan(pp.y, pp.x);
    float ai = floor(dir*a/PI*amt);
    // Repeat central angular cell position.
    a = (floor(a/PI2*dbl) + .5)/dbl;
    // make id's for track objects
    float ws = mod(ai,amt);

    vec2 qr = r2(-a*PI2)*pp; 
    qr.x -= hsc.x;
    
    //vecs for swinging
    vec3 npos = vec3(qr.x, op.y-.4415, qr.y);
    vec3 nnos = vec3(qr.x, op.y-.7, qr.y);
    
    //flip and flop - this whole thing confuses me
    //but thanks to symetry it looks ok
    float swn = (.18*cos(rft+ws))*dir;
    nnos.xy *=rnd>.5 ? r2(PI-swn*PI) : r2(PI+swn*PI);

    float blox = fBox(nnos-vec3(0,.25,0),vec3(.125,.135,.001),.0001);
    float cl = length(nnos.yx-vec2(.25,0))-.08;
    blox = max(blox,-cl);
 
    if(blox<res.x) {
        res = vec2(blox,4.);
        g_hp= nnos;
        g_id=vec2(ws);
    }
    // poles and stuff 
    float c2 = min(sdCap(nnos,.25,.0025),length(nnos-vec3(0,.25,0))-.05); 
          c2 = min(sdCap(npos.zxy-vec3(0.,-.125,.25),.25,.0055),c2);
          c2 = min(length(vec3(abs(npos.x),npos.yz)-vec3(.125,.25,0.))-.0135,c2);
    float c2a = length(npos-vec3(0,.25,0))-.024;
          
    if(c2<res.x) {
        res = vec2(c2,1.);
        g_hp= npos;
    }
    
    if(c2a<res.x) {
        res = vec2(c2a, 2.);
        g_hp= nnos;
        g_id=vec2(ws);
    }
    //truchet track
    vec3 ddc = vec3(abs(crv)-.145, (op.y-.425)-.245,crv);
    float bx = fBox(ddc, vec3(.0325, .005,1.), .0025);
    float bf = fBox(ddc, vec3(.0065, .015,1.), .0005);
    if(bx<res.x) {
        res = vec2(bx, 3.);
        g_hp=p;
    }
    
    if(bf<res.x) {
        res = vec2(bf, 3.);
        g_hp=p.xzy;
    }

    // water ground plane
    p.xz = fract(p.xz*sc)-.5;
    float base = fBox(p+vec3(0,1.,0),vec3(.48,.01,.48),.015);//+wbase;
    if(base<res.x) {
        res = vec2(base,dir>0. ? 5.:1.);
        g_hp=p;
        g_id=iq;
    }
 
    return res;
}

vec2 marcher( in vec3 ro, in vec3 rd, int maxstep) {
    float t = 0.,m = 0.;
    for( int i=0; i<maxstep; i++ ) {
        vec2 d = map(ro + rd * t);
        m = d.y;
        if(abs(d.x)<MIN_DIST*t||t>MAX_DIST) break;
        t += i<64 ? d.x*.5 : d.x;
    }
    return vec2(t,m);
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 getNormal(vec3 p, float t){
    float h = t * MIN_DIST;
    //prevent from inlining @spalmer 
    #define ZERO (min(frames,0))
    vec3 n = vec3(0.0);
    for(int i=ZERO; i<4; i++) {
        vec3 e = 0.5773*(2.*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.);
        n += e*map(p+e*h).x;
    }
    return normalize(n);
}

vec3 getSpec(vec3 p, vec3 n, vec3 l, vec3 ro) {
    vec3 spec = vec3(0.);
    float strength = 0.75;
    vec3 view = normalize(p - ro);
    vec3 ref = reflect(l, n);
    float specValue = pow(max(dot(view, ref), 0.), 32.);
    return spec + strength * specValue;
}

float getDiff(vec3 p, vec3 n, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    float dif = clamp(dot(n,l),.01 , 1.);
    float shadow = marcher(p + n * .008, l, 84).x;
    if(shadow < length(p -  lpos)) dif *= .2;
    return dif;
}

//@Shane AO
float calcAO(in vec3 p, in vec3 n){
    float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
        float hr = float(i + 1)*.17/5.; 
        float d = map(p + n*hr).x;
        occ += (hr - d)*sca;
        sca *= .9;
        if(sca>1e5) break;
    }
    return clamp(1. - occ, 0., 1.);
}

const vec3 c = vec3(0.973,0.961,1.000),
           d = vec3(0.808,0.510,0.173),
           a = vec3(.45),
           b = vec3(.45);
           
vec3 hue(float t){ 
    return a + b*cos((PI2*t+time*.15)*c*d); 
}

//@iq SDF functions
float circle(vec2 pt, vec2 center, float r) {
  float len = length(pt - center),
        edge = .001;
  return smoothstep(r-edge,r, len);
}

float circle(vec2 pt, vec2 center,float r,  float lw) {
  vec2 p = pt - center;
  float len = length(p),
        hlw = lw / 2.,
       edge = .001;
  return smoothstep(r-hlw-edge,r-hlw, len)-smoothstep(r+hlw,r+hlw+edge, len);
}

vec4 getRock(vec3 p){
    vec3 mfp = (p + dot(p,vec3(0,1,0))*2.);
    float brk = 0.0;
    brk += abs(noise(mfp.xz*2.)-.5);
    brk += abs(noise(mfp.xz*12.0)-.5)/2.0;
    brk = pow(1.0-clamp(brk,0.0,1.0),15.0);
    return vec4(mix(vec3(0),vec3(1), brk ), brk);
}

const vec3 woodAxis = normalize(vec3(1,-3,2));
vec4 getWood(vec3 p){
    vec3 mfp = (p + dot(p,woodAxis)*woodAxis*17.5)*.75;
    float wood = abs(noise(mfp.yz*2.)-.5);
    wood += abs(noise(mfp.xy*10.)-.5)/2.;
    wood += abs(noise(mfp.xz*7.)-.5)/4.;
    wood /= .75-1.5/21.;
    wood = pow(1.-clamp(wood,0.,1.),15.);
    return vec4(mix( vec3(0.627,0.255,0.051), vec3(0.180,0.043,0.000), wood ), wood);
}

vec3 getStripes(vec2 uv){
    float sd = mod(floor((uv.y* 3.)-.5), 2.);
    return (sd<1.) ? vec3(1.) : vec3(0.);
}

vec3 getColor(float m, in vec3 n) {
    vec3 h = vec3(0.45);

    if(m==1.) h = vec3(.25);
    if(m==2.) h = vec3(0.314,0.141,0.008);
    if(m==3.) h = vec3(0.753,0.827,0.373) * getWood(s_hp*5.25).rgb; 
    
    if(m==4.) {
        float hs = hash21((s_id*.15)+vec2(5.25));
        float hs2 = hash21((s_id*.25)+vec2(5.15));
        h = mix(hue(hs),hue(hs2),getStripes(s_hp.xy*22.));
        vec2 ofst = vec2(.0,.25);
        float ck2 = 1.-circle(s_hp.xy-ofst,vec2(.0),.08 );
        float ck3 =    circle(s_hp.xy-ofst,vec2(.0),.085,.025);
        h = mix(h,hue(hs2),ck2);
        h = mix(h,vec3(1),ck3);
    }
    
    if(m==5.) h = mix(vec3(0.012,0.133,0.149),vec3(.9),getWood(s_hp*.45).r);
    return h;
}

void main(void) {
    sft = time*.25;
    rft = time*1.25;
    vec2 U = (2.*gl_FragCoord.xy.xy-R.xy)/max(R.x,R.y);

    vec3 ro = vec3(0.,1.35,1.65),
         lp = vec3(0,0,0);

    ro = getMouse(ro);
    
    vec3 cf = normalize(lp-ro),
         cp = vec3(0.,1.,0.),
         cr = normalize(cross(cp, cf)),
         cu = normalize(cross(cf, cr)),
         c = ro + cf * .8,
         i = c + U.x * cr + U.y * cu,
         rd = i-ro;

    vec3 C = vec3(0),
         RC= vec3(0);
    vec3 FC= vec3(0.063,0.118,0.090);

    // trace dat map
    vec2 ray = marcher(ro,rd,128);
    s_hp=g_hp;
    s_id=g_id;
    s_hsh=g_hsh;
    if(ray.x<MAX_DIST) {
        vec3 p = ro+ray.x*rd,
             n = getNormal(p,ray.x);
             
        vec3 lpos = ro+vec3(0.,.15,0.);
        vec3 ll = normalize(lpos);
        
        vec3 h = getColor(ray.y,n);  
        float diff = getDiff(p,n,lpos);
        vec3 spec = getSpec(p,n,ll,ro);
        float ao = calcAO(p,n);
   
        C = (h * diff + spec) * ao;
  
        if(ray.y==1.||ray.y==15.){
            vec3 rr=reflect(rd,n); 
            vec2 tr = marcher(p+n*.05,rr, 128);
            s_hp=g_hp;
            s_id=g_id;
            s_hsh=g_hsh;
            if(tr.x<MAX_DIST){
                p += rr*tr.x;
                n = getNormal(p,tr.x); 
                h = getColor(tr.y,n);
                lp = normalize(lpos-p);
                diff = clamp(dot(n,lp),.01 , 1.);
                
                C += (h*diff)*.4;
                C = mix( C, FC, 1.-exp(-.00075*tr.x*tr.x*tr.x));
            }
        } 
    } 
    C = mix( C, FC, 1.-exp(-.0035*ray.x*ray.x*ray.x));
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
