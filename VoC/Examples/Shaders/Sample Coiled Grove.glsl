#version 420

// original https://www.shadertoy.com/view/mstyR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define RES    (resolution.xy)
#define MINRES (min(RES.x, RES.y))

const vec3 vX = vec3(1.0, 0.0, 0.0);
const vec3 vY = vX.yxy;
const vec3 vZ = vX.yyx;
const vec3 v0 = vX.yyy;
const vec3 v1 = vX.xxx;

mat2 rot2(in float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c, s, -s, c);
}

float saturate(float v) { return clamp(v, 0.0, 1.0); }
vec2  saturate(vec2  v) { return clamp(v, 0.0, 1.0); }
vec3  saturate(vec3  v) { return clamp(v, 0.0, 1.0); }

float sqr(float a) {
    return a * a;
}

float sdSphere(in vec3 p, in float r) {
    return length(p) - r;
}

float sdDisk(in vec2 p, in float r) {
    return length(p) - r;
}

//--------------------------------------------------------------------------------

// iq
float smin(float a, float b, float k) {
    float h = max(k - abs(a-b), 0.) / k;
    return min(a, b) - h*h*h*k*1./6.;
}

//--------------------------------------------------------------------------------

// from https://www.cs.princeton.edu/courses/archive/fall00/cs426/lectures/raycast/sld017.htm
float rayVsPlane(in vec3 ro, in vec3 rd, in vec3 n, in float d) {
    float t = -(dot(ro, n) + d) / (dot(rd, n));
    if (t < 0.0) {
        t = 1e9;
    }
    return t;
}

//--------------------------------------------------------------------------------

const uint  march_MaxSteps  = 250u;
const float march_epsilon   = 0.01;
      float march_understep = 0.2;
const float normal_epsilon  = 0.05;

const bool  do_Shadows      = true;
const bool  do_Reflections  = true;

float gMapCount = 0.0;

float sdScene(in vec3 p) {

    gMapCount += 1.0;

    float d = 1e9;
    
    vec3 q = p;
        
    q.xz = abs(q.xz);
    q.xz -= 9.0;
    
    q.xz *= rot2(q.y * q.y * 0.006 - time * 0.1);
    q.xz *= 2.0 * (0.5 +  smoothstep(10.0, 50.0, q.y));
    
    q.xz = abs(q.xz);
    q.xz -= 4.0;

    q.xz *= rot2(q.y * 0.5  - time);
    q.x = abs(q.x);
    q.x -= 2.0 * smoothstep(1.0, 15.0, q.y);

    d = min(d, sdDisk(q.xz, 1.0));

    d = smin(d, p.y, 4.5);

    return d;
}

vec3 gradScene(in vec3 p) {
    if (p.y < march_epsilon) {
        // cheat for floor
        return vY;
    }
    float d = sdScene(p);
    return vec3(
        sdScene(p + vX * normal_epsilon) - d,
        sdScene(p + vY * normal_epsilon) - d,
        sdScene(p + vZ * normal_epsilon) - d
    );
}

vec3 normalScene(in vec3 p) {
    return normalize(gradScene(p));
}

float rayVsScene(in vec3 ro, in vec3 rd, out bool outOfSteps) {

    // analytic ground plane in addition to the raymarched one.
    float pt = rayVsPlane(ro, rd, vY, 0.0);
    
    outOfSteps = false;

    float t = 0.0;

    for (uint n = 0u; n < march_MaxSteps; ++n) {
        vec3  p = ro + t * rd;
        float d = sdScene(p);
        if (d < march_epsilon) {
            return min(pt, t);
        }
        if (dot(p.xz, p.xz) > 40000.0) {
            return pt;
        }
        
        t += d * march_understep;
    }
   
    // next time we call this, use less precision.
    march_understep = mix(march_understep, 1.0, 0.5);
    
    outOfSteps = true;
    return pt;
}

const vec3 lightDir = normalize(vec3(1.0, 1.5, 1.9));

