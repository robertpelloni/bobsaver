#version 420

// original https://www.shadertoy.com/view/WldBW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_COUNT (150)
#define MIN_DIST (0.001)
#define MAX_DIST (3.)

#define SOUL_SIZE (0.2)

#define M_SOUL_BODY 1
#define C_SOUL_BODY (vec3(0.24, 0.97, 0.37) + 0.2)
#define M_SOUL_EYE 2
#define C_SOUL_EYE (vec3(1.))
#define M_SOUL_EYEBALL 3
#define C_SOUL_EYEBALL (vec3(0.1))
#define M_SOUL_EYEBROW 4
#define C_SOUL_EYEBROW (vec3(0.2, 0.4, 0.4))
#define M_SOUL_CHEEK 5
#define C_SOUL_CHEEK (vec3(0.74, 0.57, 0.17))
#define M_TREE 6
#define C_TREE (vec3(0.6, 0.2, 0.6) * 0.9)

#define M_TERRAIN 10
#define C_TERRAIN (vec3(0.1, 0.6, 1.7))
#define M_GRASS 11
#define C_GRASS1 (vec3(1.24, 4.97, 3.37))
#define C_GRASS (vec3(3.9, 0.37, 3.9))

#define C_SKY_UP (vec3(0.29, 0.44, 1.56))
#define C_SKY_DOWN (vec3(4.5, 0.94, 4.57))

struct M {
    vec3 emission;
    vec3 diffuse;
};

float noise(in vec2 uv) {
    return fract(sin(uv.x * 1233.52 + uv.y * 99.23423) * 324.234);
}

float noiseSmooth(in vec2 uv) {
    vec2 uvs = floor(uv);
    vec2 d = fract(uv);
    vec2 s = vec2(1., 0.);
    float tl = noise(uvs);
    float tr = noise(uvs + s.xy);
    float bl = noise(uvs + s.yx);
    float br = noise(uvs + s.xx);
    float top = mix(tl, tr, d.x);
    float bottom = mix(bl, br, d.x);
    float mx = mix(top, bottom, d.y);
    return max(0., mx);
}

float rayPlane(vec3 ro, vec3 rd, vec3 n, float d) {
    float denom = dot(n, rd);
    if (abs(denom) > 1e-6) {
        return dot(n*d - ro, n) / denom;
    }
    return -1.;
}

float smin(float a, float b, float k) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}

vec3 ACESFilm(vec3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0., 1.);
}

float getSoulCurve(in float time) {
    return cos(time) * 0.5 + 0.5;
}

float sdSoulHead(in vec3 p, in float size, in float curve) {
    float d;
    vec3 mir = p * vec3(sign(p.x), 1., 1.);

    float lowSphere = length((p) * vec3(1., 1.7, 1.) - vec3(0., -0.5, 0.) * size) - size;
    float hiSphere = length(p * vec3(1., 1.5, 1.) - vec3(0., 0.3, 0.) * size) - size * 0.9;
    float head = smin(lowSphere, hiSphere, 0.5 * size);
    d = head;
    
    float eye = length(mir - vec3(0.7, 0.15, -1.2) * size) - size * 0.33;
    d = smax(d, -eye, 0.4 * size);
    
    return d;
}

#define SEPOS (vec3(0.4, 0.05, -0.65))
float sdSoulEye(in vec3 p, in float size) {
    vec3 mir = p * vec3(sign(p.x), 1., 1.);
    return length(mir - vec3(0.4, 0.05, -0.65) * size) - size * 0.2;
}

float sdSoulEyebrow(in vec3 p, in float size, in float curve) {
    float jump = max(0., curve - 0.6);
    vec3 mir = p * vec3(sign(p.x), 1., 1.);
    return length((mir - vec3(0.4, 0.4 + jump * 1. * size, -.55) * size) * vec3(1., 5., 1.) ) - size * 0.2;
}

float sdSoulMouth(in vec3 p, in float size, in float curve) {
    return length((p - vec3(0., -0.3 + p.x*p.x*20., -0.9) * size) * vec3(1.2, mix(9., 3., curve), 1.)) - size * 0.2;
}

