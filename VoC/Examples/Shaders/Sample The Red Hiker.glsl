#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Xl2BRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-----------------------------------------------------
// Created by sebastien durand - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------

//-----------------------------------------------------

// Change this to improve quality (3 is good)

#define ANTIALIASING 1

//#define WITH_SHADOW
#define WITH_AO

#define PRECISION_FACTOR 5e-1

#define MIN_DIST_AO .005
#define MAX_DIST_AO .06
#define PRECISION_FACTOR_AO PRECISION_FACTOR

const int   STAR_VOXEL_STEPS = 20;
const float STAR_VOXEL_STEP_SIZE = 3.;
const float STAR_RADIUS = .02;

float gTime;

//                       Contact           Down               Pass               Up      
const float ep = 16.;
vec3[9] TETE = vec3[9](  vec3(50,24,0),    vec3(73,30,0),     vec3(94,20,0),     vec3(117,15,0), //vec3(138,29,0), 
                         vec3(85+50,24,0), vec3(85+73,30,0),  vec3(85+94,20,0),  vec3(85+117,15,0), /*vec3(85+138,29,0),*/ vec3(168+50,24,0));

vec3[9] EPAULE = vec3[9](vec3(44,47,ep),   vec3(66,53,ep),    vec3(91,43,ep),    vec3(115,38,ep), /*vec3(140,50,15),*/ 
                         vec3(85+51,50,ep),vec3(85+73,55,ep), vec3(85+91,43,ep), vec3(85+111,37,ep), vec3(168+44,47,ep));

vec3[9] COUDE = vec3[9]( vec3(25,68,25),   vec3(46,71,25),    vec3(88,74,25),    vec3(120,69,25), //vec3(148,75,15),
                         vec3(85+54,66,25),vec3(85+87,71,25), vec3(85+91,75,25), vec3(85+92,65,25), vec3(168+25,68,25));

vec3[9] POIGNE = vec3[9](vec3(20,90,15),   vec3(35,81,20),    vec3(88,106,25),   vec3(128,94,25), 
                         vec3(164,85,15),  vec3(85+102,86,20),vec3(85+88,104,25),vec3(85+82,86,20), vec3(168+20,90,15));

vec3[9] HANCHE = vec3[9](vec3(42,90,10.),  vec3(62,95,10.),   vec3(83,88,10.),   vec3(107,83,10.),  
                         vec3(127,92,10.), vec3(147,94,10.),  vec3(168,91,10.),  vec3(192,85,10.), vec3(42+168,90,10));

vec3[9] GENOU = vec3[9]( vec3(29,118,7.),  vec3(48,120,8.),   vec3(97,117,10.),  vec3(130,107,10.), 
                         vec3(144,120,7.), vec3(167,118,7.),  vec3(167,118,7.),  vec3(181,111,7.), vec3(168+29,118,7));

vec3[9] CHEVILLE=vec3[9](vec3(5,134,5.),   vec3(22,132,6.),   vec3(71,122,10.),  vec3(113,127,10.), 
                         vec3(162,146,5.), vec3(164,146,5.),  vec3(164,146,5.),  vec3(168,137,5.), vec3(168+5,134,5));

vec3[9] PIED = vec3[9](  vec3(14,150,10.), vec3(16,150,10.),  vec3(63,139,10.),  vec3(119,143,10.), 
                         vec3(178,139,10.),vec3(182,150,10.), vec3(182,150,10.), vec3(182,150,10.), vec3(168+14,150,10));

// consts
const float tau = 6.2831853;
const float phi = 1.61803398875;

// Isosurface Renderer
const int g_traceLimit=64;
const float g_traceSize=.004;

//const vec3 g_boxSize = vec3(.4);

// Data to read in Buf A

vec3 g_envBrightness = vec3(.5,.6,.9); // Global ambiant color
vec3 g_lightPos1, g_lightPos2;
vec3 g_vConnexionPos, g_posFix; 
vec3 g_vConnexionPos2;

// -----------------------------------------------------------------

float keyPress(int ascii) {
    return 0.0;//texture(iChannel2,vec2((.5+float(ascii))/256.,0.25)).x ;
}

float hash( float n ) { return fract(sin(n)*43758.5453123); }

float noise( in vec3 x ) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = vec2(0.0);//textureLod( iChannel0, (uv+ 0.5)/256.0, 0.0 ).yx;
    return mix( rg.x, rg.y, f.z );
}