vec3 sky(in vec3 ro, in vec3 rd) {
    vec3 c = v1 * (1.0 - (0.2 + 0.8 * saturate(rd.y)));
    c.r *= 0.2;
    c.g *= 0.4;
    
    float d = dot(rd, lightDir) * 0.5 + 0.5;
    
    c = mix(c, v1, sqr(sqr(sqr(d))) * 0.85);
    
    float a = atan(rd.z, rd.x);
    
    c = mix(c, v1, smoothstep(0.06 + (1.0 - d) * 0.01 * cos(a * 13.0), 0.0, abs(rd.y)));
    return c;
}

vec3 render(in vec3 ro, in vec3 rd) {
    bool outOfSteps;
    float t = rayVsScene(ro, rd, outOfSteps);
    if (t > 1e8) {
        return sky(ro, rd);
    }
    
    vec3 p;
    vec3 n;
    
    p = ro + t * rd;
    n = normalScene(p);
    
    vec3 c = v1 * (saturate(dot(n, lightDir)));

    // shadow and one reflection bounce
    ro = p + n * march_epsilon * 2.0;
    
    if (do_Shadows) {
        // shadow
        t = rayVsScene(ro, lightDir, outOfSteps);
        p = ro + t * lightDir;

        if (t < 1e9 || outOfSteps) {
            c *= 0.4;
        }
    }

    if (do_Reflections) {
        // reflect
        float fres = mix(0.01, 0.8, smoothstep(0.9, 0.1, abs(dot(rd, n))));

        vec3 c2;
        rd = reflect(rd, n);
        t = rayVsScene(ro, rd, outOfSteps);
        if (t > 1e8) {
            c2 = sky(ro, rd);
        }
        else {
            p = ro + t * rd;
            n = normalScene(p);
            c2 = v1 * (saturate(dot(n, lightDir)));
        }

        c = mix(c, c2, fres);
    }
    
    return c;
}

vec3 getRayDir(in vec2 xy, in vec3 ro, in vec3 lookTo, in float fov) {
    vec3 camFw = normalize(lookTo - ro);
    vec3 camRt = normalize(cross(camFw, vY));
    vec3 camUp = cross(camRt, camFw);
    
    vec3 rd;
    rd = camFw + fov * (camRt * xy.x + camUp * xy.y);
    rd = normalize(rd);
    
    return rd;
}

bool gHeatMap = false;

void main(void)
{
    vec2 XY = gl_FragCoord.xy;
    vec4 RGBA = vec4(0.0);
    
    const float zoom = 0.8;
    
    vec2 xy = (XY * 2.0 - RES) / MINRES / zoom;
    
    const float heatMapSize = 0.4;
    bool isHeatMap = gHeatMap && XY.x < RES.x * heatMapSize && XY.y < RES.y * heatMapSize;
    if (isHeatMap) {
        xy = (XY * 2.0 - RES * heatMapSize) / MINRES / heatMapSize / zoom;
    }
    
    //vec2 M = mouse*resolution.xy.xy;
    //if (length(M) < 100.0) {
        vec2 M = RES/2.0;
        M.x += time * 7.0;
    //}
    
    vec3 ro = vec3(0.0, 8.0, -30.0);
    ro.xz *= rot2(3.141 + (M.x / RES.x - 0.5) * -7.0);
    vec3 lt = vY * (0.0 - 20.0 * (M.y / RES.y - 1.0));
    vec3 rd = getRayDir(xy, ro, lt, 0.5);
    
    RGBA.rgb = render(ro, rd);
    
    if (isHeatMap) {
        float h = saturate(gMapCount / 500.0);
        vec3 cool = vec3(0.0, 0.0, 0.7);
        vec3 warm = vec3(1.0, 0.9, 0.0);
        RGBA.rgb = mix(cool, warm, h);
    }
    
    // gamma
    RGBA.rgb = pow(RGBA.rgb, vec3(1.0/2.2));
    
    RGBA.a   = 1.0;
    
    glFragColor = RGBA;
}