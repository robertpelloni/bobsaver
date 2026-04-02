#version 420

#define MAX_STEPS 100
#define MIN_DIST 0.001
#define MAX_DIST 100.0

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define clampLimit(A) clamp(A, 0.0, 1.0);

float golden = (1.0 + sqrt(5.0)) / 2.0;

float SphereSDF(vec3 point, float radius) {
    return length(point) - radius;
}

vec3 CyclicPermutation(vec4 v, int n) {
    if (n == 0) {
    return v.xyz;
    }
    else if (n == 1) {
    return v.zxy;
    }
    else {
    return v.yzx;
    }
}

float SmoothSubstraction(float d1, float d2, float k) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h);
}

vec3 spheres[12];

float MapPikes(vec3 position, float scale) {
    float sphere0 = SphereSDF(position - vec3(0, 0, 0), golden / scale);
    float minDist = sphere0;

    mat4 icosahedron = mat4(vec4(0, 1, golden, 0),
                    vec4(0, -1, golden, 0),
                    vec4(0, 1, -golden, 0),
                    vec4(0, -1, -golden, 0));

    float subSize = 1.2 / scale;
    for (int i = 0; i < 4; ++i) {    
    for (int j = 0; j < 3; ++j) {
        spheres[i * 3 + j] = CyclicPermutation(icosahedron[i], j);
        float sphere = SphereSDF(position - spheres[i * 3 + j] / scale, subSize);
        minDist = max(minDist, SmoothSubstraction(sphere, sphere0, 0.1));
        /*float sphere1 = SphereSDF(position - CyclicPermutation(vec3(1,0,0), j), subSize);
        float sphere2 = SphereSDF(position - CyclicPermutation(vec3(-1,0,0), j), subSize);
        minDist = max(minDist, SmoothSubstraction(sphere1, sphere0, 0.1));
        minDist = max(minDist, SmoothSubstraction(sphere2, sphere0, 0.1));*/
    }
    }
    
    float centerSphere = SphereSDF(position, golden / (2.0 * scale));
    minDist = max(minDist, SmoothSubstraction(centerSphere, sphere0, 0.1));

    return minDist;
}

float Map(vec3 position) {
    float ground = position.y + 3.0;
    float minDist = MapPikes(position, clamp(1.0 * abs(sin(time * .8) + 1.5),1.0,1.5));

    for (int i = 0; i < 12; ++i) {
        float outSphere = SphereSDF(position - spheres[i]/(2.0 * clamp(1.0 * abs(sin(time * .8) + 1.5),0.0,1.0)), 0.3 * clamp(abs(cos(time * .8) + 1.5),0.0,1.0));
        minDist = min(minDist, outSphere);
    }

    /*for (int i = 0; i < 13; ++i) {
    float outSphere = SphereSDF(position - spheres[i]/2., .2);
    minDist = min(minDist, outSphere);
    }*/
    
    return min(minDist, ground);
}

float RayMarch(vec3 ro, vec3 rd) {
    float distCamera = 0.0;

    for (int i = 0; i < MAX_STEPS; ++i) {
        float distScene = Map(ro + rd * distCamera);
        distCamera += distScene;
        if (distScene < MIN_DIST || distCamera > MAX_DIST) break;
    }

    return distCamera;
}

vec3 GetNormal(vec3 point) {
    float d = Map(point);
    vec2 e = vec2(.01, 0);

    vec3 n = d - vec3(Map(point - e.xyy),
                      Map(point - e.yxy),
                      Map(point - e.yyx));

    return normalize(n);
}

float GetShadow(vec3 ro, vec3 rd) {
    float res = 1.0;
    float ph = 1e20;
    float k = 32.0;
    float t = .5;
    for (int i = 0; i < MAX_STEPS; ++i) {
    float h = Map(ro + rd * t);
    if (h < MIN_DIST) return 0.0;
    float y = h * h / (2.0 * ph);
    float d = sqrt(h * h - y * y);
    res = min(res, k * d / max(0.0, t - y));
    ph = h;
    t += h;
    }
    return res;
}

vec3 GetLight(vec3 ro, vec3 rd, vec3 point) {
    vec3 lightPosition = normalize(vec3(0, 5, 0) - point);
    vec3 pointNormal = GetNormal(point);

    float diffuse = clamp(dot(pointNormal, lightPosition), 0.0, 1.0) * 0.5;
    
    vec3 hal = normalize(lightPosition - rd);
    float spe = pow(clamp(dot(pointNormal, hal), 0.0, 1.0), 64.0) * diffuse * 32.0 * (0.04 + 0.96 * pow(clamp(1.0 + dot(hal, rd), 0.0, 1.0), 5.0));   
    diffuse += spe;

    float softShadow = GetShadow(point, lightPosition);
    //diffuse *= softShadow;
    
    vec3 reflectionNormal = normalize(reflect(rd, pointNormal));
    float reflection = clampLimit(RayMarch(point + pointNormal * .1, reflectionNormal));
    //diffuse += reflection * 0.35;

    return vec3(diffuse);
}

vec3 render(vec2 uv) {
    vec3 ro = vec3(5.0 * sin(time), 1, -5.0 * cos(time));
    float zoom = 1.0;
    vec3 lookat = vec3(0, 0.0, 0.0);
    vec3 f = normalize(lookat - ro);
    vec3 r = normalize(cross(vec3(0, 1.0, 0), f));
    vec3 u = cross(f, r);
    vec3 c = ro + f * zoom;
    vec3 i = c + uv.x * r + uv.y * u;
    vec3 rd = i - ro;

    float dist = RayMarch(ro, rd);
    return GetLight(ro, rd, ro + rd * dist);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    vec3 col = render(uv);
    glFragColor = vec4(col, 1.);
}