//-----------------------------------------------------
// Noise functions
//-----------------------------------------------------
vec3 hash33( const in vec3 p) {
    return fract(vec3(
        sin( dot(p,    vec3(127.1,311.7,758.5453123))),
        sin( dot(p.zyx,vec3(127.1,311.7,758.5453123))),
        sin( dot(p.yxz,vec3(127.1,311.7,758.5453123))))*43758.5453123);
}

// - Palette ---------------------------------------------------------
// https://www.shadertoy.com/view/4dsSzr

vec3 heatmapGradient(float t) {
    return clamp((pow(t, 1.5) * .8 + .2) * vec3(smoothstep(0., .35, t) + t * .5, smoothstep(.5, 1., t), max(1. - t * 1.7, t * 7. - 6.)), 0., 1.);
}

float distanceRayPoint(vec3 ro, vec3 rd, vec3 p, out float h) {
    h = dot(p-ro,rd);
    return length(p-ro-rd*h);
}

float distanceLineLine(vec3 ro, vec3 u, vec3 ro2, vec3 v)
{
    vec3 w = ro - ro2;
    float a = dot(u,u);         // always >= 0
    float b = dot(u,v);
    float c = dot(v,v);         // always >= 0
    float d = dot(u,w);
    float e = dot(v,w);
    float D = a*c - b*b;        // always >= 0

    float sc = (b*e - c*d) / D;
    float tc = (a*e - b*d) / D;

    // get the difference of the two closest points
    vec3 dP = w + (sc * u) - (tc * v);
    return sc>0. ? length(dP):1000.;   // return the closest distance
}

vec4 renderStarField(in vec3 ro, in vec3 rd, in float tmax) { 
 
    float d =  0.;
    
    vec3 ros = ro + rd*d;
    ros /= STAR_VOXEL_STEP_SIZE;
    vec3 pos = floor(ros),
         mm, ri = 1./rd,
         rs = sign(rd),
         dis = (pos-ros + 0.5 + rs*0.5) * ri;
    
    float dint;
    vec3 offset, id;
    vec4 col = vec4(0);
    vec4 sum = vec4(0);
    
    for( int i=0; i<STAR_VOXEL_STEPS; i++ ) {

        id = hash33(pos);
        offset = clamp(id+.1*cos(id+(id.x)*time),STAR_RADIUS, 1.-STAR_RADIUS);
        d = distanceRayPoint(ros, rd, pos+offset, dint);
        if (dint>0.&& dint*STAR_VOXEL_STEP_SIZE<tmax) {
            col.rgb = heatmapGradient(.4+id.x*.6);
            col = (vec4(.6+.4*col.rgb, 1.)*(1.-smoothstep(STAR_RADIUS*.5,STAR_RADIUS,d)));
            col.a *= smoothstep(float(STAR_VOXEL_STEPS),0.,dint);
            col.rgb *= col.a/dint;                                                
            sum += (1.-sum.a)*col;
            if (sum.a>.99) break;
        }
        mm = step(dis.xyz, dis.yxy) * step(dis.xyz, dis.zzx);
        dis += mm * rs * ri;
        pos += mm * rs;
    }
  
    return sum;
}

// ---------------------------------------------

// Distance from ray to point
float dista(vec3 ro, vec3 rd, vec3 p) {
    return length(cross(p-ro,rd));
}

// Intersection ray / sphere

bool intersectSphere(in vec3 ro, in vec3 rd, in vec3 c, in float r, out float t0, out float t1) {
    ro -= c;
    float b = dot(rd,ro), d = b*b - dot(ro,ro) + r*r;
    if (d<0.) return false;
    float sd = sqrt(d);
    t0 = max(0., -b - sd);
    t1 = -b + sd;
    return (t1 > 0.);
}

// -- Modeling Primitives ---------------------------------------------------

bool cube(vec3 ro, vec3 rd, vec3 sz, out float tn, out float tf) { //, out vec3 n) {
    vec3 m = 1./rd,
         k = abs(m)*sz,
         a = -m*ro-k*.5, 
         b = a+k;
//    n = -sign(rd)*step(a.yzx,a)*step(b.zxy,b);
    tn = max(max(a.x,a.y),a.z);
    tf = min(min(b.x,b.y),b.z);
    return tn>0. && tn<tf;
}

float sdPlane( vec3 p ) {
    return p.y;
}

