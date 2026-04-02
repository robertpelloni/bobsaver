#version 420

// original https://www.shadertoy.com/view/Nt2XRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 2
//#define ORTHO

const float FOV = radians(45.);
const float ORTHO_SIZE = 12.;

const float PI = 3.1415927;
const float PHI = (1.+sqrt(5.))/2.;

#define clamp01(x) clamp(x, 0., 1.)

struct DistId {
    float dist;
    int matId;
};

struct Material {
    vec3 diff_color;
    vec3 spec_color;
    float shininess;
};

float sdPlane(vec3 pos, vec3 norm, float d) {
    return dot(pos, norm) - d;
}

float sdPlaneN(vec3 pos, vec3 norm, float d) {
    return (dot(pos, norm) - d) / length(norm);
}

float sdSphere(vec3 pos, float radius) {
    return length(pos) - radius;
}

float sdBox(vec3 pos, vec3 bounds) {
    return length(max(abs(pos) - bounds, 0.));
}

float sdTetrahedron(vec3 pos, float r) {
    pos.xz = abs(pos.xz);
    vec3 n = normalize(vec3(0, sqrt(.5), 1));
    return max(sdPlane(pos, n.xyz, r),
               sdPlane(pos, n.zyx*vec3(1,-1,1), r));
}

float sdOctahedron(vec3 pos, float r) {
    return sdPlane(abs(pos), normalize(vec3(1)), r);
}

float sdDodecahedron(vec3 pos, float r) {
    pos = abs(pos);
    vec3 n = normalize(vec3(0, 1, PHI));
    float d =  sdPlane(pos, n.xyz, r);
    d = max(d, sdPlane(pos, n.yzx, r));
    d = max(d, sdPlane(pos, n.zxy, r));
    return d;
}

float sdIcosahedron(vec3 pos, float r) {
    pos = abs(pos);
    vec3 n = normalize(vec3(0, 1./PHI, PHI));
    float d =  sdPlane(pos, normalize(vec3(1)), r);
    d = max(d, sdPlane(pos, n.xyz, r));
    d = max(d, sdPlane(pos, n.yzx, r));
    d = max(d, sdPlane(pos, n.zxy, r));
    return d;
}

float sdRhombicDodecahedron(vec3 pos, float r) {
    pos = abs(pos);
    vec3 n = normalize(vec3(1, 1, 0));
    float d =  sdPlane(pos, n.xyz, r);
    d = max(d, sdPlane(pos, n.yzx, r));
    d = max(d, sdPlane(pos, n.zxy, r));
    return d;
}

float sdRhombicuboctahedron(vec3 pos, float r) {
    pos = abs(pos);
    vec3 n = normalize(vec3(1, 1, 0));
    float d = max(max(pos.x, pos.y), pos.z) - r;
    d = max(d, sdPlane(pos, n.xyz, r));
    d = max(d, sdPlane(pos, n.yzx, r));
    d = max(d, sdPlane(pos, n.zxy, r));
    d = max(d, sdPlaneN(pos, vec3((2.*sqrt(2.)+1.)/7.), r));
    return d;
}

float sdCuboctahedron(vec3 pos, float r) {
    pos = abs(pos);
    vec3 n = vec3(1, 0, 0);
    float d =  sdPlaneN(pos, vec3(.5), r);
    d = max(d, sdPlane(pos, n.xyz, r));
    d = max(d, sdPlane(pos, n.yzx, r));
    d = max(d, sdPlane(pos, n.zxy, r));
    return d;
}

float opUnion(float a, float b) {
    return min(a, b);
}

float opIntersect(float a, float b) {
    return max(a, b);
}

float opSubtract(float a, float b) {
    return max(a, -b);
}

DistId opUnion(DistId a, DistId b) {
    if (a.dist < b.dist)
        return a;
    else
        return b;
}

Material getMaterial(int matId) {
    switch (matId) {
    case 0:
        return Material(vec3(.5), vec3(.8), 35.);
    case 1:
        return Material(vec3(1, 0, 0)*.9, vec3(.8), 20.);
    case 2:
        return Material(vec3(0, 1, 0)*.9, vec3(.8), 20.);
    case 3:
        return Material(vec3(0, 0, 1)*.9, vec3(.8), 20.);
    case 4:
        return Material(vec3(0, .9, 1), vec3(.8), 15.);
    case 5:
        return Material(vec3(1, 0, 1), vec3(.8), 15.);
    case 6:
        return Material(vec3(1, .8, 0), vec3(.8), 15.);
    case 7:
        return Material(vec3(.4, 0, 1), vec3(.8), 15.);
    case 8:
        return Material(vec3(1, .3, 0), vec3(.8), 15.);
    case 9:
        return Material(vec3(0, .3, 1), vec3(.8), 15.);
    default:
        return Material(vec3(.25), vec3(0), 0.);
    }
}

