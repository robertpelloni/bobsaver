#version 420

// original https://www.shadertoy.com/view/wl3yDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Playing with some abstract forms and shapes
    Standard truchet patten in 3d (grid) and
    then warped 
    nothing too exciting @pjkarlik
*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy
#define S           smoothstep
#define PI          3.1415926535
#define PI2         6.2831853070

#define MAX_DIST    50.
#define MIN_DIST    .001
#define SCALE .7

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define hue(a) .45 + .45 * cos(PI2* a * vec3(.25,.15,1.));

float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.608, 57.584)))*43758.51453); }

void getMouse( inout vec3 p ) {
    float x = 0.0; //M.xy == vec2(0) ? 0. : -(M.y/R.y * .25 - .125) * PI;
    float y = 0.0; //M.xy == vec2(0) ? 0. :  (M.x/R.x * .25 - .125) * PI;
    p.zy *=r2(x);
    p.xz *=r2(y);   
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

const float size = 1./SCALE;
const float hlf = size/2.;
const float shorten = 1.26;   
    
vec2 map(vec3 q3){
    vec2 res = vec2(100.,0.);

    float k = 5.0/dot(q3,q3); 
    q3 *= k;

    q3.z += T*.225;
    
    float d = 1e5, t = 1e5, f = 1e5, g = 1e5;
  
    vec3 qid=floor((q3+hlf)/size);
    vec3 qm = mod(q3+hlf,size)-hlf;
    
    q3+=hlf;
    
    vec3 did=floor((q3+hlf)/size);
    vec3 qd = mod(q3+hlf,size)-hlf;
    
    float ht = hash21(qid.xy+qid.z);
    float hy = hash21(did.xz);
    
    // truchet build parts
    float thx = (.075+.025*sin((q3.y+qid.z)*3.15) ) *size;
    float thz = (.075+.025*sin(T*4.+(q3.y+did.x)*3.45) ) *size;

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
    
    float gi = min(
      sdTorus(qm.xzy-vec3(.0,0,hlf),vec2(.2,.025),0.),
      sdTorus(qm.xzy-vec3(.0,0,-hlf),vec2(.2,.025),0.)
    );

    if(gi<g) {
        g = gi;
        sip = qid;
        shp = qm;
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

    float fi = min(
      sdTorus(qd.xzy-vec3(.0,0,hlf),vec2(.2,.025),0.),
      sdTorus(qd.xzy-vec3(.0,0,-hlf),vec2(.2,.025),0.)
    );

    if(fi<f) {
        f = fi;
        sip = did;
        shp = qd;
    }
    if(d<res.x) res = vec2(d,1.);
    if(t<res.x) res = vec2(t,2.);
    if(f<res.x) res = vec2(f,3.);
    if(g<res.x) res = vec2(g,3.);
    float mul = 1.0/k;
    res.x = res.x * mul / shorten;
    
    return res;
}

vec2 marcher(vec3 ro, vec3 rd, int maxsteps) {
    float d = 0.;
    float m = -1.;
    for(int i=0;i<maxsteps;i++){
        vec2 t = map(ro + rd * d);
        if(t.x<d*MIN_DIST||d>MAX_DIST) break;
        d += i < 32 ? t.x*.35 : t.x*.85;
        m  = t.y;
    }
    return vec2(d,m);
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF
vec3 getNormal(vec3 p, float t){
    float e = MIN_DIST *t;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}

// softshadow www.pouet.net
// http://www.pouet.net/topic.php?which=7931
float softshadow( vec3 ro, vec3 rd, float mint, float maxt, float k ){
    float res = 1.0;
    for( float t=mint; t < maxt; ){
        float h = map(ro + rd*t).x;
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

float circle(vec2 pt, float r, vec2 center, float lw) {
    float len = length(pt - center);
    float hlw = lw / 2.;
    float edge = .005;
    return S(r-hlw-edge,r-hlw, len)-S(r+hlw,r+hlw+edge, len);
}

vec3 getColor(float m, vec3 p, vec3 n) {
    vec3 h = vec3(.5); 
    
    if(m==1.) {
        float hs = hash21(vec2(tip.x+12.75));
        float xt = floor(1.+(3.23*hs))*2.;
        xt +=3.;
        // strip patterns..
        thp/=1./SCALE;
        float dir = mod(tip.z + tip.y,2.) * 2. - 1.;  

        vec2 cUv = thp.xy-sign(thp.x+thp.y+.001)*.5;
        float angle = atan(cUv.x, cUv.y);
        float a = sin( dir * angle * xt + T * 1.25);
        a = abs(a)-.5;a = abs(a)-.24;
        vec3 nz = hue((p.x+(T*.633))*.075);
        h = mix(nz, vec3(0), smoothstep(.01, .02, a));   
    }
    
    if(m==2.) {    
        float hs = hash21(vec2(fid.z-12.75));
        float xt = floor(2.-(3.73*hs))*2.;
        xt +=7.;
        
        ghp/=1./SCALE;
        
        /** 
        // strip patterns..
        float dir = mod(fid.x + fid.y,2.) * 2. - 1.;  

        vec2 cUv = ghp.xy-sign(ghp.x+ghp.y+.001)*.5;
        float angle = atan(cUv.x, cUv.y);
        float a = sin( dir * angle * xt + T * 1.15);
        
        a = abs(a)-.5; a = abs(a)-.25; a = abs(a)-.15;
        vec3 nz = hue((p.x+(2.+T*.83))*.065);
        h = mix(nz, vec3(0), smoothstep(.01, .02, a)); 
         */
        
        //TRUCHET PATTERN
        ghp.xy *= 20.;
        vec3 nz = hue((p.x+(2.+T*.83))*.065);
        vec2 id = floor(ghp.xy);
        vec2 rg = fract(ghp.xy)-.5;
        if(hash21(id) <.5) rg.x *= -1.;
        vec2 dUv = rg.xy-sign(rg.x+rg.y+.001)*.5;
        float d = length(dUv);
        float pix = 1.312;
        float mask = smoothstep(pix, -pix, abs(d-.5)-.15);
 
        h *= S(.5,.53,mask);
       
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
    vec3 FC = vec3(.05);
    vec3 lp = vec3(0.,0.,0.),
         ro = vec3(.0,0.,3.70);
         getMouse(ro);

    vec3 rd = camera(lp,ro,uv);
    vec2 t = marcher(ro,rd, 192);
    // save all globals
    thp = shp;
    ghp = fhp;
    tip = sip;
    fid = bip;
    if(t.x<MAX_DIST){
        vec3 p = ro + rd * t.x;
        vec3 n = getNormal(p,t.x);
        vec3 lpos = vec3(.0,.001,3.85);
        vec3 lp = normalize(lpos-p);
        vec3 ll = normalize(lpos);
        float shadow = softshadow(p + n * MIN_DIST, lp, .1, 32., 32.);     
        float diff = clamp(dot(n,lp),.0, 1.);
        vec3 spec = getSpec(p,n,ll,ro);
        vec3 h = getColor(t.y, p, n);

        C += (h * diff * shadow + spec);

        // reflection
        // if material && hue black 
        if(h.x<.001 &&h.y<.001 &&h.z<.001 || t.y == 3.){
            vec3 rr=reflect(rd,n); 
            vec2 tr = marcher(p ,rr, 128);
            thp = shp;
            ghp = fhp;
            tip = sip;
            fid = bip;
            if(tr.x<MAX_DIST){
                p += rr*tr.x;
                n = getNormal(p,tr.x);
                lp = normalize(lpos-p);
                diff = diff = clamp(dot(n,lp),.01 , 1.);
                h = getColor(tr.y, p, n);
                tC = (h * diff * shadow);
                tC = mix( tC, FC, 1.-exp(-.03*tr.x*tr.x*tr.x));
            }
        } 
        
    } 
    C+= (tC*.45);//fade back reflections.. so bright..
    C = mix( C, FC, 1.-exp(-.04*t.x*t.x*t.x));
    // Output to screen
    glFragColor = vec4(C,1.0);
}