float udBox( vec3 p, vec3 b ) {
  return length(max(abs(p)-b,0.0));
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float sdCapsule2( vec3 p, vec3 a, vec3 b, float r1, float r2 )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - mix(r1,r2,h);
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdPlane( vec3 p, vec3 n )
{
  // n must be normalized
  return dot(p,n);
}

float smin(in float a, in float b, in float k ) {
    float h = clamp( .5+.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.-h);
}

vec3 epaule1, coude1, poigne1, tete,
     epaule2, coude2, poigne2;
vec3 pied1, cheville1, genou1, hanche1,
     pied2, cheville2, genou2, hanche2;

mat2 rot, rot2;

// Mengerfold by Gijs [https://www.shadertoy.com/view/MlBXD1]
float map(vec3 pos){
  //  pos.xz = mod(pos.xz-5.,10.)+5.;
    
    float r1= .15, r2 = .1, r3= .1;

    float d = 100.;
    
    d = min(d, sdCapsule2(pos, pied1, cheville1, r2,r1));
    d = min(d, sdCapsule(pos, cheville1, genou1, r1));
    d = min(d, sdCapsule2(pos, genou1, hanche1, r1,r2));
 
    vec3 v2 = normalize(genou1 - cheville1);
    vec3 v1 = normalize(cheville1 - pied1-v2*.1);
    vec3 v3 = cross(v1,v2);
    d = max(d, -sdPlane(pos-cheville1+v2*.1, -cross(v1,v3))); 
    
    float d2 = sdCapsule2(pos, pied2, cheville2, r2,r1);
    d2 = min(d2, sdCapsule(pos, cheville2, genou2, r1));
    d2 = min(d2, sdCapsule2(pos, genou2, hanche2, r1,r2));

    v2 = normalize(genou2 - cheville2);
    v1 = normalize(cheville2 - pied2-v2*.1);
    v3 = cross(v1,v2);
    d2 = max(d2, -sdPlane(pos-cheville2+v2*.1, -cross(v1,v3))); 

    d = min(d, d2);
    
    v1 = normalize(poigne1-coude1);
    d = min(d, sdCapsule(pos, epaule1, coude1, r2));
    d = min(d, sdCapsule2(pos, coude1, poigne1-.05*v1, r2,r3));
 
    vec3 ep0 = mix(epaule1,epaule2,.5);
    vec3 ha0 = mix(hanche1,hanche2,.5);
    

    // tete
    d = min(d, sdCapsule2(pos, tete - vec3(0,.17,0), tete + vec3(-.02,.11,0),.13,.16));
  //  d = min(d, sdCapsule2(pos, tete - vec3(-.17,.06,0),tete - vec3(-.08,.05,0), .03,.05));
  
    // main
    // v1 = normalize(poigne1-coude1);
    v3 = -normalize(cross(v1,normalize(poigne1-epaule1)));
    v2 = -cross(v1,v3);
     
    
    vec3 c = poigne1-v3*.06-v1*.12;
    d2 = sdCapsule2(pos, c, poigne1+.1*(v2+v1+v3), .013,.033);
    d2 = min(d2, sdCapsule2(pos, c, poigne1+.18*(v1+v2*.2), .01,.03));
    d2 = min(d2, sdCapsule2(pos, c, poigne1+.2*(v1-v2*.2), .01,.03));
    d2 = min(d2, sdCapsule2(pos, c, poigne1+.15*(v1-v2*.6), .01,.026));
     
    
    // Main 2
    v1 = normalize(poigne2-coude2);
    v3 = normalize(cross(v1,normalize(poigne2-epaule2)));
    v2 = cross(v1,v3);
    c = poigne2-v3*.06-v1*.12;
    
    d = min(d, sdCapsule(pos, epaule2, coude2, r2));
    d = min(d, sdCapsule2(pos, coude2, poigne2-.05*v1, r2,r3));
    d = min(d, sdCapsule(pos, epaule1, epaule2, r2));
   
    d2 = min(d2, sdCapsule2(pos, c, poigne2+.1*(v2+v1+v3), .013,.033));
    d2 = min(d2, sdCapsule2(pos, c, poigne2+.18*(v1+v2*.2), .01,.03));
    d2 = min(d2, sdCapsule2(pos, c, poigne2+.2*(v1-v2*.2), .01,.03));
    d2 = min(d2, sdCapsule2(pos, c, poigne2+.15*(v1-v2*.6), .01,.026));

    
 
   d = smin(d2, d, .08);

// BBOX
//float dx = gTime*168.*.02/8.+.85;
//d = min(d, udBox(pos-vec3(dx,1.35,0), vec3(1.1, 1.7,.7)));
    
    // torse
    vec3 a = mix(ha0,ep0,.15), b = mix(ha0,ep0,.78);
    
        // cou
    d = smin(d, sdCapsule(pos, mix(epaule1,epaule2,.5)-vec3(.1,0,0), tete-vec3(.11,.1,0), r2*.5),.06);
    d = smin(d, sdCapsule2(pos, a, b, .2,.26),.18);

    // Sol
    vec3 te = vec3(0.0);//textureLod(iChannel0, pos.xz*.1,1.).rgb;
    d = min(d, pos.y+.3*length(te));
    
    // ceinture
    vec3 pos2 = pos-ha0+vec3(0,-.13,.02);
    pos2.yz *= rot2;

   // float dd = .01*(cos(35.*pos.y-ep0.y));

    
    d = min(d,mix(d,sdCappedCylinder(pos2, vec2(.28,.08)),.4)); 
 
    // Sac a dos
    pos -= ep0;//epaule2;
    d2 = udRoundBox(pos+vec3(.33,.2,0), vec3(.1,.3,.2), .15); 
    d2 += .005*(smoothstep(.1,.6,cos(51.*(.2*pos.z+.4*pos.x*pos.x+pos.y)))+smoothstep(.4,.9,sin(51.*(.8*cos(1.+pos.z)+.4*pos.x+.2*pos.y))));
    
    
  //  pos.z = abs(pos.z);
    pos.yz *= rot;
    
    d2 = smin(d2,mix(d,sdCappedCylinder(pos.yzx+vec3(.13,.04,.1), vec2(.37,.05)),.75),.05); 
    

    return min(d2,d);

}

//----------------------------------------------------------------------

vec2 opU( vec2 d1, vec2 d2 ) {
    return (d1.x<d2.x) ? d1 : d2;
}

//----------------------------------------------------------------------

// ---------------------------------------------------------------------------

float SmoothMax( float a, float b, float smoothing ) {
    return a-sqrt(smoothing*smoothing + pow(max(.0,a-b),2.0));
}

vec3 Sky( vec3 ray) {
    return g_envBrightness*mix( vec3(.8), vec3(0), exp2(-(1.0/max(ray.y,.01))*vec3(.4,.6,1.0)) );
}
float isGridLine(vec2 p, vec2 v) {
    vec2 k = smoothstep(.0,1.,abs(mod(p+v*.5, v)-v*.5)/.025);
    return k.x * k.y;
}
// -------------------------------------------------------------------

float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<24; i++ )
    {
        float h = map( ro + rd*t );
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.05, 0.20 );
        if( h<0.01 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

#ifdef WITH_AO

float calcAO( in vec3 pos, in vec3 nor ){
    float dd, hr, totao = 0.0;
    float sca = 1.0;
    vec3 aopos; 
    for( int aoi=0; aoi<5; aoi++ ) {
        hr = 0.01 + 0.05*float(aoi);
        aopos =  nor * hr + pos;
        totao += -(map( aopos )-hr)*sca;
        sca *= 0.75;
    }
    return clamp( 1.0 - 4.0*totao, 0.0, 1.0 );
}

#endif

// Adapted from Shane
vec3 doColor( in vec3 pos, in vec3 rd, in vec3 nor, in vec3 lp, in vec3 objCol){
    
          vec3 ref = reflect( rd, nor );
        
        // material        
        vec3 col = objCol;//0.45 + 0.35*sin( vec3(0.05,0.08,0.10)*(m-1.0) );
        

        // lighitng        
        float occ = calcAO( pos, nor );
        vec3  lig = normalize( vec3(0.4, 0.7, 0.6) );
        vec3  hal = normalize( lig-rd );
        float amb = .4;//clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        float dom = smoothstep( -0.1, 0.1, ref.y );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );

    #ifdef WITH_SHADOW
        dif *= calcSoftshadow( pos, lig, 0.2, 2.5 );
      //  dom *= calcSoftshadow( pos, ref, 0.2, 2.5 );
#endif
        float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),106.0)*
                    dif *
                    (0.04 + 0.96*pow( clamp(1.0+dot(hal,rd),0.0,1.0), 50.0 ));

        vec3 lin = vec3(0.0);
        lin += .80*dif*vec3(1.00,0.80,0.55)*(.3+.7*occ);
        lin += 0.40*amb*vec3(0.40,0.60,1.00)*occ;
        lin += 0.50*dom*vec3(0.40,0.60,1.00)*occ;
        lin += 0.50*bac*vec3(0.25,0.25,0.25)*occ;
        lin += 0.25*fre*vec3(1.00,1.00,1.00)*occ;
        col = col*lin;
        col += 10.00*spe*vec3(1.00,0.90,0.70);
   // col = vec3(occ);
    return col;
}

