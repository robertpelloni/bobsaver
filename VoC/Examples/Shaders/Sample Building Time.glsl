#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wltczj

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Presented with little comments.. but lots of code!
// Can someone do a reflections/raymarching example thats good..
// I feel my lame - 2 bounce thing is slow and could be moved to the
// marcher - but not good with that yet! I'd like to make the cubes
// glass and refraction and stuff.. but thats way hard!

#define R           resolution
#define T           time
#define M           mouse*resolution.xy
#define S           smoothstep

#define PI          3.141592653589793
#define PI2         6.283185307

#define MAX_DIST    135.
#define MIN_DIST    .001

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define hue(a) .45 + .40 * cos(PI2 * a + vec3(.75,.5,.25) * vec3(2.89,1.98,.95))

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
    float x = 0.0; //M.xy==vec2(0) ? .0 : -(M.y / R.y * .5 - .25) * PI;
    float y = 0.0; //M.xy==vec2(0) ? .0 :  (M.x / R.x * .5 - .25) * PI;
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

//@iq SDF functions
float sdCap( vec3 p, float h, float r ){
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}
float sdBBox( vec3 p, vec3 b, float e ) {
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

// lazy globals
vec3 htile;
vec3 g_hp,s_hp,g_bid,s_bid;
float g_hsh,s_hsh,travelSpeed,modTime,fractTime,tf;
float ga1,ga2,ga3,ga4,ga5,ga6,glow;
mat2 r60,r13;
    
const float size = 20.;
const float rep_half = size/2.;
const float rr = rep_half/4.75;

vec2 map(vec3 pos, float sg) {
    vec2 res = vec2(100.,0);
    // get center vec and some movement
    vec3 center = vec3(travelSpeed, rr/2.5, -rr/2.);
    vec3 pp = pos-center;
    vec3 sp = pp;
    // make the id's for beams
    vec3 pi = vec3(
        floor((pp + rep_half)/size)
    );
    // make vec and ids for balls
    vec3 tt = pos-center;
    vec3 ti = vec3(
        floor((tt + rep_half)/size)
    );
    float fhs,dhs,bfs;
    if(modTime<2.){
        fhs = hash21(pi.xz+vec2(11,15));
        if(fhs>.57){
            tt.y += fractTime;
        } else {
            tt.y -= fractTime;
        } 
    } else if (modTime<4.){
        dhs = hash21(pi.zy+vec2(11,15));
        if(dhs>.67){
            tt.x += fractTime;
        } else {
            tt.x -= fractTime;
        }
    } else {
        bfs = hash21(pi.xy+vec2(11,15));
        if(bfs>.27){
            tt.z -= fractTime;
        } else {
            tt.z += fractTime;
        }   
    }

    pp =  mod(pp+rep_half,size) - rep_half;
    tt =  mod(tt+rep_half,size) - rep_half;
    //secret mode
    pp.xy*=r13;
    //secret mode
    float deg = 19.9752;
    mat2 rtx = r2(fractTime*PI/deg);
    if(fhs>.5 ){
        tt.yz*=rtx;
    } else {
        tt.yz*=-rtx;
    }
    
    if(dhs>.5 ){
        tt.xy*=rtx;
    } else {
        tt.xy*=-rtx;
    }

    if(bfs>.5){
        tt.zx*=rtx;
    } else {
        tt.zx*=-rtx;
    }

    //framework
    vec3 dp = pp;
    vec3 cp = pp;
    dp.x += pi.x*pi.y > 0. ? tf : -tf;
    cp.y += pi.x*pi.y > 0. ? tf : -tf;
    dp.x=mod(dp.x+.5,1.)-.5;
    cp.y=mod(cp.y+.5,1.)-.5;
    float d2 = fBox(abs(cp)-vec3(8.5,0.,10.), vec3(2. ,.4 , .45), .01 );
    float d3 = fBox(abs(dp)-vec3(0.,8.5,10.), vec3(.4 ,2. , .45), .01 );
    
    float d1 = min(d2,d3);
    if(d1<res.x) {
        res = vec2(d1,5.);
        g_hp = pp;
        g_bid = pi;
    }
  
    //box clips
    d2 = fBox(abs(pp)-vec3(10.,10.,8.), vec3(4.25,4.25,1.) , .001);
    if(d2<res.x) {
        res = vec2(d2,2.);
        g_hp = sp.yzx;
        g_bid = pi;
    }

    d3 = fBox(abs(pp)-vec3(7.25,7.25,8.), vec3(2.5,2.5,.55) , .01);
    if(d3<res.x) {
        res = vec2(d3,3.);
        g_hp = sp;
        g_bid = pi;
    }

    //blocks
    float d4 = sdBBox(abs(tt)-vec3(.9,0,1.75),vec3(.95),.085);
    float d4a = fBox(abs(tt)-vec3(.9,0,1.75),vec3(.35),.085);
    if(d4<res.x) {
        res = vec2(d4,6.);
        g_hp = tt;
        g_bid = ti;
    }
    
    // pipes
    pp.x=abs(pp.x);
    float d11 = min(sdCap(abs(pp.zxy)-vec3(8.,0.,8.), 7.5,.25),
    sdCap(abs(pp)-vec3(8.,0.,8.), 7.5,.25));
    d11 = min(sdCap(abs(pp.yzx)-vec3(8.,0.,8.), 7.5,.25),d11);
    if(d11<res.x) {
        res = vec2(d11,3.);
        g_hp = pp;
    }
    
    float d12 =  sdCap(abs(pp.zxy)-vec3(8.,0.,7.), 7.5,.125);
    float d12a = sdCap(abs(pp)-vec3(7.,0.,8.), 7.5,.125);
    if(d12<res.x) {
        res = vec2(d12,3.);
        g_hp = pp.zxy;
    }
    if(d12a<res.x) {
        res = vec2(d12a,3.);
        g_hp = pp;
    }
    
    float d9 =  min(sdCap(abs(pp.zxy)-vec3(10.,0.,5.75), 5.8,.125),
                    sdCap(abs(pp)-vec3(5.75,0.,10.), 5.8,.125));
    d9=min(d4a,d9);
    if(d9<res.x) {
        res = vec2(d9,0.);
        g_hp = pp.zxy;
    }
    
    if(sg>0.){
        glow += .0065/(.0025+d9*d9);
    }
    return res;
}

vec2 marcher( in vec3 ro, in vec3 rd, int maxstep , float sg) {
    float t = 0.,m = 0.;
    for( int i=0; i<maxstep; i++ ) {
        vec2 d = map(ro + rd * t, sg);
        m = d.y;
        if(abs(d.x)<MIN_DIST*t||t>MAX_DIST) break;
        t += i < 32 ? d.x*.25 :  d.x*.75;
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
        n += e*map(p+e*h, 0.).x;
    }
    return normalize(n);
}

// softshadow www.pouet.net
// http://www.pouet.net/topic.php?which=7931
float softshadow( vec3 ro, vec3 rd, float mint, float maxt, float k ){
    float res = 1.0;
    for( float t=mint; t < maxt; ){
        float h = map(ro + rd*t, 0.).x;
        if( h<0.001 ) return 0.2;
        res = min( res, k*h/t );
        t += h;
    }
    return res+0.2;
}

vec3 getSpec(vec3 p, vec3 n, vec3 l, vec3 ro) {
    vec3 spec = vec3(0.);
    float strength = 0.75;
    vec3 view = normalize(p - ro);
    vec3 ref = reflect(l, n);
    float specValue = pow(max(dot(view, ref), 0.), 32.);
    return spec + strength * specValue;
}
//AO @jeyko
//#define ао(a) smoothstep(0.,1.,map(p + n*a,1.).x/a)
float calcAO(in vec3 p, in vec3 n){
    float fc = .275,nd = .15;
    return map(p + n*nd,0.).x/nd*map(p + n*fc,0.).x/fc; 
}
const float lightner = .75-1.5/18.0;
const vec3 board = vec3(0.62,0.38,0.05);
const vec3 vein = vec3(0.2,0.06,0.01);
const vec3 woodAxis = normalize(vec3(1,-3,2));
vec4 getWood(vec3 p){
    vec3 mfp = (p + dot(p,woodAxis)*woodAxis*15.5)*.50;
    float wood = 0.0;
    wood += abs(noise(mfp.xz*2.)-.5);
    wood += abs(noise(mfp.xz*12.0)-.5)/2.0;
    wood += abs(noise(mfp.xz*14.0)-.5)/4.0;
    wood += abs(noise(mfp.xz*8.0)-.5)/8.0;
    wood /= lightner;
    wood = pow(1.0-clamp(wood,0.0,1.0),5.0); // curve to thin the veins
    return vec4(mix( board, vein, wood ), wood);
}

vec4 getRock(vec3 p){
    vec3 mfp = (p + dot(p,vec3(0,1,0))*2.);
    float brk = 0.0;
    brk += abs(noise(mfp.xz*2.)-.5);
    brk += abs(noise(mfp.xz*12.0)-.5)/2.0;
    brk = pow(1.0-clamp(brk,0.0,1.0),15.0); // curve to thin the veins
    return vec4(mix(vec3(0),vec3(1), brk ), brk);
}

vec3 getStripes(vec2 uv){
    float sd = mod(floor(uv.y * 1.95), 2.);
    return (sd<1.) ? vec3(1.) : vec3(0.);
}

vec3 getColor(float m, in vec3 n) {
    vec3 h = vec3(0.45);
    if(m==1.) h = vec3(.25);
    if(m==2.) h = hue((s_bid.z+34.)*.2);
    if(m==3.) h = vec3(1.000,0.533,0.000) * getWood(s_hp.zyx).rgb; 
    if(m==4.) h = hue((s_bid.z+45.)*.5) * getStripes(s_hp.zy*6.);
    if(m==5.) {
        h = mix(vec3(0.486,0.016,0.016),vec3(0.216,0.004,0.004),getRock(s_hp).rgb); 
        h = mix(h,vec3(0.714,0.106,0.106),getRock(s_hp*2.).rgb);
    }
    if(m==6.) h = vec3(0.922,0.769,0.000) * getWood(s_hp*2.).rgb; 
    return h;
}

// Book Of Shaders - timing functions
float linearstep(float begin, float end, float t) {
    return clamp((t - begin) / (end - begin), 0.0, 1.0);
}

float easeOutCubic(float t) {
    return (t = t - 1.0) * t * t + 1.0;
}

float easeInCubic(float t) {
    return t * t * t;
}

void main(void) { //WARNING - variables void ( out vec4 O, in vec2 F ) { need changing to glFragColor and gl_FragCoord.xy
    travelSpeed = time * 3.6;
    
    r60 = r2(60.*PI/180.);
    r13 = r2(45.*PI/180.);
    fractTime = fract(time*.15)* (size);
    modTime = mod(time*.3,6.);
    
    float tm = mod(T*.3, 10.);

    float a1 = linearstep(0.0, 1.0, tm);
    float a2 = linearstep(1.0, 2.0, tm);
    float t1 = easeInCubic(a1);
    float t2 = easeOutCubic(a2);

    float a3 = linearstep(5.0, 6.0, tm);
    float a4 = linearstep(6.0, 7.0, tm);
    float t3 = easeInCubic(a3);
    float t4 = easeOutCubic(a4);
    
    float a5 = linearstep(3.0, 4.0, tm);
    float a6 = linearstep(4.0, 5.0, tm);
    float t5 = easeInCubic(a1);
    float t6 = easeOutCubic(a2);

    float a7 = linearstep(6.0, 7.0, tm);
    float a8 = linearstep(7.0, 8.0, tm);
    float t7 = easeInCubic(a3);
    float t8 = easeOutCubic(a4); 
    
    ga1 = t1+t2;
    ga2 = t3+t4;
    ga3 = t5+t6;
    ga4 = t7+t8;
    
    // 
    vec2 U = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);

    vec3 ro = vec3(0,.5,4.5),
         lp = vec3(0,0,0);
             
    // uncomment to look around
    ro = getMouse(ro);
    
    vec3 cf = normalize(lp-ro),
         cp = vec3(0.,1.,0.),
         cr = normalize(cross(cp, cf)),
         cu = normalize(cross(cf, cr)),
         c = ro + cf * .675,
         i = c + U.x * cr + U.y * cu,
         rd = i-ro;

    vec3 C = vec3(0),
        RC = vec3(0),
       RRC = vec3(0);
    vec3 FC= vec3(0.851,0.851,0.851);
  
    ro += vec3(0,(ga1-ga2)*size, 0.);
    
    // trace dat map
    vec2 ray = marcher(ro,rd,256, 1.);
    s_hp=g_hp;
    s_hsh=g_hsh;
    s_bid=g_bid;

    if(ray.x<MAX_DIST) {
        vec3 p = ro+ray.x*rd,
             n = getNormal(p,ray.x);
             
        vec3 lpos = vec3(-25.0, 4.0+((ga3-ga2)*size), ((ga3-ga4)*size)-4.5);
        vec3 ll = normalize(lpos);
        vec3 lp = normalize(lpos-p);
        
        vec3 h = getColor(ray.y,n);
        float shadow = softshadow(p + n * MIN_DIST, lp, .001, 16., 32.);     
        float diff = clamp(dot(n,lp),.01 , 1.);
        vec3 spec = getSpec(p,n,ll,ro);
        float ao = calcAO(p,n);
        
        C = (h * diff * shadow + spec) * ao;
        
        if(ray.y==1.||ray.y==2.){
            vec3 rr=reflect(rd,n); 
            vec2 tr = marcher(p,rr, 226, 1.);
            s_hp=g_hp;
            s_hsh=g_hsh;
            s_bid=g_bid;
            
            if(tr.x<MAX_DIST){
                p += rr*tr.x;
                n = getNormal(p,tr.x); 

                lp = normalize(lpos-p);
                
                h = getColor(tr.y,n);
                shadow = softshadow(p + n * MIN_DIST, lp, .001, 16., 32.);    
                diff = clamp(dot(n,lp),.01 , 1.);
                spec = getSpec(rr,n,ll,ro);
                
                RC = (h *  diff * shadow + spec)*.3;
                
                if(tr.y==1.||tr.y==2.){
                    rr=reflect(rr,n); 
                    tr = marcher(p,rr, 226, 1.);
                    s_hp=g_hp;
                    s_hsh=g_hsh;
                    s_bid=g_bid;
                    
                    if(tr.x<MAX_DIST){
                        p += rr*tr.x;
                        n = getNormal(p,tr.x); 
                        h = getColor(tr.y,n);
                        lp = normalize(lpos-p);
                        diff = clamp(dot(n,lp),.01 , 1.);

                        RRC = (h *  diff)*.9;
                        
                    } 
                    RRC = mix( RRC, FC, 1.-exp(-.00000095*tr.x*tr.x*tr.x));
               }
               
            } 
            RC = mix( RC, FC, 1.-exp(-.00000095*tr.x*tr.x*tr.x));
            
       } 
    } 
    C = mix(C,mix(RC,RRC,.25),.4);
    
    C = mix(C,clamp(C+glow,vec3(0),vec3(1)),glow*.3);
    C = mix( C, FC, 1.-exp(-.00000095*ray.x*ray.x*ray.x));
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
