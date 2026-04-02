#version 420

// original https://www.shadertoy.com/view/3dlcW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPS .0001
#define NORMAL_EPS .0001
#define PI 3.14159265359
#define PI2 PI * 2.

#define MAT_TUBE 1.

#define saturate(a) clamp(a, 0., 1.)
#define repeat(a, b) mod(a, b) - b * .5 

precision highp float;

//---------------------------------------------------------------------------------------------
// utils
//---------------------------------------------------------------------------------------------

bool checkMat(float material, float check) {
    return material < (check + .5);
}

mat3 camera(vec3 o, vec3 t) {
    vec3 forward = normalize(t - o);
    vec3 right = cross(forward, vec3(0., 1., 0.));
    vec3 up = cross(right, forward);
    return mat3(right, up, forward);
}

mat2 rot2(float t) {
    return mat2(cos(t), -sin(t), sin(t), cos(t));
}

//---------------------------------------------------------------------------------------------
// sdf
//---------------------------------------------------------------------------------------------

// ra: radius
// rb: round
// h: height
float sdRoundedCylinder(vec3 p, float ra, float rb, float h) {
    vec2 d = vec2(length(p.xz) - 2. * ra + rb, abs(p.y) - h);
    return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rb;
}

// a: begin pos
// b: begin thin
// ra: end pos
// rb: end thin
float sdStick(in vec3 p, vec3 a, vec3 b, float ra, float rb) {
    vec3 ba = b - a;
    vec3 pa = p - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
    float r = mix(ra, rb, h);
    return length(pa - h * ba) - r;
}

float sdElipsoid(in vec3 pos, vec3 rad) {
    float k0 = length(pos / rad);
    float k1 = length(pos / rad / rad);
    return k0 * (k0 - 1.) / k1;
}

float sdCylinder(vec3 p, vec3 c) {
  return length(p.xz - c.xy) - c.z;
}

float smin(in float a, in float b, float k) {
    float h = max(k - abs(a - b), 0.);
    return min(a, b) - h * h / (k * 4.);
}

float smax(in float a, in float b, float k) {
    float h = max(k - abs(a - b), 0.);
    return max(a, b) + h * h / (k * 4.);
}

