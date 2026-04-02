#version 420

// original https://www.shadertoy.com/view/tdyGRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_MARCHING_STEPS 255
#define MIN_DIST 0.0
#define MAX_DIST 100.0
#define EPSILON 0.0001
#define PI 3.1415926

mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

float dot2(vec2 v) {
    return dot(v, v);
}

float sdCappedCone(vec3 p, float h, float r1, float r2) {
    vec2 q = vec2(length(p.xz), p.y);

    vec2 k1 = vec2(r2, h);
    vec2 k2 = vec2(r2 - r1, 2.0 * h);
    vec2 ca = vec2(q.x - min(q.x,(q.y < 0.0) ? r1 : r2), abs(q.y) - h);
    vec2 cb = q - k1 + k2 * clamp(dot(k1 - q, k2) / dot2(k2), 0.0, 1.0);
    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
    return s*sqrt(min(dot2(ca), dot2(cb)));
}

float opSmoothUnion(float a, float b, float k) {
  float h = max(k - abs(a - b), 0.0 ) / k;
  return min(a, b) - h * h * h * k * (1.0 / 6.0);
}

float sceneSDF(vec3 p) {
  p = rotateY(time) * p;

  float s = sin(time * 2.) / 2. + 0.5;
  float t = smoothstep(0., 2., s);
  float l = 0.5 + s;
  float r = 0.4;

  float d = sdCappedCone(rotateX(radians(90.)) * p + vec3(0., -l, 0.), l, 0.4, 0.4 - s/2.);
  d = opSmoothUnion(d, sdCappedCone(rotateX(radians(-90.)) * p + vec3(0., -l, 0.), l, 0.4, 0.4 - s/2.), 0.1);

  for (int i = 0; i < 4; i++) {
    d = opSmoothUnion(d, sdCappedCone(rotateZ(radians(float(i) * 90.)) * p + vec3(0., -l, 0.), l, 0.4, 0.4 - s/2.), 0.1);
    d = opSmoothUnion(d, sdCappedCone(rotateZ(radians(float(i)*45.)) * rotateX(radians(45.)) * p + vec3(0., -l, 0.), l, 0.4, 0.4 - s/2.), 0.1);
    d = opSmoothUnion(d, sdCappedCone(rotateZ(radians(180. + float(i)*45.)) * rotateX(radians(45.)) * p + vec3(0., -l, 0.), l, 0.4, 0.4 - s/2.), 0.1);
    d = opSmoothUnion(d, sdCappedCone(rotateZ(radians(float(i)*45.)) * rotateX(radians(90. + 45.)) * p + vec3(0., -l, 0.), l, 0.4, 0.4 - s/2.), 0.1);
    d = opSmoothUnion(d, sdCappedCone(rotateZ(radians(180. + float(i)*45.)) * rotateX(radians(90. + 45.)) * p + vec3(0., -l, 0.), l, 0.4, 0.4 - s/2.), 0.1);
  }

  return d;
}

float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection);
        if (dist < EPSILON) {
            return depth;
        }
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
}

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

vec3 estimateNormal(vec3 p) {
    float pDist = sceneSDF(p);
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - pDist,
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - pDist,
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - pDist
    ));
}

vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye,
                          vec3 lightPos, vec3 lightIntensity) {
    vec3 N = estimateNormal(p);
    vec3 L = normalize(lightPos - p);
    vec3 V = normalize(eye - p);
    vec3 R = normalize(reflect(-L, N));

    float dotLN = dot(L, N);
    float dotRV = dot(R, V);

    if (dotLN < 0.0) {
        // Light not visible from this point on the surface
        return vec3(0.0, 0.0, 0.0);
    }

    if (dotRV < 0.0) {
        // Light reflection in opposite direction as viewer, apply only diffuse component
        return lightIntensity * (k_d * dotLN);
    }
    return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
}

vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye) {
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;

    vec3 light1Pos = vec3(-4.0,
                          2.0,
                          4.0);
    vec3 light1Intensity = vec3(0.4, 0.4, 0.4);

    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light1Pos,
                                  light1Intensity);

    vec3 light2Pos = vec3(2.0,
                          2.0,
                          2.0);
    vec3 light2Intensity = vec3(0.4, 0.4, 0.4);

    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light2Pos,
                                  light2Intensity);
    return color;
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    // Based on gluLookAt man page
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

void main(void) {
    vec3 viewDir = rayDirection(45.0, resolution.xy);
    vec3 eye = vec3(8.0, 5.0 * sin(0.2 * time), 7.0);
    mat3 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    vec3 worldDir = viewToWorld * viewDir;
    
    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
    
    if (dist > MAX_DIST - EPSILON) { // Didn't hit anything
         float d = 0.6 - length((gl_FragCoord.xy - resolution.xy/2.)/resolution.x);
         glFragColor = vec4(vec3(d), 1.0);
         return;
    }
    
    // The closest point on the surface to the eyepoint along the view ray
    vec3 p = eye + dist * worldDir;
    
    vec3 K_a = vec3(0.97, 0.22, 0.5) * (mod(length(p), 0.3) > 0.15 ? 1. : 0.);
    vec3 K_d = K_a;
    vec3 K_s = vec3(1.0, 1.0, 1.0);
    float shininess = 40.0;
    
    vec3 color = phongIllumination(K_a, K_d, K_s, shininess, p, eye);
    
    glFragColor = vec4(color, 1.0);
    //glFragColor = vec4(gl_FragCoord.xy/resolution.xy, 0.5, 1.0);
    
}
