#version 420

// original https://www.shadertoy.com/view/4dVXWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PHI (sqrt(5.)*0.5 + 0.5)
#define PI 3.14159265

#define t time

vec2 rot2D(vec2 p, float angle) {

    angle = radians(angle);
    float s = sin(angle);
    float c = cos(angle);
    
    return p * mat2(c,s,-s,c);
    
}
        
    

float fOpIntersectionRound(float a, float b, float r) {
    float m = max(a, b);
    if ((-a < r) && (-b < r)) {
        return max(m, -(r - sqrt((r+a)*(r+a) + (r+b)*(r+b))));
    } else {
        return m;
    }
}

// Cone with correct distances to tip and base circle. Y is up, 0 is in the middle of the base.
float fCone(vec3 p, float radius, float height) {
    vec2 q = vec2(length(p.xz), p.y);
    vec2 tip = q - vec2(0, height);
    vec2 mantleDir = normalize(vec2(height, radius));
    float mantle = dot(tip, mantleDir);
    float d = max(mantle, -q.y);
    float projected = dot(tip, vec2(mantleDir.y, -mantleDir.x));
    
    // distance to tip
    if ((q.y > height) && (projected < 0.)) {
        d = max(d, length(tip));
    }
    
    // distance to base ring
    if ((q.x > radius) && (projected > length(vec2(height, radius)))) {
        d = max(d, length(q - vec2(radius, 0)));
    }
    return d;
}

// Reflect space at a plane
float pReflect(inout vec3 p, vec3 planeNormal, float offset) {
    float t = dot(p, planeNormal)+offset;
    if (t < 0.) {
        p = p - (2.*t)*planeNormal;
    }
    return sign(t);
}

// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// The "Round" variant uses a quarter-circle to join the two objects smoothly:
float fOpUnionRound(float a, float b, float r) {
    float m = min(a, b);
    if ((a < r) && (b < r) ) {
        return min(m, r - sqrt((r-a)*(r-a) + (r-b)*(r-b)));
    } else {
     return m;
    }
}

// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float pModPolar(inout vec2 p, float repetitions) {
    float angle = 2.*PI/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = mod(a,angle) - angle/2.;
    p = vec2(cos(a), sin(a))*r;
    // For an odd number of repetitions, fix cell index of the cell in -x direction
    // (cell index would be e.g. -5 and 5 in the two halves of the cell):
    if (abs(c) >= (repetitions/2.)) c = abs(c);
    return c;
}

vec3 pModDodecahedron(inout vec3 p) {
    vec3 v1 = normalize(vec3(0., PHI, 1.));
    vec3 v2 = normalize(vec3(PHI, 1., 0.));

    float sides = 5.;
    float dihedral = acos(dot(v1, v2));
    float halfDdihedral = dihedral / 2.;
    float faceAngle = 2. * PI / sides;
    
    p.z = abs(p.z);
    
    pR(p.xz, -halfDdihedral);
    pR(p.xy, faceAngle / 4.);
    
       p.x = -abs(p.x);
    
    pR(p.zy, halfDdihedral);
    p.y = -abs(p.y);
    pR(p.zy, -halfDdihedral);

    pR(p.xy, faceAngle);
    
    pR(p.zy, halfDdihedral);
    p.y = -abs(p.y);
    pR(p.zy, -halfDdihedral);

    pR(p.xy, faceAngle);
    
    pR(p.zy, halfDdihedral);
    p.y = -abs(p.y);
    pR(p.zy, -halfDdihedral);

    pR(p.xy, faceAngle);
    
    pR(p.zy, halfDdihedral);
       p.y = -abs(p.y);
    pR(p.zy, -halfDdihedral);

    p.z = -p.z;
    pModPolar(p.yx, sides);
    pReflect(p, vec3(-1, 0, 0), 0.);
    
    return p;
}

