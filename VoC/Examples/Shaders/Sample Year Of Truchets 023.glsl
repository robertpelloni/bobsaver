#version 420

// original https://www.shadertoy.com/view/dlG3WK

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #023
    05/23/2023  @byt3_m3chanic
    Truchet Core \M/->.<-\M/ 2023 
    
    Unstyled, unbothered, moisturized, happy, in my lane, flourishing.

    https://soundcloud.com/monster-magnet-433718279/premiere-cypherpunx-feat-sian
*/

#define R          resolution
#define M          mouse*resolution.xy
#define T          time
#define PI         3.141592653
#define PI2        6.283185307

#define MAX_DIST   60.
#define MIN_DIST   1e-4

mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}
float hash21(vec2 p){return fract(sin(dot(p,vec2(23.73,59.71)+date.z))*4832.3234);}

//@iq sdf's + extrude
float opx(in float d, in float z, in float h){
    vec2 w = vec2( d, abs(z) - h );
      return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}
float box(vec2 p,vec2 b){
    vec2 d = abs(p)-b;
    return length(max(d,0.)) + min(max(d.x,d.y),0.);
}

//@Shane - path function
vec2 path(in float z){
    vec2 p1 =vec2(7.38*sin(z *.15)+5.38*cos(z *.075),2.4*cos(z *.0945));
    vec2 p2 =vec2(5.2*sin(z *.089),2.31*sin(z *.127)+3.5*cos(z *.095));
    return (p1 - p2)*.3;
}

mat2 r90;
float tspeed = 0.;

vec3 lp = vec3(0);
const float sz = 2.65;
const float hf = sz/2.;
const float rd = .025;

vec2 map (in vec3 p) {
     vec2 res = vec2(1e5,0);
    p.xy += hf;

     vec2 tun = p.xy - path(p.z);
    vec3 q = vec3(tun,p.z),
        id = floor((q + hf)/sz);

    float thick  = .0825+.0625*sin(p.z*.75);
          thick -= .0125*cos(p.y*.62)+.0125*sin(p.x*1.25);
    
    float chk = mod(id.y+mod(id.z+id.x,2.),2.)*2.-1.;
    q = mod(q+hf,sz)-hf;
    
    float hs = hash21(id.xz+id.y);
    float xhs = fract(2.33*hs+id.y);

    if (hs >.5) q.xz *= r90;
    if (chk>.5) q.zy *= r90;

    vec3 q1,q2,q3;
    float trh,trx,jre;

    if(xhs>.65) {
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
    
    if(trh<res.x ) res = vec2(trh,2.);
    if(trx<res.x ) res = vec2(trx,3.);
    if(jre<res.x ) res = vec2(jre,4.);

     return res;
}

// Tetrahedron technique @iq
// https://iquilezles.org/articles/normalsSDF
vec3 normal(vec3 p, float t) {
    float e = MIN_DIST*t;
    vec2 h =vec2(1,-1)*1.5773;
    vec3 n = h.xyy * map(p+h.xyy*e).x+
             h.yyx * map(p+h.yyx*e).x+
             h.yxy * map(p+h.yxy*e).x+
             h.xxx * map(p+h.xxx*e).x;
    return normalize(n);
}

//@iq of hsv2rgb
vec3 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.+vec3(0,4,2),6.)-3.)-1., 0., 1.0 );
    return c.z * mix( vec3(1), rgb, c.y);
}

void main(void) //WARNING - variables void ( out vec4 O, in vec2 F ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0);
    
    // precal
    tspeed = time*1.25;
    r90=rot(1.5707);

    vec3 C =vec3(0);
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);

    vec3 ro = vec3(0,0,.1);
    vec3 rd = normalize(vec3(uv,-1.));

    // mouse //
    float x = (T*.0095)*PI2;
    float y = (T*-.0125)*PI2;

    mat2 rx = rot(x), ry = rot(y);
    ro.zy *= rx; ro.xz *= ry; 
    rd.zy *= rx; rd.xz *= ry;

    ro.z -= tspeed;
    ro.xy += path(ro.z);

    float d,m;
    vec3 p = vec3(0);

    for(int i=0;i<98;i++) {
        p = ro+rd*d;
        vec2 ray = map(p);
        d += i<32? ray.x*.35 : ray.x * .85;
        m = ray.y;
        if(ray.x<MIN_DIST*d||d>MAX_DIST)break;
    }

    if(d<MAX_DIST) {
        C = hsv2rgb(vec3(clamp(d*.035,0.,1.)+T*.05,1.,.5));
    } 
    
    // fog level
    C = mix(vec3(.01), C, exp(-.00125*d*d*d));

    C = pow(C, vec3(.4545));
    O = vec4(C,1.);
    
    glFragColor=O;
}