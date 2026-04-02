#version 420

// original https://www.shadertoy.com/view/wdKBWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**

    Wooden kinetic windmills | @pjkarlik
    
    Just working on making procedural textures
    and stuff over using images. Handy noise
    makes some good lines / want to try and do
    boards, pannels. 

    Tried to optimize - some globals and precal
*/

#define R            resolution
#define T            time
#define M            mouse*resolution.xy
#define S           smoothstep

#define PI            3.141592653589793
#define PI2            6.283185307

#define MAX_DIST    75.
#define MIN_DIST    .001

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))

//The hash functions
float hash(in float n){return fract(sin(n)*43.54); }
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43.5453); }

//Sum noise
float noise(in vec2 x){
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.-2.*f);
    float n = p.x + p.y*57.;
    float res = mix(mix( hash(n+  0.), hash(n+  1.),f.x),
                    mix( hash(n+ 57.), hash(n+ 58.),f.x),f.y);
    return res;
}

//http://mercury.sexy/hg_sdf/
float vmax(vec3 v) { return max(max(v.x, v.y), v.z); }
float fBox(vec3 p, vec3 b, float r) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)))-r;
}

//@iq SDF function
float sdCyl( vec3 p, float h, float r ){
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

//@iq extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    vec2 w = vec2( sdf, abs(pz) - h );
    return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}

const vec3 k = vec3(-.8660254, .5, .57735);
float sHexS(in vec2 p, float r, in float sf){
    p = abs(p); 
    p -= 2.*min(dot(k.xy,p), 0.)*k.xy;
    r -= sf;
    return length(p - vec2(clamp(p.x, -k.z*r, k.z*r), r))*sign(p.y - r) - sf;
}

// lazy globals
vec3 htile;
vec3 g_hp,s_hp,s_tile,g_tile;
float g_hsh,s_hsh,tm,hgt = .05;
mat2 r60;

const float hexscale = 2.75;
const float scale = 2./hexscale;
const float size = 2.45;
const float s25 = .025*scale;
const float s15 = .15*scale;
const float s08 = .008*scale;
const float scsz = scale/(size);
const float sw = (scsz- s25)/1.6;
const float disize = scsz + s25;

const vec2 l = vec2(scale*1.732/2., scale);
const vec2 s = l*2.;
const vec2[4] ps4 = vec2[4](vec2(-l.x, l.y), l + vec2(0., l.y), -l, vec2(l.x, -l.y) + vec2(0., l.y));
    
    
vec4 map(vec3 q3){
    q3.z+=tm;
    float d=1e5,mid=0.,boxID=0.;
    vec2 p,ip,id,cntr;

    for(int i = 0; i<4; i++){

        cntr = ps4[i]/2.;
        p = q3.xz - cntr;
        
        ip = floor(p/s) + .5;
        p -= (ip)*s;
        vec2 idi = (ip)*s + cntr;
        
        float random = hash21(idi);
        float random2= hash21(idi.yx);
        
        float di2D = sHexS(p, disize, s25),
              di = opExtrusion(di2D, (q3.y+1.), 1.2);

        vec3 pq = vec3(p.x,q3.y,p.y);
        vec3 bs = vec3(sw, (random2*.05)*scale ,s08);
        
        float post = sdCyl(pq-vec3( 0,s15,0),bs.x*.195,.15);

        vec3 pz = pq;
        pz.xz=abs(pz.xz);
        pq.xz*=r2(random2*T*.5);
        vec3 hps = vec3(bs.x*1.75,.2,0);
        float ns = .201+hgt*scale;
        float planks = fBox(pq-vec3( sw, ns,0),bs,.0015);
            post = min (sdCyl(pz-hps,bs.x*.15,.01), post);
        pq.xz *= r60;
        pz.xz *= r60;
        planks = min(  fBox(pq-vec3(-sw, ns,0),bs,.0015),planks);
           post = min(sdCyl(pz-hps,bs.x*.15,.0075), post);
        pq.xz *= r60;
        pz.xz *= r60;
        planks = min(  fBox(pq-vec3( sw, ns,0),bs,.0015),planks);
           post = min(sdCyl(pz-hps,bs.x*.15,.0075), post);
        if(planks<d) {
            d = planks;
            id = idi;
            mid = 2.;
            g_tile = vec3(0);
            g_hp = pq;
            g_hsh = 0.;
        }

        if(di<d){
            d = di;
            id = idi;
            mid = 1.;
            g_tile = vec3(di2D,id);
            g_hp = vec3(p.x,q3.y,p.y);
            g_hsh = random;
        }

        if(post<d) {
            d = post;
            id = idi;
            mid = 3.;
            g_tile = vec3(0);
            g_hp = pq;
            g_hsh = 0.;
        }
        
    }
  
    return vec4(d, id, mid);
}