vec3 pModIcosahedron(inout vec3 p) {

    vec3 v1 = normalize(vec3(1, 1, 1 ));
    vec3 v2 = normalize(vec3(0, 1, PHI+1.));

    float sides = 3.;
    float dihedral = acos(dot(v1, v2));
    float halfDdihedral = dihedral / 2.;
    float faceAngle = 2. * PI / sides;
    

    p.z = abs(p.z);    
    pR(p.yz, halfDdihedral);
    
       p.x = -abs(p.x);
    
    pR(p.zy, halfDdihedral);
    p.y = -abs(p.y);
    pR(p.zy, -halfDdihedral);

    pR(p.xy, faceAngle);
    
    pR(p.zy, halfDdihedral);
    p.y = -abs(p.y);
    pR(p.zy, -halfDdihedral);

    pR(p.xy, faceAngle);
     
    pR(p.zy, halfDdihedral);
    p.y = -abs(p.y);
    pR(p.zy, -halfDdihedral);

    pR(p.xy, faceAngle);
  
    pR(p.zy, halfDdihedral);
       p.y = -abs(p.y);
    pR(p.zy, -halfDdihedral);

    p.z = -p.z;
    pModPolar(p.yx, sides);
    pReflect(p, vec3(-1, 0, 0), 0.);

    return p;
}

float spikeModel(vec3 p) {
    pR(p.zy, PI/2.);
    return fCone(p, 0.25, 3.);
}

float spikesModel(vec3 p) {
    float smooth = 0.6;
    
    pModDodecahedron(p);
    
    vec3 v1 = normalize(vec3(0., PHI, 1.));
    vec3 v2 = normalize(vec3(PHI, 1., 0.));

    float sides = 5.;
    float dihedral = acos(dot(v1, v2));
    float halfDdihedral = dihedral / 2.;
    float faceAngle = 2. * PI / sides;
    
    float spikeA = spikeModel(p);
    
    pR(p.zy, -dihedral);

    float spikeB = spikeModel(p);

    pR(p.xy, -faceAngle);
    pR(p.zy, dihedral);
    
    float spikeC = spikeModel(p);
    
    return fOpUnionRound(
        spikeC,
        fOpUnionRound(
            spikeA,
            spikeB,
            smooth
           ),
        smooth
       );
}

float coreModel(vec3 p) {
    float outer = length(p) - .9;
    float spikes = spikesModel(p);
    outer = fOpUnionRound(outer, spikes, 0.4);
    return outer;
}

float exoSpikeModel(vec3 p) {
    pR(p.zy, PI/2.);
    p.y -= 1.;
    return fCone(p, 0.5, 1.);
}

float exoSpikesModel(vec3 p) {
    pModIcosahedron(p);

    vec3 v1 = normalize(vec3(1, 1, 1 ));
    vec3 v2 = normalize(vec3(0, 1, PHI+1.));

    float dihedral = acos(dot(v1, v2));

    float spikeA = exoSpikeModel(p);
    
    pR(p.zy, -dihedral);

    float spikeB = exoSpikeModel(p);

    return fOpUnionRound(spikeA, spikeB, 0.5);
}

float exoHolesModel(vec3 p) {
    float len = 3.;
    pModDodecahedron(p);
    p.z += 1.5;
    return length(p) - .65;
}

float exoModel(vec3 p) {    
    float thickness = 0.18;
    float outer = length(p) - 1.5;
    float inner = outer + thickness;

    float spikes = exoSpikesModel(p);
    outer = fOpUnionRound(outer, spikes, 0.3);
    
    float shell = max(-inner, outer);

    float holes = exoHolesModel(p);
    shell = fOpIntersectionRound(-holes, shell, thickness/2.);
    
    return shell;
}

// Based on Template 3D by iq: https://www.shadertoy.com/view/ldfSWs

float doModel(vec3 p) {
    p.y -= 3.0;
    
    p.xz = rot2D(p.xz, (time) * 45.);
    
    float exo = exoModel(p);
    float core = coreModel(p);
    return min(exo, core);
}

void doCamera(out vec3 camPos, out vec3 camTar, in float time, in vec2 mouse) {
    
    float an = 10.0 * mouse.x + PI / 2.;
    //an = 10.;

    //float d = 2. + sin(an) * 1.6;
    float d = 2. + (1. - mouse.y) * 10.;
    camPos = vec3(
        sin(an),
        sin(mouse.y * PI / 2.),
        cos(an)
    ) * d;

       camTar = vec3(0);
}

vec3 doBackground(void) {
    return vec3(0.0);
}

vec3 doMaterial(in vec3 pos, in vec3 nor) {
    return vec3(0.25);
}

