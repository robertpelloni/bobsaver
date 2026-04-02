#version 420

// original https://www.shadertoy.com/view/3ddfDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Accidental fractal thing - just started to play with it
// and now I have to stop - cause Im going nowhere but tweaking
// numbers and giggling.. I had a bad habit of just playing with my
// shaders - but posting so I'll move to something else. Nothing really
// new in here.. @pjkarlik
//

#define MAX_DIST     25.0
#define MIN_DIST     .0001

#define PI          3.1415926
#define PI2         6.2831853
#define R             resolution
#define T            time
#define M             mouse*resolution.xy

#define r2(a)  mat2(cos(a), sin(a), -sin(a), cos(a))
#define kf(a,b) a*(2.75/b)
#define pfract(a) -1.+2.*fract(.5*a+.5);
#define hash(a, b) fract(sin(a*1.2664745 + b*.9560333 + 3.) * 14958.5453)
#define hue(a) .55 + .45 * cos(PI2 * a + vec3(1.35,.75,.25) * vec3(1.,1.,.75))
#define wmod(a) mod(a+1.5,3.)-1.5;

vec3 getMouse( vec3 ro ) {
    float x = 0.0;// mouse*resolution.xy.xy==vec2(0) ? .0 : (M.y / R.y * .25 - .125) * PI;
    float y = 0.0;// mouse*resolution.xy.xy==vec2(0) ? .0 : -(M.x / R.x * .25 - .125) * PI;
    
    ro.zy *= r2(x);
    ro.zx *= r2(y);
    return ro;
}

//@iq for sdf/extrusion formulas
float opExtrusion(in float sdf, in float pz, in float h){
    vec2 w = vec2( sdf, abs(pz) - h );
      return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}