float Trace( vec3 pos, vec3 ray, float traceStart, float traceEnd ) {
  
    // BBOX
     float dx = gTime*168.*.02/8.+.85;

    float tn, tf;
    if (cube(pos-vec3(dx,1.35,0), ray, vec3(1.1, 1.7,.7)*2.,  tn, tf)) {
        traceEnd = min(tf, traceEnd);
        float t = max(tn, traceStart);
        float h;
        for( int i=0; i < g_traceLimit; i++) {
            h = map( pos+t*ray );
            if (h < g_traceSize || t > traceEnd)
                return t>traceEnd?100.:t;
            t = t+h+.002;
        }
    }
    
    return 100.0;
}

vec3 Normal( vec3 pos, vec3 ray, float t) {

    float pitch = .2 * t / resolution.x;   
    pitch = max( pitch, .005 );
    vec2 d = vec2(-1,1) * pitch;

    vec3 p0 = pos+d.xxx; // tetrahedral offsets
    vec3 p1 = pos+d.xyy;
    vec3 p2 = pos+d.yxy;
    vec3 p3 = pos+d.yyx;

    float f0 = map(p0), f1 = map(p1), f2 = map(p2),    f3 = map(p3);
    vec3 grad = p0*f0+p1*f1+p2*f2+p3*f3 - pos*(f0+f1+f2+f3);
    // prevent normals pointing away from camera (caused by precision errors)
    return normalize(grad - max(.0,dot (grad,ray ))*ray);
}