float doRulerModel(vec3 p) {
    return 1000.0;
    float t = 0.1;
    return abs(p.y) - mod(t/5., 1.);
}

float rule(float d, float scale) {
    return mix(1., .35, smoothstep(.6, 1., abs(fract(d * scale) * 2. - 1.)));
}

vec3 rulerColor(float t) {
    t = clamp(log(t+1.0), 0.0, 1.0);
    return mix(mix(vec3(0.,.1,1.), vec3(1.,.1,0.), t*5.), vec3(1.0), smoothstep(.2,.5,t));
}

vec3 doRulerMaterial(vec3 p, float d, float t) {
    float lt = log(t) / log(10.0);
    float s = pow(10.0, -floor(lt));
    float m = smoothstep(0.0, 0.33, fract(lt));
    float r = rule(d, s * 10.) * mix(rule(d, s * 100.0), rule(d, s), m);
    return mix(rulerColor(s * d), rulerColor(s * d * 0.1), m) * 0.8 * r;
}

float doCombinedModels(vec3 p) {
    return min(doModel(p), doRulerModel(p));
}

float calcSoftshadow(in vec3 ro, in vec3 rd);

vec3 doLighting(in vec3 pos, in vec3 nor, in vec3 rd, in float dis, in vec3 mal) {
    vec3 lin = vec3(0.0);

    // key light
    //-----------------------------
    //vec3 lig = normalize(vec3(1.1, 0.7, 0.9));
    vec3 lig = normalize(vec3(0.0,1.0,0.8)); 
    float dif = max(dot(nor, lig), 0.0);
    float sha = 0.0;
    if (dif > 0.01) sha = calcSoftshadow(pos + 0.01 * nor, lig);
    lin += dif * vec3(2.) * sha;

    // ambient light
    //-----------------------------
    //lin += vec3(0.5);

    // surface-light interacion
    //-----------------------------
    vec3 col = mal * lin;

    // fog
    //-----------------------------
    //col *= exp(-0.01 * dis * dis);

    //Specular
    float nrm = (60.0 + 8.0) / (3.1415 * 8.0);
    col += pow(max(dot(reflect(rd,nor),lig),0.0),60.0) * nrm;
 
//////experiment
    
    float fresnel = 1.0 - max(dot(nor,rd),0.0);
    fresnel = pow(fresnel,3.0) * 0.65;
    
    //sky color
    vec3 e = reflect(rd,nor);
    
    e.y = max(e.y,0.0);
    vec3 ret;
    ret.x = pow(1.0-e.y,2.0);
    ret.y = 1.0-e.y;
    ret.z = 0.6+(1.0-e.y)*0.4;
    //Reflected
    vec3 reflected = ret*0.05;

    //Sea color
    vec3 base = vec3(0.03,0.01,0.01);
    vec3 scolor = vec3(0.1,0.04,0.0);

    float diffuse = pow(dot(nor,lig) * 0.4 + 0.6,80.0)*200.0;
      
    //Refracted
    vec3 refracted = base + diffuse * scolor * 0.32; 
    
    //Experiment - overwrite color
    col = mix(refracted,col,fresnel);    
    
    //
    
    return col;
}

vec3 calcIntersection(in vec3 ro, in vec3 rd) {
    const float maxd = 100.0;    // max trace distance
    const float precis = 0.00001; // precission of the intersection
    vec3 p;
    float h = precis * 2.0;
    float d, r;
    float t = 0.0;
    float res = -1.0;
    for (int i = 0; i < 90; i++) // max number of raymarching iterations is 90
    {
        if (h < precis || t > maxd) break;
        p = ro + rd * t;
        r = doRulerModel(p);
        d = doModel(p);
        h = min(d, r);
        t += h;
    }

    if (t < maxd) res = t;
    return vec3(res, r < d ? 1.0 : 0.0, d);
}

vec3 calcNormal(in vec3 pos) {
    const float eps = 0.002; // precision of the normal computation

    const vec3 v1 = vec3(1.0, -1.0, -1.0);
    const vec3 v2 = vec3(-1.0, -1.0, 1.0);
    const vec3 v3 = vec3(-1.0, 1.0, -1.0);
    const vec3 v4 = vec3(1.0, 1.0, 1.0);

    return normalize(v1 * doCombinedModels(pos + v1 * eps) + 
                     v2 * doCombinedModels(pos + v2 * eps) +
                     v3 * doCombinedModels(pos + v3 * eps) + 
                     v4 * doCombinedModels(pos + v4 * eps));
}

