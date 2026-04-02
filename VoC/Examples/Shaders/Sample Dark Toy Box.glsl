#version 420

// original https://www.shadertoy.com/view/tsXyW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPS .0001
#define NORMAL_EPS .0001
#define PI 3.14159265359
#define PI2 PI * 2.
#define FLT_MAX 3.402823466e+38
#define FLT_MIN 1.175494351e-38

#define MAT_BOX_1 1.
#define MAT_BOX_2 2.
#define MAT_BOX_3 3.
#define MAT_BOX_4 4.
#define MAT_BOX_5 5.
#define MAT_PRISM 6.

#define saturate(a) clamp(a, 0., 1.)
#define repeat(a, b) mod(a, b) - b * .5 
// #define repeat(a, b) mod(a + b * .5, b) - b * .5 

const float stopThreshold = .0001;

precision highp float;

struct Light {
    vec3 position;
      float intensity;
      vec3 color;
      vec3 diffuse;
      vec3 specular;
      float attenuation;
};
    
struct Surface {
      float depth;
      // float dist;
      vec3 position;
      vec3 baseColor;
    vec3 specularColor;
      vec3 normal;
      vec3 emissiveColor;
      float material;
};  

//---------------------------------------------------------------------------------------------
// utils
//---------------------------------------------------------------------------------------------

// ref: https://www.shadertoy.com/view/ldlcRf
vec2 minMat(vec2 d1, vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
}

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

mat3 rot3(float roll, float pitch, float yaw) {
    float cp = cos(pitch);
    float sp = sin(pitch);
    float sr = sin(roll);
    float cr = cos(roll);
    float sy = sin(yaw);
    float cy = cos(yaw);
    return mat3(
        cp * cy, (sr * sp * cy) - (cr * sy), (cr * sp * cy) + (sr * sy),
        cp * sy, (sr * sp * sy) + (cr * cy), (cr * sp * sy) - (sr * cy),
        -sp, sr * cp, cr * cp
    );
}

float distanceToLine(vec3 origin, vec3 dir, vec3 point) {
    vec3 pointToOrigin = point - origin;
    float pointToOriginLength = length(pointToOrigin);
    vec3 pointToOriginNorm = normalize(pointToOrigin);
    float theta = dot(dir, pointToOriginNorm);
    return pointToOriginLength * sqrt(1. - theta * theta);
}

vec3 hash3(vec3 p) {
    vec3 q = vec3(
        dot(p, vec3(127.1, 311.7, 114.5)),
        dot(p, vec3(269.5, 183.3, 191.9)),
        dot(p, vec3(419.2, 371.9, 514.1))
    );
    return fract(sin(q) * 43758.5433);
}

vec3 rgbColor(float r, float g, float b) {
    return vec3(r / 255., g / 255., b / 255.);
}

//---------------------------------------------------------------------------------------------
// sdf
//---------------------------------------------------------------------------------------------

float sdSphere(in vec3 pos, float rad) {
    return length(pos) - rad;
}

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

float sdOctahedron(vec3 p, float s) {
  p = abs(p);
  float m = p.x+p.y+p.z-s;
  vec3 q;
       if( 3.0*p.x < m ) q = p.xyz;
  else if( 3.0*p.y < m ) q = p.yzx;
  else if( 3.0*p.z < m ) q = p.zxy;
  else return m*0.57735027;
    
  float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
  return length(vec3(q.x,q.y-s+k,q.z-k)); 
}

// d1 subtract to d2
float opSub(float d1, float d2) {
    return max(-d1, d2);
}

float sdBox(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0);
}