float sdBody(in vec3 p, in float size, in float curve) {
    p -= vec3(0., -1.4, 0.) * size;
    
    float spread = min(0., -cos((p.y / size) * 2.)) * mix(0.4, 0., curve) + 1.;
    float shrink = mix(1.4, 1., curve);
    p *= vec3(spread, shrink, spread);
    
    return max(
        smin(
            length(p.xz) - size * 0.3,
            length(p - vec3(0., -0.6, 0.) * size) - size * 0.5,
            0.35 * size
        ),
        length(p) - size * 0.8
    );
}

vec2 modSoul(in vec3 pOrig, in float size, in float time) {
    float curve = getSoulCurve(time);
    vec3 p = pOrig;
    
    float jump = max(0., curve - 0.6);
    
    p -= vec3(0., 2.1 + mix(-0.2, 0., curve) + jump, 0.) * size;
    
    float body = sdBody(p, size, curve);
    float head = sdSoulHead(p, size, curve);
    
    float cheekDot = abs(dot(
        normalize(p * vec3(sign(p.x), 1., 1.)), 
        normalize(vec3(0.8, -0.45, -1.))
    ));
    
    vec2 res = vec2(
        smin(head, body, 0.5 * size), 
        cheekDot > 0.988 ? M_SOUL_CHEEK : M_SOUL_BODY
    );
    
    
    
    float mouth = sdSoulMouth(p, size, curve);
    if (-mouth > res.x) { res = vec2(mouth, vec3(0.1)); }
    
    float eye = sdSoulEye(p, size);
    if (eye < res.x) { 
        vec3 eyePos = normalize(p * vec3(sign(p.x), 1., 1.) - SEPOS * size);
        bool ball = dot(eyePos, normalize(vec3(0.3, 0., -1.))) > 0.95;
        res = vec2(eye, ball ? M_SOUL_EYEBALL : M_SOUL_EYE); 
    }
    
    float eyebrow = sdSoulEyebrow(p, size, curve);
    if (eyebrow < res.x) { res = vec2(eyebrow, M_SOUL_EYEBROW); }
    
    return res;
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdTerr(vec3 p) {
    float cell = 0.01;
    p -= vec3(0., -0.01, 0.);
    vec2 fl = mod(p.xz, cell);
    vec3 rp = vec3(fl.x, p.y, fl.y) - vec3(cell, 0., cell) / 2.;
    
    vec2 corner = floor(p.xz / cell) * cell;
    
    float disp = noise(corner * 200.);
    disp = mix(-0.4, 0.05, disp);
    
    rp -= vec3(0., 0. + disp, 0.);
    
    float dist = sdSphere(
        rp * vec3(1., 0.1, 1.), 
        0.004
    );
    
    return min(p.y, dist);
}

float sdTree(vec3 p) {
    float r = 0.3;
    return sdSphere((p - vec3(0., r + 0.2, 0.)) * vec3(3., 1., 2.), r) * 0.8;
}

///
///
///

vec2 getDist(vec3 p, bool ignoreSouls) {
    vec2 res = vec2(MAX_DIST, -1.);
    
    vec2 temp;
    
    if (!ignoreSouls) {
        temp = modSoul(p - vec3(0., 0.03, 0.), SOUL_SIZE, time * 8.);
        if (temp.x < res.x) { res = temp; };
    }
    
    temp = vec2(sdTerr(p), M_GRASS);
    if (temp.x < res.x) { res = temp; }
    
    temp = vec2(sdTree(p - vec3(-0.95, sin(time) * 0.03, 0.5)), M_TREE);
    if (temp.x < res.x) { res = temp; }
    
    temp = vec2(sdTree((p - vec3(0.8, sin(time + 3.) * 0.03, 0.8)) * 1.2), M_TREE);
    if (temp.x < res.x) { res = temp; }
    
    temp = vec2(sdTree((p - vec3(0.7, sin(time * 2.) * 0.03 - 0.4, -0.5)) * 0.4), M_TREE);
    if (temp.x < res.x) { res = temp; }
    
    return res;
}

///
///
///

vec3 getNormal(vec3 p, bool ignoreSouls) {
    float dist = getDist(p, ignoreSouls).x;
    vec2 e = vec2(0.001, 0.);
    vec3 n = dist - vec3(
        getDist(p - e.xyy, ignoreSouls).x,
        getDist(p - e.yxy, ignoreSouls).x,
        getDist(p - e.yyx, ignoreSouls).x);
    return normalize(n);
}

vec2 rayCast(vec3 ro, vec3 rd, bool ignoreSouls) {
    float total = 0.;
    
    for (int i = 0; i < MAX_COUNT; ++i) {
        vec2 hit = getDist(ro + rd * total, ignoreSouls);
        float d = hit.x;
        total += d;
        if ((d) < MIN_DIST) return vec2(total, hit.y);
        if (total > MAX_DIST) return vec2(total, -1.);
    }
    
    return vec2(MAX_DIST + 1., -1.);
}

M getMaterial(float m, vec3 rd, vec3 touch) {
    int im = int(m);
    vec3 z = vec3(0.);
    
    if (im == M_SOUL_BODY) return M(z, C_SOUL_BODY);
    if (im == M_SOUL_EYE) return M(z, C_SOUL_EYE);
    if (im == M_SOUL_EYEBALL) return M(z, C_SOUL_EYEBALL);
    if (im == M_SOUL_EYEBROW) return M(z, C_SOUL_EYEBROW);
    if (im == M_SOUL_CHEEK) return M(z, C_SOUL_CHEEK);
    
    if (im == M_GRASS) {
        float cell = 0.4;
        vec2 corner = floor(touch.xz / cell) * cell;
        float cf = noise(corner * 100.);
        vec3 col = mix(C_GRASS1, C_GRASS, cf);
        float f = clamp(touch.y, 0., 0.1) / 0.1;
        return M(z, mix(C_TERRAIN, col * 3., f));
    }
    
    if (im == M_TERRAIN) {
        return M(z, C_TERRAIN);
    }
    
    float angle = dot(rd, vec3(0., 1., 0.));
    float axis = dot(rd, vec3(-1., 0., 0.));
    
    float skypow = clamp(angle, 0., 1.);
    vec3 sky = mix(C_SKY_DOWN, C_SKY_UP, smoothstep(-0.3, 0.25, skypow));
    
    
    float mount;
    
    mount = (sin(axis * 5.5 + 2.5)) * 0.1 - 0.;
    mount = exp(-max(0., angle - mount)*25.);
    sky = mix(sky, vec3(0.6, 0.5, 4.9) * mix(0.5, 1., angle/0.2), mount);
    
    mount = (sin(axis * 6.) * 0.5 + 0.5) * 0.1 - 0.15;
    mount = exp(-max(0., angle - mount)*65.);
    sky = mix(sky, vec3(0.8, 0.9, 1.9) * mix(0.4, 0.3, angle/0.2), mount);
    
    mount = (sin(axis * 6.) * 0.5 + 0.5) * 0.1 - 0.23;
    mount = exp(-max(0., angle - mount)*65.);
    sky = mix(sky, vec3(3.4, 2.9, 1.9) * mix(0.4, 0.3, angle/0.2), mount);
    
    
    if (im == M_TREE) {
        return M(z, C_TREE);
    }
    
    return M(sky, z);
}

vec3 getLightWithPos(in vec3 lightPos, in vec3 lightCol, in vec3 p, in vec3 n, bool occlusion) {
    vec3 toLight = lightPos - p;
    vec3 nToLight = normalize(toLight);
    float dToLight = length(toLight);
    float pLight = max(0., dot(n, nToLight));
    if (occlusion) {
        float occlDist = rayCast(p + nToLight * 0.01, nToLight, false).x;
        pLight *= min(1., pow(occlDist / dToLight, 1.));
    }
    return pLight * lightCol;
}

vec3 getLight(in vec3 p, in vec3 n, bool occlusion) {
    return getLightWithPos(vec3(1., 1., -1.), vec3(1.3), p, n, occlusion) + 
        getLightWithPos(vec3(-1., 0.4, 1.), vec3(5., .2, .2) * 2., p, n, occlusion);
}

vec3 castToLight(in vec3 ro, in vec3 rd, out vec2 hit, out vec3 n, out vec3 touch, bool ignoreSouls) {
    vec3 col = vec3(0.);
    
    hit = rayCast(ro, rd, ignoreSouls);
    if (hit.x >= MAX_DIST) {
        return getMaterial(-1., rd, touch).emission;
    }
    
    touch = ro + rd * hit.x;
    M m = getMaterial(hit.y, rd, touch);
    
    vec3 ambient = C_SKY_UP;
    col += m.diffuse * ambient;
    
    vec3 lightPos = vec3(2., 1.5, -3.);
    vec3 lightCol = vec3(1.) * 2.;
    
    col += m.emission;
    
    if (length(m.diffuse) > 0.01) {
        n = getNormal(touch, ignoreSouls);
        col += m.diffuse * getLight(touch, n, true);
    }
    
    return col;
}

vec3 renderScene(in vec3 ro, in vec3 rd) {
    vec2 hit;
    vec3 n, touch;
    vec3 col = castToLight(ro, rd, hit, n, touch, false);
    
    int mid = int(hit.y);
    if (mid == M_SOUL_BODY || mid == M_SOUL_CHEEK) {
        float f = 1.-max(0., -dot(n, rd));
        f = clamp(f, 0.5, 0.8) - 0.5;
        f /= 0.3;
        if (f > 0.1) {
            vec3 sub = castToLight(ro, rd, hit, n, touch, true);
            col = mix(col, sub, f) * (1. - abs(n) * 0.3);
        }
    }
    
    if (mid == M_TREE) {
        vec3 sky = getMaterial(-1., rd, touch).emission;
        float f = 1.-max(0., -dot(n, rd));
        f = clamp(f, 0.0, 1.);
        f /= 0.9;
        f = max(0., f);
        col = mix(col, sky, f);
    }
    
    if (hit.x < MAX_DIST && touch.y < 0.1) {
        vec3 planeN = vec3(0., 1., 0.);
        float upDist = rayPlane(ro, rd, planeN, 0.1);
        if (upDist > 0.) {
            vec3 plane = ro + rd * upDist;
            float dist = length(plane - touch);
            
            float scaterring = 1. - exp(-dist * 10.);
            float absorbing = 1. - exp(-dist * 35.);
            
            vec3 diffuse = C_TERRAIN;
            
            col = mix(col, vec3(0.), absorbing) + 
                scaterring * diffuse * getLight(plane + 0.5 * dist * rd, planeN, false);
        }
    }
    
    if (hit.x < MAX_DIST && touch.y < 0.15) {
        vec3 planeN = vec3(0., 1., 0.);
        float upDist = rayPlane(ro, rd, planeN, 0.15);
        if (upDist > 0.) {
            vec3 plane = (ro + rd * upDist);
            
            vec3 diffuse = vec3(noiseSmooth(plane.xz * 9. + vec2(0., time * 0.3)));
            col += diffuse * 0.2 * getLight(plane, planeN, false);
            
        }
    }

    return col;
}

void main(void)
{

    vec2 vpShift = vec2(resolution.x/resolution.y, 1.);
    vec2 vp = gl_FragCoord.xy/resolution.y*2. - vpShift;
    
    float time = time * 0.5;
    vec3 origin = vec3(sin(time) * 0.2, 0.5, -2.);
    vec3 target = vec3(0., 0.4, 0.);
    vec3 up = vec3(0., 1., 0.);
     
    vec3 camForward = normalize(target - origin);
    vec3 camRight = normalize(cross(up, camForward));
    vec3 camUp = cross(camForward, camRight);
    
    vec3 ro = origin;
    vec3 rd = normalize(3. * camForward + camRight * 1. * vp.x + camUp * vp.y);

    vec3 col = renderScene(ro, rd);
    
    //glFragColor = vec4(col, 1.);
    glFragColor = vec4(ACESFilm(col), 1.);
}
