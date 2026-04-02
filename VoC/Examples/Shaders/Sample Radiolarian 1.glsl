#version 420

// original https://www.shadertoy.com/view/Mdt3RX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PHI (sqrt(5.)*0.5 + 0.5)
#define PI 3.14159265

#define t time

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
    return vec3(.5);
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
    vec3 lig = normalize(vec3(1.1, 0.7, 0.9));
    float dif = max(dot(nor, lig), 0.0);
    float sha = 0.0;
    if (dif > 0.01) sha = calcSoftshadow(pos + 0.01 * nor, lig);
    lin += dif * vec3(2.) * sha;

    // ambient light
    //-----------------------------
    lin += vec3(0.5);

    // surface-light interacion
    //-----------------------------
    vec3 col = mal * lin;

    // fog
    //-----------------------------
    col *= exp(-0.01 * dis * dis);

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

void main(void) {
    vec2 p = (-resolution.xy + 2.0 * gl_FragCoord.xy) / resolution.y;
    vec2 m = mouse*resolution.xy.xy / resolution.xy;

    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------

    // camera movement
    vec3 ro, ta;
    doCamera(ro, ta, time, m);

    // camera matrix
    mat3 camMat = calcLookAtMatrix(ro, ta, 0.0); // 0.0 is the camera roll

    // create view ray
    vec3 rd = normalize(camMat * vec3(p.xy, 2.0)); // 2.0 is the lens length

    //-----------------------------------------------------
    // render
    //-----------------------------------------------------

    vec3 col = doBackground();

    // raymarch
    vec3 t = calcIntersection(ro, rd);
    if (t.x > -0.5) {
        // geometry
        vec3 pos = ro + t.x * rd;
        vec3 nor = calcNormal(pos);

        // materials
        vec3 mal;
        if (t.y > 0.) {
            mal = doRulerMaterial(pos, t.z, t.x);
            //mal = doLighting(pos, nor, rd, t.x, mal);
        } else {
            mal = doMaterial(pos, nor);
        }
        
        //col = doLighting(pos, nor, rd, t.x, mal);
          col = vec3(0.5) + nor * 0.5;
    }

    //-----------------------------------------------------
    // postprocessing
    //-----------------------------------------------------

    // gamma
    //col = pow(clamp(col, 0.0, 1.0), vec3(0.4545));
    glFragColor = vec4(col, 1.0);
}