float sdTorus( vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdBox( in vec2 p, in vec2 b, in vec4 r ){
    r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
    vec2 q = abs(p)-b+r.x;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}

float sdbox(vec3 p, vec3 s) {
      vec3 d = abs(p-vec3(0.)) - s;
      return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sh,tm,tf;
mat2 r90,r5,rT;
const float size = 2.55;
const float aNum = 20.;
const float rdx = .25;

vec2 teeth(vec3 p, float z) {

    p.y+=4.15;
    vec3 w = p;
    w.y+=.95;
    w.y = wmod(w.y);
    
    vec2 res = vec2(100.,-1.);

    float rng = sdTorus(w-vec3(0,1.25,0),vec2(1.1 ,.345));
    if(rng<res.x) res = vec2(rng,3.);

    float c2 = length(p.xz)-1.3654 ;
    float sf = opExtrusion(c2, p.y,  125.);

    if(sf<res.x) res = vec2(sf,2.);
    
    p.xz*=r5;

    float a = atan(p.z, p.x);
    float ia = floor(a/PI2*aNum);
    ia = (ia + .5)/aNum*PI2;
    sh = -mod(ia+z,.0);
    
    p.xz *= r2(ia);
    p.x -= rdx + size;
    p.xz *=r90;
    
    float t = sdBox(p.xy-vec2(0,2.),vec2(.285,.45),vec4(.35,.12,.35,.12));
    float sp = opExtrusion(t, p.z-1., .5);
    if(sp<res.x) res = vec2(sp,1.);

    float tl = sdBox(p.xy-vec2(0,1.),vec2(.285,.45),vec4(.12,.35,.12,.35));
    float sd = opExtrusion(tl, p.z-1., .5);
    if(sd<res.x) res = vec2(sd,1.);

    return res;
}

vec4 orb = vec4(0.0);

vec2 map (in vec3 p) {
    vec2 res = vec2(MAX_DIST,0.);

    vec3 q = p;
    vec3 f = p;
    
     p.y+=1.+tf;
    p.z+=.79;

    float scale = .75;

    for( int i=0; i<2;i++ ) {
        p = pfract(p);
        float r2 = dot(p,p);  
        orb = min( orb, vec4(abs(p),r2) );
        p = kf(p,r2);
        scale = kf(scale,r2);
    }

    vec2 biofract = teeth(p.yzx,floor(orb.z*2.2));
    float d = (biofract.x)/scale;
    float bx = sdbox(f-vec3(0.,1.,0.),vec3(122.55,122. ,1.75));
    d = max(d,bx);
    if(d<res.x ) res =vec2(d,biofract.y);

    return res;
}

//@iq dist base normal - fixes close up
vec3 getNormal(vec3 p, float t){
    float e = .00015 *t;
    vec2 h = vec2(1.,-1.)*.57735027;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}

vec2 marcher( in vec3 ro, in vec3 rd,int maxsteps ) {
    float depth = 0.0;
    float m = -1.;
    for (int i = 0; i<maxsteps;i++){
        vec2 dist = map(ro + depth * rd);
        if(abs(dist.x)<MIN_DIST*depth) break;
        depth += i<64 ?  dist.x * .35 : dist.x*.95;
        if(depth>MAX_DIST) break;
        m = dist.y;
    } 
    return vec2(depth,m);
}

float getDiff(vec3 p, vec3 lpos, float t) {
    vec3 l = normalize(lpos-p);
    vec3 n = getNormal(p, t);
    float dif = clamp(dot(n,l),0. , 1.);
    vec2 shadow = marcher(p + n * MIN_DIST * 2., l, 92);
    if(shadow.x < length(p -  lpos)) dif *= .1;
    return dif;
}

float calAO(vec3 p, vec3 n){ //@Shane
    float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
        float hr = float(i + 1)*.23/8.; 
        float d = map(p + n*hr).x;
        occ += (hr - d)*sca;
        sca *= .9;
        if(sca>1e5) break;
    }
    return clamp(1. - occ, 0., 1.);
}

float ssh;

vec3 getColor(float m, vec3 p, float t) {
    vec3 tint = vec3(.25);  
    if(m == 1.) tint = hue(255.+ssh*15.);
    if(m == 2.) tint = vec3(.05);
    return tint;
}

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv) {
    vec3 color = vec3(0.);
    vec3 fadeColor = vec3(.5);
    vec2 ray = marcher(ro, rd,256);
    float t = ray.x;
    ssh=sh;
    if(ray.x<MAX_DIST) {
        vec3 p = ro + ray.x * rd;
        vec3 n = getNormal(p, ray.x);
        // lighting and shade
        vec3 lpos1 = vec3( -.05, -8.25 , -5.55);
        vec3 lpos2 = vec3(-2.5, -3.5, -6.25);
        vec3 diff = vec3(.9)*getDiff(p, lpos2, ray.x);
             diff+= vec3(.9)*getDiff(p, lpos1, ray.x);
          float ao = calAO(p,n);
        vec3 tint = getColor(ray.y, p, ray.x);
        color += tint * diff * ao;
       
    }
    color = mix( color, fadeColor, 1.-exp(-.0325*t*t*t));
    return color;
}

vec3 camera( in vec3 ro, in vec3 lp, in vec2 uv ) {
    vec3 cf = normalize(lp-ro);
    vec3 cp = vec3(0.,1.,0.);
    vec3 cr = normalize(cross(cp, cf));
    vec3 cu = normalize(cross(cf, cr));
    vec3 c = ro + cf * .85;
    vec3 i = c + uv.x * cr + uv.y * cu;
    return i-ro; 
}

void main(void) {
    //
    tm = T*.1;
    tf = T*.5;
    r90=r2(90.*PI/180.);
    r5 =r2(tf);
    rT =r2(tm);
    //
    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);

    vec3 lp = vec3(-.196, -.3,0.);
    vec3 ro = vec3(-.196,-2.5,-1.95);
    //if(M.z>0.){
    //    ro = getMouse(ro);
    //}else{
        ro.xy*=r2(.15*sin(tm));
    //}
    vec3 rd = camera(ro, lp, uv);

    
    vec3 col = render(ro, rd, uv);
    col= pow(col, vec3(0.4545));
    glFragColor = vec4(col,1.0);
}
 