vec4 marcher( in vec3 ro, in vec3 rd, int maxstep ) {
    float t = 0.;
    vec3 m = vec3(0.);
    for( int i=0; i<maxstep; i++ ) {
        vec4 d = map(ro + rd * t);
        m = d.yzw;
        if(d.x<MIN_DIST*t||t>MAX_DIST) break;
        t +=  d.x*.85;
    }
    return vec4(t,m);
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 getNormal(vec3 p, float t){
    float e = MIN_DIST *t;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}

float getDiff(in vec3 p, in vec3 lpos, in vec3 n) {
    vec3 l = lpos-p;
    vec3 lp = normalize(l);
    float dif = clamp(dot(n,lp),0. , 1.),
          shadow = marcher(p + n * MIN_DIST * 2.,lp,84).x;
    if(shadow < length(l)) dif *= .2;
    return dif;
}

vec3 getSpec(vec3 p, vec3 n, vec3 l, vec3 ro) {
    vec3 spec = vec3(0.);
    float strength = 0.75;
    vec3 view = normalize(p - ro);
    vec3 ref = reflect(l, n);
    float specValue = pow(max(dot(view, ref), 0.), 32.);
    return spec + strength * specValue;
}
//@Shane AO
float calcAO(in vec3 p, in vec3 n){
    float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
        float hr = float(i + 1)*.16/8.; 
        float d = map(p + n* hr).x;
        occ += (hr - d)*sca;
        sca *= .8;
        if(sca>1e5) break;
    }
    return clamp(1. - occ, 0., 1.);
}
//@iqhttps://iquilezles.org/www/articles/palettes/palettes.htm
vec3 getHue(float t){ 
    vec3 c = vec3(.95, .94, .85),
         d = vec3( .9,.55,.25),
         a = vec3(.65),
         b = vec3(.45);
    
    return a + b*cos( PI *(c*t+d) ); 
}

const vec3 vein = vec3(0.235,0.075,0.004);
const vec3 woodAxis = normalize(vec3(1,-3,2));
vec4 getWood(vec3 p){
    vec3 board = vec3(0.875,0.569,0.149)+(s_hsh*.8);
    vec3 mfp = (p + dot(p,woodAxis)*woodAxis*13.5)*5.0;
    float wood = 0.0;
    wood += abs(noise(mfp.xz*2.)-.5);
    wood += abs(noise(mfp.xz*12.0)-.5)/2.0;
    wood += abs(noise(mfp.xz*14.0)-.5)/4.0;
    wood += abs(noise(mfp.xz*8.0)-.5)/8.0;
    wood /= .75-1.5/18.0;
    wood = pow(1.0-clamp(wood,0.0,1.0),5.0); // curve to thin the veins
    return vec4(mix( board, vein, wood ), wood);
}

float circle(vec2 pt, float r, vec2 center, float lw) {
      float len = length(pt - center);
      float hlw = lw / 2.;
      float edge = .005;
      return S(r-hlw-edge,r-hlw, len)-S(r+hlw,r+hlw+edge, len);
}

float circle(vec2 pt, float r, vec2 center) {
      float edge = .005;
      return 1.-S(r-edge,r+edge, length(pt - center));
}
// Tri-Planar blending function. @Shane
// https://www.shadertoy.com/view/XlXXWj
// hacked to work with my wood texture
vec3 getTex( in vec3 p, in vec3 n ) {  
    n = max(n*n - .2, MIN_DIST);
    n /= dot(n, vec3(1)); 
    vec3 tx = getWood(s_hp.yzx).xyz;
    vec3 ty = getWood(s_hp.zxy).xyz;
    vec3 tz = getWood(s_hp.xyz).xyz;
    return mat3(tx*tx, ty*ty, tz*tz)*n;
}

vec3 getColor(float m, in vec3 n) {
    vec3 h = vec3(0.05);
    vec3 tex = getTex(s_hp, n).rgb;
    vec3 hue = getHue(s_hsh*1.25);
    if(m==1.) {
        h = vec3(0.05);
        float hex = abs(s_tile.x) - .3;
        hex= s_hsh>.5 ? abs(abs(hex)-.1 )-.005 : abs(hex)-.1;
        float sft = .015;
        float lex = hex-(.05-sft);
        hex=abs(abs(hex)-.05)-sft;
        h=tex;
        float cir = circle(vec2(0),.15,s_hp.xz,.2);
        cir=smoothstep(.01,.05,cir);
        h = mix(h,getHue(s_hsh*2.25),cir);
        
        float angle = atan(s_hp.x, s_hp.z);
        float stripes = sin( angle * 24. );
        stripes=smoothstep(.01,.05,stripes);
        vec3 ts = s_hsh<.2 ? mix(tex+s_hsh,hue,stripes) : tex+(s_hsh*.5);
        h = mix(h, hue, 1.-S(.001, .0013,hex));
        h = mix(h,ts, 1.-S(.001, .0013,lex));
        
    }
    
    if(m==2.) h = vec3(0.859,0.373,0.000) * (tex + s_hsh); 
    
    if(m==3.) h = vec3(.3); 
    if(m==4.) h = (tex - s_hsh); 
    return h;
}

void main(void) {
    tm = T*.275;
    r60 = r2(60.*PI/180.);
    
    vec2 U = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);

    vec3 ro = vec3(0,.0,1.75),
         lp = vec3(0,0,0);
         
    ro.zy *= r2(-82.5*PI/180.);         

    vec3 cf = normalize(lp-ro),
         cp = vec3(0.,1.,0.),
         cr = normalize(cross(cp, cf)),
         cu = normalize(cross(cf, cr)),
         c = ro + cf * .75,
         i = c + U.x * cr + U.y * cu,
         rd = i-ro;

    vec3 C = vec3(0.);
    vec3 FC= vec3(U.y*.5);

    vec4 ray = marcher(ro,rd,128);
    s_hp=g_hp;
    s_hsh=g_hsh;
    s_tile=g_tile;
    float t = ray.x;

    if(ray.x<MAX_DIST) {
        vec3 p = ro+ray.x*rd,
             n = getNormal(p,ray.x),
             h = getColor(ray.w,n);
        vec3 lpos1 = vec3(-.5, 5.0, -2.5);
        vec3 spec = getSpec(p,n,normalize(lpos1),ro);
        float ao = calcAO(p,n);
        float diff =  getDiff(p, lpos1, n);
        C += (h * diff+spec)* ao;
  
    }
    
    C = mix( C, FC, 1.-exp(-.015*t*t*t));
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