DistId map(vec3 pos) {
    DistId res = DistId(sdPlane(pos, vec3(0,1,0), -6.), 0);
    res = opUnion(res, DistId(sdBox(pos - vec3(-16,0,8), vec3(3)), 6));
    res = opUnion(res, DistId(sdTetrahedron(pos - vec3(0,0,8), 2.), 9));
    res = opUnion(res, DistId(sdOctahedron(pos - vec3(16,0,8), 3.), 8));
    res = opUnion(res, DistId(sdIcosahedron(pos - vec3(-8,0,0), 4.), 1));
    res = opUnion(res, DistId(sdDodecahedron(pos - vec3(8,0,0), 4.), 3));
    res = opUnion(res, DistId(sdRhombicDodecahedron(pos - vec3(-16,0,-8), 4.), 2));
    res = opUnion(res, DistId(sdRhombicuboctahedron(pos - vec3(0,0,-8), 4.), 7));
    res = opUnion(res, DistId(sdCuboctahedron(pos - vec3(16,0,-8), 4.), 4));
    // res = opUnion(res, DistId(sdSphere(abs(pos) - vec3(16,0,4), 4.01), 7));
    return res;
}

DistId castRay(vec3 origin, vec3 dir) {
    float minDist = 1.;
    float maxDist = 100.;

    float t = minDist;
    int matId = -1;
    for (int i=0; i<128; i++) {
        float eps = 1e-4*t;
        DistId res = map(origin + dir*t);
        matId = res.matId;
        if (res.dist < eps || t > maxDist) break;
        t += res.dist;
    }
    if (t > maxDist)
        matId = -1;
    return DistId(t, matId);
}

vec3 calcNormal(vec3 pos) {
    vec2 e = vec2(1.0, -1.0) * 1e-3;
    return normalize(e.xyy * map(pos + e.xyy).dist +
                     e.yxy * map(pos + e.yxy).dist +
                     e.yyx * map(pos + e.yyx).dist +
                     e.xxx * map(pos + e.xxx).dist);
}

vec3 shade(vec3 origin, vec3 dir, float dist, int matId) {
    vec3 pos = origin + dist*dir;
    vec3 normal = calcNormal(pos);
    Material mat = getMaterial(matId);
    float ambient = .12*(1.0 + .6*normal.y);
    
    vec3 light1 = normalize(vec3(1, 1, .75));
    float diffuse = clamp01(dot(normal, light1));
    float specular = pow(clamp01(dot(reflect(-light1, normal), -dir)), mat.shininess);

    vec3 light2 = normalize(vec3(1, .5, -2));
    diffuse += .8 * clamp01(dot(normal, light2));
    specular += .8 * pow(clamp01(dot(reflect(-light2, normal), -dir)), mat.shininess);

    float total = diffuse + ambient;
    vec3 col = clamp01(total)*mat.diff_color;
    col += clamp01(specular)*mat.spec_color;
    return clamp01(col);
}

vec3 render(vec3 origin, vec3 dir) {
    vec3 col = vec3(.5, .8, 1.)*(1.+1.5*dir.y);
    DistId res = castRay(origin, dir);
    if (res.matId >= 0) {
        col = shade(origin, dir, res.dist, res.matId);
    }
    return col;
}

mat3 lookAt(vec3 cameraPos, vec3 center, vec3 up) {
    vec3 forward = normalize(center - cameraPos);
    vec3 right = normalize(cross(forward, up));
    up = normalize(cross(right, forward));
    return mat3(right, up, forward);
}

void main(void)
{
    vec2 mouse = mouse*resolution.xy.xy == vec2(0) ?
        vec2(0,-.4) : (2.*mouse*resolution.xy.xy - resolution.xy) / resolution.xy;

    float r = 35.;
    float theta = 2.*PI*(time/10. + mouse.x*.5 + .25);
    float phi = -mouse.y*PI/2.;
    vec3 cameraPos = vec3(r*cos(theta)*cos(phi), r*sin(phi), r*sin(theta)*cos(phi));
    vec3 center = vec3(0, 0, 0);
    mat3 cameraRot = lookAt(cameraPos, center, vec3(0, 1, 0));

    float screenDist = 1. / tan(FOV/2.);

    vec3 col = vec3(0);
    for (int i=0; i<AA; i++) {
        for (int j=0; j<AA; j++) {
            vec2 pix = gl_FragCoord.xy + (vec2(i, j)+.5)/float(AA) - .5;
            vec2 uv = (2.*pix - resolution.xy) / resolution.y;
            #ifdef ORTHO
            vec3 rayPos = cameraPos + cameraRot * vec3(uv, 0) * ORTHO_SIZE;
            vec3 rayDir = cameraRot * vec3(0, 0, 1);
            #else
            vec3 rayPos = cameraPos;
            vec3 rayDir = cameraRot * normalize(vec3(uv, screenDist));
            #endif
            col += render(rayPos, rayDir);
        }
    }
    col /= float(AA*AA);

    // gamma
    col = pow(col, vec3(1./2.2));

    glFragColor = vec4(col, 1.0);
}