float calcSoftshadow(in vec3 ro, in vec3 rd) {
    float res = 1.0;
    float t = 0.0005; // selfintersection avoidance distance
    float h = 1.0;
    for (int i = 0; i < 40; i++) { // 40 is the max numnber of raymarching steps
        h = doModel(ro + rd * t);
        res = min(res, 64.0 * h / t); // 64 is the hardness of the shadows
        t += clamp(h, 0.01, 2.0);     // limit the max and min stepping distances
    }
    return clamp(res, 0.0, 1.0);
}

mat3 calcLookAtMatrix(in vec3 ro, in vec3 ta, in float roll) {
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(sin(roll), cos(roll), 0.0)));
    vec3 vv = normalize(cross(uu, ww));
    return mat3(uu, vv, ww);
}

/*
"Seascape" by Alexander Alekseev aka TDM - 2014
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Contact: tdmaav@gmail.com
*/

const int NUM_STEPS = 4;
//const float PI         = 3.1415;
const float EPSILON    = 1e-3;
float EPSILON_NRM;

// sea
const int ITER_GEOMETRY = 1; //3
const int ITER_FRAGMENT = 4; //5
const float SEA_HEIGHT = 0.6;
const float SEA_CHOPPY = 4.0;
const float SEA_SPEED = 0.8;
const float SEA_FREQ = 0.16;
const vec3 SEA_BASE = vec3(0.03,0.01,0.01);
const vec3 SEA_WATER_COLOR = vec3(0.1,0.04,0.0);
float SEA_TIME;
mat2 octave_m = mat2(1.6,1.2,-1.2,1.6);

// math
mat3 fromEuler(vec3 ang) {
    vec2 a1 = vec2(sin(ang.x),cos(ang.x));
    vec2 a2 = vec2(sin(ang.y),cos(ang.y));
    vec2 a3 = vec2(sin(ang.z),cos(ang.z));
    mat3 m;
    m[0] = vec3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
    m[1] = vec3(-a2.y*a1.x,a1.y*a2.y,a2.x);
    m[2] = vec3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
    return m;
}
float hash( vec2 p ) {
    float h = dot(p,vec2(127.1,311.7));    
    return fract(sin(h)*43758.5453123);
}
float noise( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );    
    vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

// lighting
float diffuse(vec3 n,vec3 l,float p) {
    return pow(dot(n,l) * 0.4 + 0.6,p)*200.0;
}
float specular(vec3 n,vec3 l,vec3 e,float s) {    
    float nrm = (s + 8.0) / (3.1415 * 8.0);
    return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
}

// sky
vec3 getSkyColor(vec3 e) {
    e.y = max(e.y,0.0);
    vec3 ret;
    ret.x = pow(1.0-e.y,2.0);
    ret.y = 1.0-e.y;
    ret.z = 0.6+(1.0-e.y)*0.4;
    return ret*0.05;
}

// sea
float sea_octave(vec2 uv, float choppy) {
    uv += noise(uv);        
    vec2 wv = 1.0-abs(sin(uv));
    vec2 swv = abs(cos(uv));    
    wv = mix(wv,swv,wv);
    return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
}

float map(vec3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    vec2 uv = p.xz; uv.x *= 0.75;
    
    float d, h = 0.0;    
    for(int i = 0; i < ITER_GEOMETRY; i++) {        
        d = sea_octave((uv+SEA_TIME)*freq,choppy);
        d += sea_octave((uv-SEA_TIME)*freq,choppy);
        h += d * amp;        
        uv *= octave_m; freq *= 1.9; amp *= 0.22;
        choppy = mix(choppy,1.0,0.2);
    }
    return p.y - h;
}

