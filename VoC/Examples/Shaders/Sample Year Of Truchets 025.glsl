#version 420

// original https://www.shadertoy.com/view/DtK3WK 

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #025
    05/26/2023  @byt3_m3chanic
    Truchet Core \M/->.<-\M/ 2023 

*/

#define R          resolution
#define M          mouse*resolution.xy
#define T          time
#define PI         3.141592653
#define PI2        6.283185307

#define MAX_DIST   50.
#define MIN_DIST   1e-4

// rotation and hash and lerp functions
mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){return fract(sin(dot(p,vec2(23.73,59.71)+date.z))*4832.3234); }
float lsp(float b, float e, float t){return clamp((t-b)/(e-b),0.,1.); }
float eoc(float t){return (t = t-1.)*t*t+1.; }

//@iq sdf's + extrude
float opx(in float d, in float z, in float h){
    vec2 w = vec2( d, abs(z) - h ); return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}
float box(vec2 p,vec2 b){
    vec2 d = abs(p)-b; return length(max(d,0.)) + min(max(d.x,d.y),0.);
}
float box(vec3 p, vec3 b){
  vec3 q = abs(p)-b;return length(max(q,0.)) + min(max(q.x,max(q.y,q.z)),0.);
}

// globals
float tspeed=0.,tmod=0.,ga1=0.,ga2=0.,ga3=0.,ga4=0.,gtk,stk;

// constants
const float sz = 3.5;
const float db = sz*4.;
const float hf = sz/2.;
const float rd = .025;
const float thict = .275;

vec2 map (in vec3 p) {
     vec2 res = vec2(1e5,0);
    p += hf;
    // movement
    p.z  += ga1;
    p.x  += ga2;
    
    // sizing and mixdown
    float thick = .14+.1*sin(p.z*.5+p.y*.75+T*1.75);
    thick -= .1+.05*sin(p.x*1.25+T);
    thick = mix(thict,thick,.5+.5*sin(T*.2));
    gtk=thick;
    
    // id grid
    vec3 q = p, id = floor((q + hf)/sz);
    // 3d checkerd 
    float chk = mod(id.y+mod(id.z+id.x,2.),2.)*2.-1.;
    q = mod(q+hf,sz)-hf;
    
    float hs = hash21(id.xz+id.y);
    float xhs = fract(35.37*hs);

    if (hs>.5) q.y=-q.y;
    if (chk>.5) q.xy=-q.xy;

    vec3 q1,q2,q3;
    float trh,trx,jre;
    //draw
    if(xhs>.75) {
        q1 = q;
        q2 = q + vec3(0,hf,hf);
        q3 = q - vec3(0,hf,hf);
        
        trh = opx(box(q1.xz,vec2(sz,thick)),q1.y,thick)-rd;
        trx = opx(abs(length(q2.yz)-hf)-thick,q.x,thick)-rd;
        jre = opx(abs(length(q3.yz)-hf)-thick,q.x,thick)-rd;
    } else {
        q1 = q + vec3(hf,0,-hf);
        q2 = q + vec3(0,hf,hf);
        q3 = q - vec3(hf,hf,0);
 
        trh = opx(abs(length(q1.xz)-hf)-thick,q.y,thick)-rd;
        trx = opx(abs(length(q2.yz)-hf)-thick,q.x,thick)-rd;
        jre = opx(abs(length(q3.xy)-hf)-thick,q.z,thick)-rd;
    }
    
    if(trh<res.x) res = vec2(trh,2.);
    if(trx<res.x) res = vec2(trx,3.);
    if(jre<res.x) res = vec2(jre,4.);

     return res;
}

// surface normal yo
vec3 normal(vec3 p, float t) {
    t*=MIN_DIST;
    float d = map(p).x;
    vec2 e = vec2(t,0);
    vec3 n = d - vec3(
        map(p-e.xyy).x,
        map(p-e.yxy).x,
        map(p-e.yyx).x
        );
    return normalize(n);
}

//@iq of hsv2rgb
vec3 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.+vec3(0,4,2),6.)-3.)-1., 0., 1.0 );
    return c.z * mix( vec3(1), rgb, c.y);
}

vec4 FC = vec4(.005);
vec4 render(inout vec3 ro, inout vec3 rd, inout vec3 ref, bool last, inout float d, vec2 uv) {

    vec3 C = vec3(0);
    vec3 p = ro;
    float m;
    // ray marcher
    for(int i=0;i<80;i++) {
        p=ro+rd*d;
        vec2 ray = map(p);
        if(ray.x<MIN_DIST*d||d>MAX_DIST)break;
        d+= i<30? ray.x*.35 : ray.x * .9;
        m = ray.y;
    }
    stk=gtk;
    if(d<MAX_DIST) {
        vec3 n = normal(p,d);
        vec3 lpos = vec3(hf,hf,-hf);
        vec3 l = normalize(lpos-p);

        float diff = clamp(dot(n,l),.05,1.);
        float spec = pow(max(dot(reflect(l, n), rd ), .1), 25.)*.75;
        vec3 clr = hsv2rgb(vec3(p.z*.062+stk*1.5+T*.02,.75,.35));
        vec3 h = clr*clamp(diff+spec,0.,1.);
        ref = h*.65;
        C = h;
        
        ro = p+n*MIN_DIST;
        rd = reflect(rd,n);
    } 
    C = mix(FC.rgb,C,exp(-.00055*d*d*d));
    // fog level
    return vec4(C,1.);
}

void main(void) //WARNING - variables void ( out vec4 O, in vec2 F ) need changing to glFragColor and gl_FragCoord.xy
{   
    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0);

    // precal
    tspeed = T*.65;
    tmod = mod(tspeed,12.);
    
    float t1 = lsp(00.,03.,tmod);
    t1 = eoc(t1); t1 = t1*t1*t1;
    
    float t2 = lsp(03.,06.,tmod);
    t2 = eoc(t2); t2 = t2*t2*t2;
    
    float t3 = lsp(06.,9.,tmod);
    t3 = eoc(t3); t3 = t3*t3*t3;
    
    float t4 = lsp(9.,12.,tmod);
    t4 = eoc(t4); t4 = t4*t4*t4;
    
    ga1 = (t1*db)-(t3*db);
    ga2 = (t2*db)-(t4*db);
    
    ga3 = (t1-t3)*PI;
    ga4 = (t2-t4)*PI;

    // screen uv
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    uv*=rot(ga3+ga4);
    
    // ray order+direction
    vec3 ro = vec3(0,0,.1);
    vec3 rd = normalize(vec3(uv,-1));

    // mouse //
    float x = 0.;
    float y = 0.;

    mat2 rx = rot(x+ga3), ry = rot(y-ga4);
    ro.zy *= rx; ro.xz *= ry; 
    rd.zy *= rx; rd.xz *= ry;
    
    // reflection loop (@BigWings)
    vec3 C=vec3(0), ref=vec3(0), fil=vec3(1);
    float d=0.;

    for(float i=0.; i<2.; i++) {
        vec4 pass = render(ro, rd, ref, i==2.-1., d, uv);
        C += pass.rgb*fil;
        fil*=ref;
        // first bounce - get fog layer
        if(i==0.) FC = vec4(FC.rgb,exp(-.00055*d*d*d));
    }

    //layer fog in   
    C = mix(C,FC.rgb,1.-FC.w);
    C=pow(C, vec3(.4545));
    O = vec4(C,1);
    
    glFragColor=O;
}