float displacement(vec3 p, vec3 power) {
  return sin(power.x * p.x) * sin(power.y * p.y) * sin(power.z * p.z);
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

vec2 pmod(vec2 p, float r) {
    float a = atan(p.x, p.y) + PI / r;
    float n = PI * 2. / r;
    a = floor(a / n) * n;
    return p * rot(-a);
}

//---------------------------------------------------------------------------------------------
// raymarch
//---------------------------------------------------------------------------------------------

vec2 scene(vec3 p) {
    // dummy float max and min
    vec2 res = vec2(10000., -10000.);

    {
        float d = 0.;

        p.z -= time * .7;

        p.xy = rot(time * .1 + p.z * .25) * p.xy;

        vec3 _p1 = p;
        float sphereRepeatNum = .5;
        _p1 = repeat(_p1, sphereRepeatNum);
        vec3 sphereId = floor(p / sphereRepeatNum);
        d = sdElipsoid(_p1, vec3(.02 + sin(time * 1. + sphereId.z) * .2));

        vec3 _p2 = p;
        float tube1_repeat_num = .5;
        vec3 tube1_id = floor(p / tube1_repeat_num);
        _p2.yz = rot(PI * .5) * _p2.yz;
        _p2.x += sin(time * 2. + p.x * 3. + p.z * 2.) * .04;
        _p2.z += sin(time * 2. + p.z * 4. + p.x * 4.) * .04;
        _p2 = repeat(_p2, tube1_repeat_num);
        d = smin(
            d,
            sdCylinder(_p2, vec3(0., 0., .025)),
            .08
        );

        vec3 _p3 = p;
        float tube2RepeatNum = .5;
        vec3 tube2Id = floor(p / tube2RepeatNum);
        _p3.xz = rot(PI * .5) * _p3.yz;
        _p3.y += sin(time * 2. + p.y * 3. + p.x * 2.) * .04;
        _p3.z += sin(time * 2. + p.z * 4. + p.x * 4.) * .04;
        _p3 = repeat(_p3, tube2RepeatNum);
        d = smin(
             d,
             sdCylinder(_p3, vec3(0., 0., .025)),
             .08
         );

        vec3 _p4 = p;
        float tube3RepeatNum = .5;
        vec3 tube3_id = floor(p / tube3RepeatNum);
        _p4.x += sin(time * 2. + p.y * 3. + p.x * 2.) * .04;
        _p4.z += sin(time * 2. + p.z * 4. + p.x * 4.) * .04;
        _p4 = repeat(_p4, tube3RepeatNum);
        d = smin(
            d,
            sdCylinder(_p4, vec3(0., 0., .025)),
            .08
        );

        if(d < res.x) res = vec2(d, MAT_TUBE);
    }
    
    return res;
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(NORMAL_EPS, 0);
    return normalize(
        vec3(
            scene(p + e.xyy).x - scene(p - e.xyy).x,
            scene(p + e.yxy).x - scene(p - e.yxy).x,
            scene(p + e.yyx).x - scene(p - e.yyx).x
        )
    );
}

vec2 raymarch(vec3 ro, vec3 rd) {
    float tmin = .01;
    float tmax = 80.;
    float m = -1.;
    float t = tmin;
    for(int i = 0; i < 64; i++) {
        vec3 pos = ro + rd * t;
        vec2 h = scene(pos);
        m = h.y;
        if(abs(h.x) < (.001 * t)) break;
        t += h.x;
        if(t > tmax) break;
    }
    if(t > tmax) m = -1.;
    return vec2(t, m);
}

//---------------------------------------------------------------------------------------------
// lightings
//---------------------------------------------------------------------------------------------

float calcOcculusion(vec3 pos, vec3 nor) {
    float occ = 0.;
    float sca = 1.;
    for(int i = 0; i < 5; i++) {
        float h = .01 + .11 * float(i) / 4.;
        vec3 opos = pos + h * nor;
        float d = scene(opos).x;
        occ += (h - d) * sca;
        sca *= .95;
    }
    return clamp(1. - 2. * occ, 0., 1.);
}
 
vec3 fog(vec3 color, float dist, vec3 fogColor, float b) {
  float fogAmount = 1. - exp(-dist * b);
  return mix(color, fogColor, fogAmount);
}
 

//---------------------------------------------------------------------------------------------
// main
//---------------------------------------------------------------------------------------------

void main(void) {
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) / min(resolution.x, resolution.y);
    vec2 mouse = (mouse*resolution.xy.xy - resolution.xy * .5) / min(resolution.x, resolution.y);
    
    vec3 ro = vec3(mouse * .5, 4.) + vec3(sin(time * 1.4) * .075, cos(time * .9) * .075, 0.);
    vec3 target = vec3(ro.xy, ro.z - 3.) + vec3(cos(time * 1.2) * .075, sin(time * .7) * .075, 0.);
    float fov = 1.5;
    
    vec3 rd = camera(ro, target) * normalize(vec3(uv, fov));
    
    vec2 result = raymarch(ro, rd);
    vec3 color = vec3(0.);
    
    if(result.y > 0.) {
        float depth = result.x;
        float material = result.y;    
   
        vec3 position = ro + rd * depth;
        vec3 normal = getNormal(position);
    
        vec3 objColor = vec3(0.);

        if(checkMat(material, MAT_TUBE)) {
            objColor = vec3(.1, .2, .5);
        }

        vec3 specularColor = vec3(.1, .2, .7);
        
        vec3 lightPos = vec3(0., 0., ro.z - 3.);
        vec3 lightDir = normalize(lightPos);
        float lightIntensity = .45;
    
        vec3 ambient = vec3(.01);
        
        // point light
        vec3 toLightDir = normalize(lightPos - position);
        float diffuse = max(0., dot(normal, toLightDir));
        float d = distance(lightPos, position);
        vec3 k = vec3(0.06, 0.08, 0.09);
        float attenuation = 1. / (k.x + (k.y * d) + (k.z * d * d));
        attenuation *= lightIntensity;
  
        vec3 ref = reflect(-toLightDir, normal);
        float specular = max(0., dot(ref, normalize(ro - normal)));
        float specularPower = 32.;
        specular = pow(specular, specularPower);
        
        diffuse *= attenuation;
        specular *= attenuation;
  
        color =
            objColor * vec3(diffuse) +
            specularColor * vec3(specular) +
            ambient;        
    }

    // fog
    color = fog(color, result.x, vec3(.05, .05, .1), .14);
    
    // gamma
    color = pow(color, vec3(.4545));
    
    glFragColor = vec4(color, 1.);
}
