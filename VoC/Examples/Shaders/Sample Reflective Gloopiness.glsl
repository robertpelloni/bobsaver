#version 420

// original https://www.shadertoy.com/view/clSSRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_ITERS 50
#define MIN_DIST 0.003
#define MAX_DIST 100.

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

float smin(float a, float b, float k) {
  float res = exp(-k * a) + exp(-k * b);
  return -log(res) / k;
}

// SDFs
float sSphere(vec3 p, float r) {
    return length(p) - r;
}

float sPlane(vec3 p) {
    return p.y;
}

float sPlaneXY(vec3 p) {
  return p.z;
}

float sScene(vec3 p) {
    float x = 0;//(mouse*resolution.xy.x/resolution.x);
    float d = smin(sPlane(p + vec3(1.)), sSphere(p - vec3(0., 0., 2.), 0.5), 2.5);
    d = smin(d, sSphere(p - vec3(0.5, 0.5, 1.5), 0.3), 10.);
    d = smin(d, sSphere(p - vec3(-0.7, 0.2, 1.8), 0.2), 10.);
    d = smin(d, sSphere(p - vec3(-0.1 + x, -0.2, 1.4), 0.2), 10.);
    d = smin(d, sSphere(p - vec3(-0.3, sin(time), 1.4), 0.1), 7.);
    d = smin(d, sPlaneXY(vec3(5.) - p), 10.);
    d = smin(d, sSphere(p - vec3(0., 0.5, 7.), 4.), 2.);
    return d;
}

// Ray casting
struct RayCast {
    vec3 p;
    float d;
};
RayCast getSurface(vec3 ro, vec3 rd) {
    float d = 0.;
    vec3 p = ro;
    for(int i=0; i<MAX_ITERS; i++) {
        p += d * rd;
        d = sScene(p);
        if (d < MIN_DIST) {
            return RayCast(p, d);
        }
    }
    return RayCast(p, MAX_DIST);
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.01, 0.);
    vec3 val = vec3(
        sScene(p + e.xyy) - sScene(p - e.xyy),
        sScene(p + e.yxy) - sScene(p - e.yxy),
        sScene(p + e.yyx) - sScene(p - e.yyx)
    );
    return normalize(val);
}

// Lighting
struct Light {
    vec3 pos;
    vec3 col;
};

vec3 getLighting(vec3 p, vec3 n, vec3 i, Light light) {
    float dist = length(p - light.pos);
    vec3 normDiff = normalize(light.pos - p);
    
    // diffuse
    float diffuse = dot(n, light.pos);
    diffuse = map(diffuse, 0., 1., 0.2, 1.);
    diffuse *= 1. / pow(dist, 2.);
    diffuse = max(0., diffuse);
    vec3 diffuseV = diffuse * light.col;
   
    // specular
    float spec = dot(i, normDiff);
    spec = 0.9 * smoothstep(0.99, 1., spec);
    vec3 specular = spec * (light.col + vec3(0.8));
    
    // shadow
    float e = 0.02;
    vec3 ro = p + (e * n);
    RayCast rayCast = getSurface(ro, normDiff);
    float shadow = step(0., rayCast.d - e - dist);
    shadow = map(shadow, 0., 1., 0.1, 1.);
    
    return shadow * (diffuseV + specular);
}

vec3 getSceneLighting(vec3 p, vec3 n, vec3 i) {
    Light light1 = Light(
        vec3(1.5*sin(time), 2., 0.5*cos(time)),
        5. * vec3 (1., 0., 0.)
    );
    
    Light light2 = Light(
        vec3(-1.*sin(time), 2., -0.5*cos(time) - 1.),
        4. * vec3 (0., 1., 0.)
    );
    
    Light light3 = Light(
        vec3(-1.5*sin(time), 2., 0.5*cos(time) + 1.),
        2. * vec3 (0., 0., 1.)
    );
    
    Light light4 = Light(
        vec3(-5., 100., 10.),
        100. * vec3(1., 0., 0.5)
    );
    
    vec3 lighting = getLighting(p, n, i, light1);
    lighting += getLighting(p, n, i, light2);
    lighting += getLighting(p, n, i, light3);
    lighting += getLighting(p, n, i, light4);
    return lighting;
}

void main(void)
{
    float zoom = 1.;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
    
    vec3 ro = vec3(0., 0., -zoom);
    vec3 rd = normalize(vec3(uv, 0.) - ro);
    
    vec3 p = getSurface(ro, rd).p;
    vec3 n = getNormal(p);
    vec3 i = reflect(normalize(p), n);
    
    // Ambient lighting
    vec3 col = 0.3 * vec3(0., 0.8, 1.);
    
    // Base lighting
    col += getSceneLighting(p, n, i);
    
    // Reflections
    float fresnel = dot(ro, n);
    fresnel = smoothstep(1., 0.4, fresnel);
    ro = p + (0.02 * n);
    p= getSurface(ro, i).p;
    n = getNormal(p);
    col += 0.2 * fresnel * getSceneLighting(p, n, i);

    glFragColor = vec4(col, 1.0);
}
