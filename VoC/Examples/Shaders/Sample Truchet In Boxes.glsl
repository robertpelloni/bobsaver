#version 420

// original https://www.shadertoy.com/view/3sycWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Single Pass Truchet Pattern | @pjkarlik

    Mostly playing around still with
    tiled grids and doing patterns. 

    Took me a bit to match up the 3D
    version to follow the things I've
    done in 2D.. 

*/

#define R            resolution
#define T            time
#define M            mouse*resolution.xy
#define PI            3.1415926535
#define PI2            6.2831853070

#define MAX_DIST     50.
#define MIN_DIST    .0001
#define SCALE 1.15

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define hue(a) .65 + .45 * cos(PI2* a * vec3(.15,.75,1.));

float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

void getMouse( inout vec3 p ) {
    float x = 0.0; //M.xy == vec2(0) ? 0. : -(M.y/R.y * .125 - .06) * PI;
    float y = 0.0; //M.xy == vec2(0) ? 0. : (M.x/R.x * .125 - .06) * PI;
    p.zy *=r2(x);
    p.xz *=r2(y);   
}

//http://mercury.sexy/hg_sdf/
float vmax(vec3 v) {    return max(max(v.x, v.y), v.z);        }
float fBox(vec3 p, vec3 b, float r) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)))-r;
}
//@iq
mat2 trs;// - with added precal
float sdTorus( vec3 p, vec2 t, float a ) {
  if(a>0.){p.xy *= trs;p.yz *= trs;}
  vec2 q = vec2(length(p.xy)-t.x,p.z);
  return length(q)-t.y;
}

vec3 shp,fhp;
vec2 sip,bid;
float thsh;

vec2 map(vec3 q3){
    vec2 res = vec2(1000.,0.);
    const float size = 1./SCALE;
    float hlf = size/2.;
    q3.y += T*.25;

    float d = 1e5, t = 1e5;
  
    vec2 qid=floor((q3.xy+hlf)/size);
    vec3 qm = vec3(
        mod(q3.x+hlf,size)-hlf,
        mod(q3.y+hlf,size)-hlf,
        q3.z
          );

    float ht = hash21(qid); 
    vec3 bm = qm;
    // build box parts
    float f = length(bm)-(hlf*1.2);
    float b = fBox(bm,vec3(hlf)*1.05,.0);
    float c = fBox(bm,vec3(hlf)*.85,.02);
    float di = ht > .6 ? max(c,-b) : max(c,-f);

    // box
    if(di<d) {
        d = di;
        sip = qid;
        fhp = bm;
        thsh = ht;
    }

    // truchet build parts
    float thx = (.14+.09*sin(T*1.5-q3.y*1.2) ) *size;
    if(ht>.5) qm.x *= -1.;

    float ti = min(
      sdTorus(qm-vec3(hlf,hlf,0),vec2(hlf,thx),0.),
      sdTorus(qm-vec3(-hlf,-hlf,0),vec2(hlf,thx),0.)
    );

    // truchet
    if(ti<t) {
        // things to set for
        // global lazy pass
        t = ti;
        sip = qid;
        shp = qm;
        thsh = ht;
    }

    if(d<res.x) res = vec2(d,1.);
      if(t<res.x) res = vec2(t,2.);
    return res;
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF
vec3 getNormal(vec3 p, float t){
    float e = .0002 *t;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}

vec2 marcher(vec3 ro, vec3 rd, int maxsteps) {
    float d = 0.;
    float m = -1.;
    for(int i=0;i<maxsteps;i++){
        vec2 t = map(ro + rd * d);
        if(abs(t.x)<d*MIN_DIST||d>MAX_DIST) break;
        d += t.x*.75;
        m  = t.y;
    }
    return vec2(d,m);
}

float getDiff(vec3 p, vec3 n, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    float dif = clamp(dot(n,l),.01 , 1.);
    float shadow = marcher(p + n * .01, l, 84).x;
    if(shadow < length(p -  lpos)) dif *= .25;
    return dif;
}

vec3 camera(vec3 lp, vec3 ro, vec2 uv) {
    vec3 cf = normalize(lp - ro),
         cr = normalize(cross(vec3(0,1,0),cf)),
         cu = normalize(cross(cf,cr)),
         c  = ro + cf *.85,
         i  = c + uv.x * cr + uv.y * cu,
         rd = i - ro;
    return rd;
}

vec3 thp,ghp;
vec2 tip,fid;
float hsh;

vec3 getColor(float m, vec3 p, vec3 n) {
      vec3 h = vec3(.5);      
    if(m==1.) {
        h = vec3(1.)*hue(hash21(tip));
    }
    if(m==2.) {    
        // strip patterns..
        float scale = 1./SCALE;
        thp/=scale;
        float dir = mod(tip.x + tip.y,2.) * 2. - 1.;  

        vec2 cUv = thp.xy-sign(thp.x+thp.y+.001)*.5;
        float angle = atan(cUv.x, cUv.y);
        float a = sin( dir * angle * 5. + time * 2.25);
        a = abs(a)-.5;a = abs(a)-.3;
        vec3 nh = hue((p.y*.2)*PI);
        h = nh * (smoothstep(.01, .05, a));  
    }
    
    return h;
}

void main(void) {
    // precal
    trs = r2(PI*4.5);
    // Normalized coordinates (from -1 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/max(resolution.x,resolution.y);
    vec3 C = vec3(0.);
    vec3 FC = vec3(.2,.1,.15);
    vec3 lp = vec3(0.,0.,0.),
         ro = vec3(.2,.2,2.75);
         getMouse(ro);

    vec3 rd = camera(lp,ro,uv);
    vec2 t = marcher(ro,rd, 256);
    // save all globals
    thp = shp;
    ghp = fhp;
    tip = sip;
    hsh = thsh;
    if(t.x<MAX_DIST){
        vec3 p = ro + rd * t.x;
        vec3 n = getNormal(p, t.x);
        vec3 lpos = vec3(0.,0.,2.25);
        float diff = getDiff(p, n, lpos);
          vec3 h = getColor(t.y, p, n);
        
        C+=diff * h;
        
        // reflection
        // if material && hue not black 
        if(t.y==2. && h.x>.01 &&h.y>.01){
            vec3 rr=reflect(rd,n); 
            vec2 tr = marcher(p ,rr, 128);
            thp = shp;
            ghp = fhp;
            tip = sip;
            hsh = thsh;
            if(tr.x<MAX_DIST){
                p += rr*tr.x;
                n = getNormal(p,tr.x);
                diff = getDiff(p,n,lpos);
                h = getColor(tr.y, p, n);
                C+=diff * h;
            } 
        } 
        
    } 
    C = mix( C, FC, 1.-exp(-.0015*t.x*t.x*t.x));
    // Output to screen
    glFragColor = vec4(C,1.0);
}