float sdWireBox(vec3 p, float s, float b) {
    float d = 0.;
    float o = s + .01;
    float i = s - b;
    d = opSub(
        sdBox(p, vec3(o, i, i)),
        sdBox(p, vec3(s))
    );
    d = opSub(
        sdBox(p, vec3(i, o, i)),
        d
    );
    d = opSub(
        sdBox(p, vec3(i, i, o)),
        d
    );
    return d;
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
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
    float d = FLT_MAX;
    float m = 0.;

    p.z += -time * 2.4;
    

        
    // top
    {        
        vec3 _p = p;
        float repeatNum = 2.1;
        vec3 id = floor((_p + repeatNum * .5) / repeatNum);
        vec3 rnd = hash3(id);
        // _p.xz = repeat(_p.xz, repeatNum);
        _p.xz = mod(_p.xz + repeatNum * .5, repeatNum) - repeatNum * .5;
        //vec3 offset = vec3(0., sin(time + rnd.x + rnd.y) * .25, 0.) * 0.;
        vec3 offset = vec3(0., 3. + sin(time * 2.5 + rnd.x * 10.) * .1, 0.);
        
        d = min(d, sdRoundBox(_p - offset, vec3(.8), .1));

        if(rnd.x < .2) {
            m = MAT_BOX_1;    
        } else if(rnd.x < .4) {
            m = MAT_BOX_2;    
        } else if(rnd.x < .6) {
            m = MAT_BOX_3;    
        } else if(rnd.x < .8) {
            m = MAT_BOX_4;    
        } else {
            m = MAT_BOX_5;    
        }
    }
    

    
    // floor
    {        
        vec3 _p = p;
        float repeatNum = 2.1;
        vec3 id = floor((_p + repeatNum * .5) / repeatNum);
        vec3 rnd = hash3(id);
        // _p.xz = repeat(_p.xz, repeatNum);
        _p.xz = mod(_p.xz + repeatNum * .5, repeatNum) - repeatNum * .5;
        //vec3 offset = vec3(0., sin(time + rnd.x + rnd.y) * .25, 0.) * 0.;
        vec3 offset = vec3(0., sin(time * 2.5 + rnd.x * 10.) * .1, 0.);
        
        d = min(d, sdRoundBox(_p - offset, vec3(.8), .1));

        if(rnd.x < .2) {
            m = MAT_BOX_1;    
        } else if(rnd.x < .4) {
            m = MAT_BOX_2;    
        } else if(rnd.x < .6) {
            m = MAT_BOX_3;    
        } else if(rnd.x < .8) {
            m = MAT_BOX_4;    
        } else {
            m = MAT_BOX_5;    
        }
    }
    
    // space
    {
        vec3 _p = p;
        float repeatNum = 2.1;
        vec3 id = floor((_p + repeatNum * .5) / repeatNum);
        vec3 rnd = hash3(id);
        // _p.xz = repeat(_p.xz, repeatNum);
        _p.xz = mod(_p.xz + repeatNum * .5, repeatNum) - repeatNum * .5;               
        d = opSub(sdRoundBox(_p, vec3(.3, 10., .3), .1), d);
    }
    
    // octahedron
    {
        vec3 _p = p;
        float repeatNum = 2.1;
        vec3 id = floor((_p +repeatNum * .5) / repeatNum);
        vec3 rnd = hash3(id);
        // _p.xz = repeat(_p.xz, repeatNum);        
        _p.xz = mod(_p.xz + repeatNum * .5, repeatNum) - repeatNum * .5;        
        _p.xz = rot2(time + rnd.x * 10.) * _p.xz;
        _p = _p - vec3(0., 1.5 + sin(time * 2.5 + rnd.x * 20.) * .1, 0.);
        _p.y *= .5;
        //_p.xy = rot2(time) * _p.xy;
        //_p.xy = pmod(_p.xy, 1. + floor(rnd.x * 11.));
        //_p.y -= .05 + sin(time * 4.) * .1;
        //_p.yz = rot2(time * 2.) * _p.yz;
        //_p.xy = pmod(_p.xy, 1. + floor(rnd.x * 5.));
        float objD = sdOctahedron(_p, .15);
        m = minMat(vec2(d, m), vec2(objD, MAT_PRISM)).y;
        d = min(objD, d);
    }
    
    return vec2(d, m);
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

    
    // raymarching
    float depth = 0.;
    float dist = 0.;
    vec2 result = vec2(0.);
    for(int i = 0; i < 64; i++) {
        result = scene(ro + rd * depth);
        dist = result.x;
        if(dist < stopThreshold) {
            break;
        }
        depth += result.x;
    }    
    
    float tmax = 40.;
    if(depth > tmax) result.y = -1.;
    
    return vec2(depth, result.y);
}

//---------------------------------------------------------------------------------------------
// lightings
//---------------------------------------------------------------------------------------------

const int maxShadowIterations = 32;

float softShadow(vec3 ro, vec3 rd, float mint, float tmax, float power) {
  float res = 1.;
  float t = mint;
  float ph = 1e10;
  for(int i = 0; i < maxShadowIterations; i++) {
    float h = scene(ro + rd * t).y;

    // pattern 1
    // res = min(res, power * h / t);

    // pattern 2
    float y = h * h / (2. * ph);
    float d = sqrt(h * h - y * y);
    res = min(res, power * d / max(0., t - y));
    ph = h;

    t += h;

    float e = EPS;
    if(res < e || t > tmax) break;
  }
  return clamp(res, 0., 1.);
}
 

float getSpecular(vec3 position, vec3 normal, Light light, float diffuse, vec3 cameraPos) {
      vec3 lightDir = light.position - position;
      vec3 ref = reflect(-normalize(lightDir), normal);
      float specular = 0.;
      if(diffuse > 0.) {
        specular = max(0., dot(ref, normalize(cameraPos - normal)));
        float specularPower = 64.;
        specular = pow(specular, specularPower);
      }
      return specular;
}

