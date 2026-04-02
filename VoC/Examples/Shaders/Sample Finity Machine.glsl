#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tttyRS

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// @pjkarlik finity machine 2021
// a much better version of one of my
// first shaders here
// https://www.shadertoy.com/view/3ddSzH
#define R            resolution
#define T            time
#define M            mouse*resolution.xy
#define S           smoothstep

#define PI            3.141592653589793
#define PI2            6.283185307

#define MAX_DIST    135.
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
    float x = 0.0; //M.xy==vec2(0) ? -.01 : -(M.y / R.y * 1. - .5) * PI;
    float y = 0.0; //M.xy==vec2(0) ?  .01 :  (M.x / R.x * 1. - .5) * PI;
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
float pMod1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

//@iq SDF functions
float sdCyl( vec3 p, float h, float r ){
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
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
vec3 g_hp,s_hp;
float travelSpeed,modTime,fractTime,glow =0.;
mat2 r60,r13;
    
const float size = 20.;
const float rep_half = size/2.;
const float rr = rep_half/4.75;
vec2 s1 = vec2(4.5,2.5);
vec2 s2 = vec2(11.,.25);

vec2 map(vec3 pos, float sg) {

    vec2 res = vec2(100.,0);
    vec3 center = vec3(travelSpeed,0, -rr/2.);
    vec3 pp = pos-center;
    vec3 tt = pos-center;
    vec3 sp = pp;

    vec3 pi = vec3(
        floor((pp + rep_half)/size)
    );
    vec3 ti = pi;

    float bfs,fhs,dhs;
    if(modTime<2.){
        fhs = hash21(pi.xz);
        if(fhs>.57){
            tt.y += fractTime;
        } else {
            tt.y -= fractTime;
        } 
    } else if (modTime<4.){
          dhs = hash21(pi.zy+vec2(0,.4));
        if(dhs>.67){
            tt.x += fractTime;
        } else {
            tt.x -= fractTime;
        }
    } else {
          bfs = hash21(pi.xy+vec2(0,.4));
        if(bfs>.27){
            tt.z -= fractTime;
        } else {
            tt.z += fractTime;
        }   
    }

    pp =  mod(pp+rep_half,size) - rep_half;
    tt =  mod(tt+rep_half,size) - rep_half;
    
    float deg = 39.752;
    if(fhs>.5 ){
        tt.yz*=r2(fractTime*PI/deg);
    } else {
        tt.yz*=r2(-fractTime*PI/deg);
    }
    
    if(dhs>.5 ){
        tt.xy*=r2(fractTime*PI/deg);
    } else {
        tt.xy*=r2(-fractTime*PI/deg);
    }

    if(bfs>.5){
        tt.zx*=r2(fractTime*PI/deg);
    } else {
        tt.zx*=r2(-fractTime*PI/deg);
    }

    //framework
  
    float d1 = fBox(abs(pp)-vec3(10.,10.,0.), s2.yyx, .0 );
    d1 = min(fBox(abs(pp)-vec3(10.,0.,10.), s2.yxy, .0 ),d1);
    d1 = min(fBox(abs(pp)-vec3(0.,10.,10.), s2.xyy, .0 ),d1);
    //  it's really better without this part.
    if(d1<res.x) {
        res = vec2(d1,4.);
        g_hp = pp;
    }
 
      
    //box clips
    float d2 = fBox(abs(pp)-vec3(10.,10.,10.), vec3(3.5) , .015);
    if(d2<res.x) {
        res = vec2(d2,2.);
        g_hp = sp.yzx;
    }

    float d3=fBox(abs(pp)-vec3(10.,10.,10.), s1.xyy , .015);
    d3 = min(fBox(abs(pp)-vec3(10.,10.,10.), s1.yxy , .015),d3);
    d3 = min(fBox(abs(pp)-vec3(10.,10.,10.), s1.yyx , .015),d3);
    if(d3<res.x) {
        res = vec2(d3,6.);
        g_hp = sp;
    }

    //balls
    float d4 = length(tt)-1.95;
    vec3 vt=abs(tt);
    d4 = max(fBox(tt,vec3(1.45),.015),-d4);
    float d6 = max(length(vt-vec3(1.45))-.35,-d4);
    if(d6<res.x) {
        res = vec2(d6,5.);
        g_hp = vt;
    }
    if(d4<res.x) {
        res = vec2(d4,3.);
        g_hp = tt;
    }
    float d5 = length(tt)-1.35;
    if(d5<res.x) {
        res = vec2(d5,0.);
        g_hp = tt;
    }
    
    // pipes
    pp.x=abs(pp.x);
    float d9 = sdCap(abs(pp  )-vec3(8.5,0.,8.5), 7.5,.25);
    d9 = min(sdCap(abs(pp.zxy)-vec3(8.5,0.,8.5), 7.5,.25),d9);
    d9 = min(sdCap(abs(pp.yzx)-vec3(8.5,0.,8.5), 7.5,.25),d9);
    if(d9<res.x) {
        res = vec2(d9,3.);
        g_hp = pp;
    }
   //sg prevents glow from changing for normal
    if(sg>0.){
        glow += .0025/(.00025+d5*d5);
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
    float fc = .375,nd = .15;
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

vec3 getStripes(vec2 uv){
    uv.y -= sin(radians(25.)) * uv.x;
    float sd = mod(floor(uv.y * 1.95), 2.);
    vec3 background = (sd<1.) ? vec3(1.) : vec3(0.);
    return background;
}

vec3 getColor(float m, in vec3 n) {
    vec3 h = vec3(0.45);
    if(m==1.) h = vec3(0.659,0.855,0.922);
    if(m==2.) h = vec3(0.337,0.561,0.220) * getStripes(s_hp.xz+s_hp.xy);
    if(m==3.) h = vec3(1.000,0.533,0.000) * getWood(s_hp.zyx).rgb; 
    if(m==4.) h = vec3(0.651,1.000,0.000);
    if(m==5.) h = vec3(0.243,0.592,0.008); 
    if(m==6.) h = vec3(0.922,0.769,0.000) * getWood(s_hp).rgb; 
    return h;
}

void main(void) { //WARNING - variables void ( out vec4 O, in vec2 F ) { need changing to glFragColor and gl_FragCoord.xy
    travelSpeed = time * 4.15;
    r60 = r2(60.*PI/180.);
    r13 = r2(45.*PI/180.);
    mat2 r15 = r2(-25.*PI/180.);
    fractTime = fract(time*.3)* (size);
    modTime = mod(time*.6,6.);
    
    vec2 U = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);

    vec3 ro = vec3(0.,-1.85,4.5),
         lp = vec3(0,0,0);

    //if (M.z>0. ){
    //    ro = getMouse(ro);
    //} else {
        ro.zx*=r2(55.*PI/180.);
        ro.zy*=r2(2.*PI/180.);
    //}
    
    vec3 cf = normalize(lp-ro),
         cp = vec3(0.,1.,0.),
         cr = normalize(cross(cp, cf)),
         cu = normalize(cross(cf, cr)),
         c = ro + cf * .75,
         i = c + U.x * cr + U.y * cu,
         rd = i-ro;

    vec3 C = vec3(0),
        RC = vec3(0),
       RRC = vec3(0);
    vec3 FC= vec3(1.000,0.898,0.722);
    // trace dat map
    vec2 ray = marcher(ro,rd,256, 1.);
    s_hp=g_hp;

    if(ray.x<MAX_DIST) {
        vec3 p = ro+ray.x*rd,
             n = getNormal(p,ray.x);
             
        vec3 lpos = vec3(4.0, 15.0, 4.5);
        vec3 ll = normalize(lpos);
        vec3 lp = normalize(lpos-p);
        
        vec3 h = getColor(ray.y,n);
        float shadow = softshadow(p + n * MIN_DIST, lp, .1, 16., 32.);     
        float diff = clamp(dot(n,lp),.01 , 1.);
        vec3 spec = getSpec(p,n,ll,ro);
        float ao = calcAO(p,n);
        
        C = (h * diff * shadow + spec) * ao;
        
        if(ray.y==1.||ray.y==4.||ray.y==2. && h.x>.001&& h.x>.001&&h.x>.001 ){
            vec3 rr=reflect(rd,n); 
            vec2 tr = marcher(p,rr, 192, 1.);
            s_hp=g_hp;
            
            if(tr.x<MAX_DIST){
                p += rr*tr.x;
                n = getNormal(p,tr.x); 

                lp = normalize(lpos-p);
                
                h = getColor(tr.y,n);
                shadow = softshadow(p + n * MIN_DIST, lp, .1, 16., 32.);    
                diff = clamp(dot(n,lp),.01 , 1.);
                spec = getSpec(rr,n,ll,ro);
                
                RC = (h *  diff * shadow + spec)*.3;
                
                // if you want to get technical and have double reflections you 
                // can - however after building, the reduction in surfaces that
                // you can actually see is almost less than 1% so to save render
                // speed its commented out. 
                
                /**
                if(tr.y==1.||tr.y==4.||tr.y==2. && h.x>.001&& h.x>.001&&h.x>.001){
                    rr=reflect(rr,n); 
                    tr = marcher(p,rr, 192, 1.);
                    s_hp=g_hp;
                    
                    if(tr.x<MAX_DIST){
                        p += rr*tr.x;
                        n = getNormal(p,tr.x); 
                        h = getColor(tr.y,n);
                        lp = normalize(lpos-p);
                        diff = clamp(dot(n,lp),.01 , 1.);

                        RRC = (h *  diff)*.9;
                        
                    } 
                    //reflection mixdown 2
                    RRC = mix( RRC, FC, 1.-exp(-.0000025*tr.x*tr.x*tr.x));
               }*/
               
            } 
            
            //reflection mixdown 1
            RC = mix( RC, FC, 1.-exp(-.0000025*tr.x*tr.x*tr.x));  
       } 
    } 
    // unsure how to do reflections? or do them well? 
    // mixdown to prevent colors over 1.0
    //C = mix(C,mix(RC,RRC,.25),.4);
    C = mix(C,RC,.4);
    // add back glow
    C = clamp( C+(glow*.3),.01,1.);
    C = mix( C, FC, 1.-exp(-.0000025*ray.x*ray.x*ray.x));
    glFragColor = vec4(pow(C, vec3(0.4545)),1.);
}