// Camera
vec3 Ray( float zoom, in vec2 gl_FragCoord) {
    return vec3( gl_FragCoord.xy-resolution.xy*.5, resolution.x*zoom );
}

vec3 Rotate( inout vec3 v, vec2 a ) {
    vec4 cs = vec4( cos(a.x), sin(a.x), cos(a.y), sin(a.y) );
    
    v.yz = v.yz*cs.x+v.zy*cs.y*vec2(-1,1);
    v.xz = v.xz*cs.z+v.zx*cs.w*vec2(1,-1);
    
    vec3 p;
    p.xz = vec2( -cs.w, -cs.z )*cs.x;
    p.y = cs.y;
    
    return p;
}

mat2 matRot(in float a) {
    float ca = cos(a), sa = sin(a);
    return mat2(ca,sa,-sa,ca);
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr) {
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 getPos(vec3 arr[9], int it, float kt, float z) {
    it = it%8;
    
    vec3 p = mix(arr[it], arr[it+1], kt);
    
    return .02*vec3(p.x+floor(gTime/8.)*168., 150.-p.y, p.z*z);
}

void main(void)
{
    
    gTime = time*6.;
    
    int it = int(floor(gTime));
    float kt = fract(gTime);
    
    float dz = 1.;
    tete = getPos(TETE, it, kt, dz);

    epaule1 = getPos(EPAULE, it, kt, -dz);
    coude1 = getPos(COUDE, it, kt, -dz);
    poigne1 = getPos(POIGNE, it, kt, -dz);

    
    pied1 = getPos(PIED, it, kt, dz);
    cheville1 = getPos(CHEVILLE, it, kt, dz);
    genou1 = getPos(GENOU, it, kt, dz);
    hanche1 = getPos(HANCHE, it, kt, dz);

    
    epaule2 = getPos(EPAULE, it+4, kt, dz);
    coude2 = getPos(COUDE, it+4, kt, dz);
    poigne2 = getPos(POIGNE, it+4, kt, dz);

    pied2 = getPos(PIED, it+4, kt, -dz);
    cheville2 = getPos(CHEVILLE, it+4, kt, -dz);
    genou2 = getPos(GENOU, it+4, kt, -dz);
    hanche2 = getPos(HANCHE, it+4, kt, -dz);

    float a = -1.5708*.4;
    rot = mat2(cos(a), sin(a), -sin(a), cos(a));
    
    a = -1.5708*.1;
    rot2 = mat2(cos(a), sin(a), -sin(a), cos(a));
    
    float dx = it%8 < 4 ? -85.*.02 : +85.*.02; 
    pied2.x += dx;
    cheville2.x += dx;
    genou2.x += dx;
    hanche2.x += dx;

    epaule2.x += dx;
    coude2.x += dx;
    poigne2.x += dx;
    
    
    //pied1 = vec3(.0);
// ------------------------------------
 
    
    vec2 m = mouse*resolution.xy.xy/resolution.y - .5;
   
 
    //float time = 15.0 + time;

    

// Positon du point lumineux
    float distLightRot =  100.;
                              
    float lt = 5.;//*(time-1.);
    
  
    g_lightPos1 = distLightRot*vec3(cos(lt*.5), 1., sin(lt*.5));
   
    // g_lightPos1.xz += hanche1.xz;
     

    float traceStart = .2;

    float t, s1, s2;
    
    vec3 col = vec3(0), colorSum = vec3(0.);
    vec3 pos;
    vec3 ro, rd;
    
  
    
#if (ANTIALIASING == 1)    
    int i=0;
#else
    for (int i=0;i<ANTIALIASING;i++) {
#endif
        float randPix = hash(time);
        vec2 subPix = .4*vec2(cos(randPix+6.28*float(i)/float(ANTIALIASING)),
                              sin(randPix+6.28*float(i)/float(ANTIALIASING)));        
        // camera    
        vec2 q = (gl_FragCoord.xy+subPix)/resolution.xy;
        vec2 p = -1.0+2.0*q;
        p.x *= resolution.x/resolution.y;

        ro = vec3(hanche1.x+12.*cos(3.14*(.01*time+m.x+.3)),3.+3.*abs(sin(.01314*time))+10.*(m.y+.3),hanche1.z+12.*sin(3.14*(.01*time+m.x+.3)));// .9*cos(0.1*time), .45, .9*sin(0.1*time) );
        vec3 ta = hanche1;

        ta.x +=1.2;
        ta.y = 1.2;
        
        // camera-to-world transformation
        mat3 ca = setCamera(ro, ta, 0.0);

        // ray direction
         rd = ca * normalize( vec3(p.xy,4.5) );

        float tGround = -(ro.y-0.) / rd.y;
        float traceEnd = 100.;//min(tGround,100.);
        traceStart = 10.;
        col = vec3(0);
        vec3 n;
        t = Trace(ro, rd, traceStart, traceEnd);

      
        
        if (tGround < 0.) tGround = 100.;
        
        t = min(t, tGround);
        
        
        if (t<100.) {
        
        vec3 objCol = vec3(0,0,0);

            pos = ro + rd*t;
            n = Normal(pos, rd, t);
               if (pos.y<.01) {
               objCol = .02*vec3(.8,.8,.9);//textureLod(iChannel0, pos.xz*.1,1.).rgb;
               } else {
                objCol = vec3(.5,.0,.0) ;
               }

            col = doColor(pos, rd, n, g_lightPos1, objCol);
        } else {
            float time = time*.5;
            float kt = fract(time);
            vec3 k = -.5+hash33(floor(time)+vec3(0, 2, 112));
            if (k.y>.25) {
            float t0 = distanceLineLine(ro,rd, k*200.+vec3(-100,0,0), normalize(k));
    // comet
          
            col = vec3(1,.8,.7) * (1.-smoothstep(0.,.8,t0)) * smoothstep(.53,.01,rd.y+.2*kt);
            col *= (.5+.5*hash(time))*smoothstep(0.,1., kt);
            }
        }
        
#if (ANTIALIASING > 1)    
        colorSum += col;
    }
    
    col = colorSum/float(ANTIALIASING);
#endif
    
    
    vec4 star = renderStarField(ro, rd, t);
//star.rgb *= 3.;//vec3(1.);
         star.rgb += col.rgb * (1.0 - star.a);
         col = star.rgb;
        
         
    // fog
    float f = 50.0;
    col = mix( vec3(.18), col, exp2(-t*vec3(.4,.6,1.0)/f) );
    
    

    
    col = pow( col, vec3(0.4545) );
    col *= pow(16.*q.x*q.y*(1.-q.x)*(1.-q.y), .1); // Vigneting
    glFragColor =  vec4(col,1);
}