float map_detailed(vec3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    vec2 uv = p.xz; uv.x *= 0.75;
    
    float d, h = 0.0;    
    for(int i = 0; i < ITER_FRAGMENT; i++) {        
        d = sea_octave((uv+SEA_TIME)*freq,choppy);
        d += sea_octave((uv-SEA_TIME)*freq,choppy);
        h += d * amp;        
        uv *= octave_m; freq *= 1.9; amp *= 0.22;
        choppy = mix(choppy,1.0,0.2);
    }
    return p.y - h;
}

vec3 getSeaColor(vec3 p, vec3 n, vec3 l, vec3 eye, vec3 dist) {  
    float fresnel = 1.0 - max(dot(n,-eye),0.0);
    fresnel = pow(fresnel,3.0) * 0.65;
        
    vec3 reflected = getSkyColor(reflect(eye,n));    
    vec3 refracted = SEA_BASE + diffuse(n,l,80.0) * SEA_WATER_COLOR * 0.12; 
    
    vec3 color = mix(refracted,reflected,fresnel);
    
    float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
    color += SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * 0.18 * atten;
    
    color += vec3(specular(n,l,eye,60.0));
    
    return color;
}

// tracing
vec3 getNormal(vec3 p, float eps) {
    vec3 n;
    n.y = map_detailed(p);    
    n.x = map_detailed(vec3(p.x+eps,p.y,p.z)) - n.y;
    n.z = map_detailed(vec3(p.x,p.y,p.z+eps)) - n.y;
    n.y = eps;
    return normalize(n);
}

float heightMapTracing(vec3 ori, vec3 dir, out vec3 p) {  
    float tm = 0.0;
    float tx = 1000.0;    
    float hx = map(ori + dir * tx);
    if(hx > 0.0) return tx;   
    float hm = map(ori + dir * tm);    
    float tmid = 0.0;
    for(int i = 0; i < NUM_STEPS; i++) {
        tmid = mix(tm,tx, hm/(hm-hx));                   
        p = ori + dir * tmid;                   
        float hmid = map(p);
        if(hmid < 0.0) {
            tx = tmid;
            hx = hmid;
        } else {
            tm = tmid;
            hm = hmid;
        }
    }
    return tmid;
}

// main
void main(void) {
    EPSILON_NRM    = 0.1 / resolution.x;
    SEA_TIME = time * SEA_SPEED;

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;    
    float time2 = time * 0.3 + mouse.x*resolution.x*0.01;
        
    // ray
    //vec3 ang = vec3(sin(time*3.0)*0.1,sin(time)*0.2+0.3,time);   
    vec3 ang = vec3(0.0, 0.3, 0.0);
    vec3 ori = vec3(0.0,4.5, 7.0);
    vec3 dir = normalize(vec3(uv.xy,-2.0)); dir.z += length(uv) * 0.15;
    dir = normalize(dir) * fromEuler(ang);

    //360 camera
//   vec2 texCoord = gl_FragCoord.xy / resolution.xy; 
//    vec2 thetaphi = ((texCoord * 2.0) - vec2(1.0)) * vec2(3.1415926535897932384626433832795, 1.5707963267948966192313216916398); 
//    dir = vec3(cos(thetaphi.y) * cos(thetaphi.x), sin(thetaphi.y), cos(thetaphi.y) * sin(thetaphi.x));

    
    // tracing
    vec3 p;
    heightMapTracing(ori,dir,p);
    vec3 dist = p - ori;
    vec3 n = getNormal(p, dot(dist,dist) * EPSILON_NRM);
    vec3 light = normalize(vec3(0.0,1.0,0.8)); 
  
    
        //
    
    // color
    vec3 color = mix(
        getSkyColor(dir),
        getSeaColor(p,n,light,dir,dist),
        pow(smoothstep(0.0,-0.05,dir.y),0.3));
    
    //

    vec3 t = calcIntersection(ori, dir);
    if (t.x > -0.5) {
        // geometry
        vec3 pos = ori + t.x * dir;
        vec3 nor = calcNormal(pos);

        // materials
        vec3 mal;
        if (t.y > 0.) {
            mal = doRulerMaterial(pos, t.z, t.x);
            //mal = doLighting(pos, nor, rd, t.x, mal);
        } else {
            mal = doMaterial(pos, nor);
        }
        
        color = doLighting(pos, nor, dir, t.x, mal);
    }
        
    // post
    glFragColor = vec4(pow(color,vec3(0.75)), 1.0);
}