void calcDirectionalLight(inout Light light, Surface surface, vec3 cameraPos) {
      // diffuse
      float diffuseCoef = max(0., dot(surface.normal, normalize(light.position)));
      vec3 diffuse = diffuseCoef * light.attenuation * light.color * light.intensity;
      // specular
      float specularCoef = getSpecular(surface.position, surface.normal, light, diffuseCoef, cameraPos);
      vec3 specular = vec3(specularCoef * light.attenuation * light.color * light.intensity);  

      light.diffuse = diffuse * softShadow(surface.position, normalize(light.position), .1, 3., 5.);
    light.specular = specular;
}

void calcPointLight(inout Light light, Surface surface, vec3 cameraPos) {
      float d = distance(light.position, surface.position);
      vec3 k = vec3(.06, .08, .09);
      light.attenuation = 1. / (k.x + (k.y * d) + (k.z * d * d));

      // point light
      vec3 lightDir = light.position - surface.position;
      // diffuse
      float diffuseCoef = max(0., dot(surface.normal, normalize(lightDir)));
      vec3 diffuse = diffuseCoef * light.color * light.intensity * light.attenuation;
      // specular
      float specularCoef = getSpecular(surface.position, surface.normal, light, diffuseCoef, cameraPos);
      vec3 specular = vec3(specularCoef * light.attenuation * light.color * light.intensity); 
    
      light.diffuse = diffuse * softShadow(surface.position, normalize(light.position), .1, 3., 5.);
      light.specular = specular;
}

float ambientOcculusion(vec3 pos, vec3 nor) {
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

vec3 lighting(Surface surface, vec3 cameraPos) {
      vec3 position = surface.position;

      vec3 color = vec3(0.);
      vec3 normal = surface.normal;

      Light directionalLight;
      directionalLight.position = vec3(0., .1, 1.);
      directionalLight.intensity = .01;
      directionalLight.color = vec3(1., 1., 1.);
      directionalLight.attenuation = 1.;
      calcDirectionalLight(directionalLight, surface, cameraPos);
    
      Light pointLight;
      pointLight.position = vec3(0., 0., 0.);
      pointLight.intensity = .7;
      pointLight.color = vec3(.4, .8, .5);
      //pointLight.attenuation = 1.;
      calcPointLight(pointLight, surface, cameraPos);
    
      vec3 diffuse = directionalLight.diffuse + pointLight.diffuse;
      vec3 specular = directionalLight.specular + pointLight.specular;
    
    float occ = ambientOcculusion(surface.position, surface.normal);
      float amb = clamp(.5 + .5 * surface.normal.y, 0., 1.);
      vec3 ambient = surface.baseColor * amb * occ * vec3(0., .08, .1);        
  
      color =
        surface.emissiveColor +
        surface.baseColor * diffuse +
        surface.specularColor * specular +
        ambient;  
  
      return color;
}

//---------------------------------------------------------------------------------------------
// main
//---------------------------------------------------------------------------------------------

void main(void) {
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) / min(resolution.x, resolution.y);
    vec2 mouse = (mouse*resolution.xy.xy - resolution.xy * .5) / min(resolution.x, resolution.y);
    
    vec3 ro = vec3(mouse * .5 + vec2(1.05, 1.5) + vec2(sin(time * .8), cos(time * 1.2)) * .15, 3.);
    vec3 target = vec3(1.05, 1.5, 0.) + vec3(sin(time * .3), cos(time * .8), 0.) * .15;
    float fov = .9;
    
    vec3 rd = camera(ro, target) * normalize(vec3(uv, fov));
    
    vec2 result = raymarch(ro, rd);
    vec3 color = vec3(0.);
    
    if(result.y > 0.) {
        float depth = result.x;
        float material = result.y;    
   
        vec3 position = ro + rd * depth;
        vec3 normal = getNormal(position);
        
        Surface surface;
        surface.depth = depth;
        // surface.dist = dist;
        surface.position = position;
        surface.normal = normal;
        surface.material = result.y;
    
        vec3 objColor = vec3(0.);

        // pallete is:
        // https://www.color-hex.com/color-palette/88982
        if(checkMat(material, MAT_BOX_1)) {
            surface.baseColor = rgbColor(201., 72., 24.);
        } else if(checkMat(material, MAT_BOX_2)) {
            surface.baseColor = rgbColor(10., 48., 77.);
        } else if(checkMat(material, MAT_BOX_3)) {
            surface.baseColor = rgbColor(132., 163., 158.);
        } else if(checkMat(material, MAT_BOX_4)) {
            surface.baseColor = rgbColor(255., 193., 16.);
        } else if(checkMat(material, MAT_BOX_5)) {
            surface.baseColor = rgbColor(169., 101., 41.);
        } else if(checkMat(material, MAT_PRISM)) {
            surface.baseColor = rgbColor(140., 120., 40.);
        }
        surface.specularColor = vec3(1.);
        
        // surface.emissiveColor = surface.baseColor;
        
        color = lighting(surface, ro);
    }

    // fog
    color = fog(color, result.x, vec3(.02, .02, .04), .12);
    
    // gamma
    color = pow(color, vec3(.4545));
    
    glFragColor = vec4(color, 1.);
}

