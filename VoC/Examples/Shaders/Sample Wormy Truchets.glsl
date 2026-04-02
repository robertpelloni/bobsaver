#version 420

// original https://www.shadertoy.com/view/3sVyRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Interwoven "Worm" Truchet | @pjkarlik
*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy
#define PI          3.1415926535
#define PI2         6.2831853070

#define MAX_DIST    50.
#define MIN_DIST    .0001
#define SCALE 1.5

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define hue(a) .45 + .45 * cos(PI2* a * vec3(.25,.15,1.));

float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.608, 57.584)))*43758.51453); }

void getMouse( inout vec3 p ) {
    float x = 0.0; //M.xy == vec2(0) ? 0. : -(M.y/R.y * 1. - .5) * PI;
    float y = 0.0; //M.xy == vec2(0) ? 0. :  (M.x/R.x * 1. - .5) * PI;
    p.zy *=r2(x);
    p.xz *=r2(y);   
}

//http://mercury.sexy/hg_sdf/
float vmax(vec3 v) {    return max(max(v.x, v.y), v.z);     }
float fBox(vec3 p, vec3 b, float r) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)))-r;
}
//@iq
mat2 trs;
float sdTorus( vec3 p, vec2 t, float a ) {
  if(a>0.){
      p.xy *= trs;
      p.yz *= trs;
  }
  vec2 q = vec2(length(p.xy)-t.x,p.z);
  return length(q)-t.y;
}

vec3 shp,fhp;
vec3 sip,bip;
float thsh,fhsh;
mat2 t90;

vec2 map(vec3 q3){
    vec2 res = vec2(1000.,0.);
    const float size = 1./SCALE;
    float hlf = size/2.;
    q3.yz+=vec2(1.45,-.66);
    q3.x -= T*.28;
    
    float d = 1e5, t = 1e5;
  
    vec3 qid=floor((q3+hlf)/size);
    vec3 qm = mod(q3+hlf,size)-hlf;
    
    q3+=hlf;
    
    vec3 did=floor((q3+hlf)/size);
    vec3 qd = mod(q3+hlf,size)-hlf;
    
    float ht = hash21(qid.xy+qid.z);
    float hy = hash21(did.xz);
    
    // truchet build parts
    float thx = (.085+.045*sin((q3.y+qid.z)*2.95) ) *size;
    float thz = (.085+.035*sin((q3.y+did.x)*2.15) ) *size;

    if(ht>.5) qm.x *= -1.;
    if(hy>.5) qd.z *= -1.;
    
    float ti = min(
      sdTorus(qm-vec3(hlf,hlf,.0),vec2(hlf,thx),0.),
      sdTorus(qm-vec3(-hlf,-hlf,.0),vec2(hlf,thx),0.)
    );

    // truchet
    if(ti<t) {
        t = ti;
        bip = qid;
        fhp = qm;
    }
    
    qd.xz*=t90;
    float di = min(
      sdTorus(qd-vec3(hlf,hlf,.0),vec2(hlf,thz),0.),
      sdTorus(qd-vec3(-hlf,-hlf,.0),vec2(hlf,thz),0.)
    );
    
   // truchet
    if(di<d) {
        d = di;
        sip = did;
        shp = qd;
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
    float dif = clamp(dot(n,l),.1 , 1.);
    float shadow = marcher(p + n * .01, l, 92).x;
    if(shadow < length(p -  lpos)) dif *= .4;
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
vec3 tip,fid;

vec3 getColor(float m, vec3 p, vec3 n) {
    vec3 h = vec3(.5);      
    if(m==1.) {
        float hs = hash21(vec2(tip.x+1.75));
        float xt = floor(1.+(3.23*hs))*2.;
        
        // strip patterns..
        thp/=1./SCALE;
        float dir = mod(tip.z + tip.y,2.) * 2. - 1.;  

        vec2 cUv = thp.xy-sign(thp.x+thp.y+.001)*.5;
        float angle = atan(cUv.x, cUv.y);
        float a = sin( dir * angle * xt + T * 1.95);
        a = abs(a)-.5;a = abs(a)-.4;
        vec3 nz = hue((p.x+(T*.633))*.075);
        h = mix(nz, vec3(1), smoothstep(.01, .02, a));   
    }
    if(m==2.) {    
        float hs = hash21(vec2(fid.z+2.75));
        float xt = floor(2.-(3.73*hs))*2.;
        
        // strip patterns..
        ghp/=1./SCALE;
        float dir = mod(fid.x + fid.y,2.) * 2. - 1.;  

        vec2 cUv = ghp.xy-sign(ghp.x+ghp.y+.001)*.5;
        float angle = atan(cUv.x, cUv.y);
        float a = sin( dir * angle * xt + T * 1.75);
        a = abs(a)-.5; a = abs(a)-.35; a = abs(a)-.15;
        vec3 nz = hue((p.x+(100.+T*.83))*.065);
        h = mix(nz, vec3(1), smoothstep(.01, .02, a));  
    }
    
    return h;
}

void main(void) {
    // precal
    trs = r2(PI*4.5);
    t90 = r2(90.*PI/180.);
    // Normalized coordinates (from -1 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/max(resolution.x,resolution.y);
    vec3 C = vec3(0.);
    vec3 tC= vec3(0.);
    vec3 FC = vec3(.45);
    vec3 lp = vec3(0.,0.,0.),
         ro = vec3(.082,0.,.15);
         getMouse(ro);

    vec3 rd = camera(lp,ro,uv);
    vec2 t = marcher(ro,rd, 128);
    // save all globals
    thp = shp;
    ghp = fhp;
    tip = sip;
    fid = bip;
    if(t.x<MAX_DIST){
        vec3 p = ro + rd * t.x;
        vec3 n = getNormal(p,t.x);
        vec3 lpos = vec3(0.,.5,-.25);
        float diff = getDiff(p,n,lpos);
        vec3 h = getColor(t.y, p, n);
        
        C+=diff * h;

        // reflection
        // if material && hue not black 
        if(h.x<.9999 &&h.y<.9999 &&h.z<.9999){
            vec3 rr=reflect(rd,n); 
            vec2 tr = marcher(p ,rr, 98);
            thp = shp;
            ghp = fhp;
            tip = sip;
            fid = bip;
            if(tr.x<MAX_DIST){
                p += rr*tr.x;
                n = getNormal(p,tr.x);
                diff = getDiff(p,n,lpos);
                h = getColor(tr.y, p, n);
                tC = diff * h;
                tC = mix( tC, FC, 1.-exp(-.08*tr.x*tr.x*tr.x));
            }
        } 
        
    } 
    C+= (tC*.35);//fade back reflections.. so bright..
    C = mix( C, FC, 1.-exp(-.08*t.x*t.x*t.x));
    // Output to screen
    glFragColor = vec4(C,1.0);
}
