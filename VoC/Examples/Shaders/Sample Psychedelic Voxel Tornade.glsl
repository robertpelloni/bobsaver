#version 420

// original https://www.shadertoy.com/view/wtlXWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//------------------------------------------------------------------------
// # refs
// ## repeat, mod, pmod
// - https://qiita.com/kaneta1992/items/21149c78159bd27e0860#ifs%E3%81%AB%E3%82%88%E3%82%8B%E8%A4%87%E9%9B%91%E3%81%AA%E5%BD%A2%E7%8A%B6
// - https://qiita.com/edo_m18/items/8c20c9c80d44e8b1dfe4#_reference-7c25132332209c2cd12e
// - https://gam0022.net/blog/2017/03/02/raymarching-fold/
// ## collor pallete
// - https://www.shadertoy.com/view/ll2GD3
// ## material mechanism
// - https://www.shadertoy.com/view/ldlcRf
// ## fake motion blur ?
// - https://www.shadertoy.com/view/WllSDM
// ## distance functions, fog ... 
// - http://www.iquilezles.org/www/index.htm
//------------------------------------------------------------------------

precision highp float;

#define EPS .0001
#define PI 3.1415
#define PI2 PI * 2.
#define repeat(p, o) mod(p, o) - o * .5
#define saturate(a) clamp(a, 0., 1.)

// ref: https://www.shadertoy.com/view/ldlcRf
#define TEST_MAT_LESS (a, b) a < (b + .1)
#define TEST_MAT_GREATER (a, b) a > (b - .1)

const float stopThreshold = .0001;

struct Light {
    vec3 position;
      float intensity;
      vec3 color;
      vec3 diffuse;
      vec3 specular;
};
    
struct Surface {
      float depth;
      float dist;
      vec3 position;
      vec3 baseColor;
      vec3 normal;
      vec3 emissiveColor;
      float material;
};  

// init lights
Light directionalLight;    
Light pointLight;

// ref: https://www.shadertoy.com/view/ldlcRf
vec2 minMat(vec2 d1, vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
}

// ref: https://www.shadertoy.com/view/WllSDM
float n3(vec3 p) {
    vec3 r = vec3(1, 99, 999);
    vec4 s = dot(floor(p), r) + vec4(0., r.yz, r.y + r.z);
    p = smoothstep(0., 1., fract(p));
    vec4 a = mix(fract(sin(s) * 5555.), fract(sin(s + 1.) * 5555.), p.x);
    vec2 b = mix(a.xz, a.yw, p.y);
    return mix(b.x, b.y, p.z);
}
    
// ref: https://www.shadertoy.com/view/ll2GD3
// t: 0-1, a: contrast, b: brightness, c: times, d: offset
vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

float sdBox(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0);
}

float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

// d1 subtract to d2
float opSub(float d1, float d2) {
    return max(-d1, d2);
}

float smin(float a, float b, float k) {
  float res = exp(-k * a) + exp(-k * b);
  return -log(res) / k;
}

float sdWireBox(vec3 p, float s, float b) {
    float d = 0.;
    float o = s + .5;
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

vec2 pmod(vec2 p, float r) {
    float a = atan(p.x, p.y) + PI / r;
    float n = PI * 2. / r;
    a = floor(a / n) * n;
    return p * rot(-a);
}

vec2 tunnel(vec3 p) {    
    float d = 0.;
    vec3 _p = p;
    vec3 q = p;
    float m = 0.;
    
    float scale = 2.6;
    float scalePower = .6;
    vec3 size = vec3(1.1);
    
    float repeatNum = 9.;

    vec3 id = floor(_p / repeatNum);
    
    float openSpeed = mod(time * 1.8 + PI2 * .8, PI2);
    
    float border = .15 + sin(openSpeed) * .11;
    
    d = 100000.;
    
    vec2 obj = vec2(d, 1.);

    _p.z = repeat(_p.z, .8);
    
    _p.xy = pmod(_p.xy, 5.);

    for(int i = 0; i < 2; i++) {
        _p.y -= size.y;

        p.xz *= rot(.08);
        p.xy *= rot(mod(time * .8, PI2));
        
        float currentDist = 0.;
        currentDist = sdWireBox(p, .22 * size.y, border * size.y);
        
        vec2 currentObj = vec2(currentDist, float(i) + 1.);
        m = minMat(obj, currentObj).y;
        obj.x = min(obj.x, currentObj.x);
        obj.y = m;
        
        scale *= scalePower;
        
        p = _p;
        size *= scale;
    }
    
    return vec2(obj.x, m);
}

vec3 opTwist(vec3 p) {
    float k = .75;
    vec3 q = p;
    q.xy *= rot(mod(k * p.z + time * .35, PI2));
    return q;
}

vec2 scene(vec3 p) {
    vec3 move = vec3(0., 0., -time) * 1.8;
    vec2 d = vec2(0.);
    vec3 _p = p + move;
    _p = opTwist(_p);
    d = tunnel(_p);
    
    return d;
}

mat3 camera(vec3 o, vec3 t, vec3 u) {
    vec3 forward = normalize(t - o);
    vec3 right = cross(forward, u);
    vec3 up = cross(right, forward);
    return mat3(right, up, forward);
}

vec3 getNormal(vec3 p, float eps) {
    vec2 e = vec2(eps, 0);
    return normalize(
        vec3(
            scene(p + e.xyy).x - scene(p - e.xyy).x,
            scene(p + e.yxy).x - scene(p - e.yxy).x,
            scene(p + e.yyx).x - scene(p - e.yyx).x
        )
    );
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

float calcRim(float NoL, float NoE, float EoL, float eyeCoef, float lightCoef) {
    float rimEyeCoef = pow(saturate(1. - saturate(NoE)), eyeCoef);
    float rimLightCoef = pow(EoL, lightCoef);
    float rim = saturate(rimEyeCoef * rimLightCoef);
    return rim;
}

void calcDirectionalLight(inout Light light, Surface surface, vec3 cameraPos) {
      // diffuse
    float NoL = dot(surface.normal, normalize(light.position));
    float EoL = dot(
        normalize(cameraPos - surface.position),
        normalize(light.position - surface.position)
    );
    float NoE = dot(
        normalize(cameraPos - surface.position),
        surface.normal
    );
    
      float diffuseCoef = saturate(NoL);
      vec3 diffuse = diffuseCoef * light.color * light.intensity;    
    diffuse += calcRim(NoL, NoE, EoL, 4., 32.) * light.intensity * light.color;
    
    // specular
      float specularCoef = getSpecular(surface.position, surface.normal, light, diffuseCoef, cameraPos);
      vec3 specular = vec3(specularCoef * light.color * light.intensity);  
    
      light.diffuse = diffuse;
      light.specular = specular;
}

void calcPointLight(inout Light light, Surface surface, vec3 cameraPos) {
    vec3 lightDir = normalize(light.position - surface.position);
    float attenuation = saturate(1. / pow(distance(light.position, surface.position), 2.));
    
    float NoL = saturate(dot(surface.normal, lightDir));
    float EoL = dot(
        normalize(cameraPos - surface.position),
        lightDir
    );
    float NoE = dot(
        normalize(cameraPos - surface.position),
        surface.normal
    );

    float diffuseCoef = NoL;
    vec3 diffuse = diffuseCoef * attenuation * light.color * light.intensity;
    diffuse += calcRim(NoL, NoE, EoL, 4., 32.) * light.intensity * attenuation * light.color;    
    
    float specularCoef = getSpecular(surface.position, surface.normal, light, diffuseCoef, cameraPos);
    vec3 specular = vec3(specularCoef * attenuation * light.color * light.intensity);
        
    light.diffuse = diffuse;
    light.specular = specular;
}

vec3 lighting(Surface surface, vec3 cameraPos, vec3 rd) {
      vec3 position = surface.position;

      vec3 color = vec3(0.);
      vec3 normal = surface.normal;

    calcDirectionalLight(directionalLight, surface, cameraPos);
    calcPointLight(pointLight, surface, cameraPos);

      vec3 diffuse = directionalLight.diffuse + pointLight.diffuse;
      vec3 specular = directionalLight.specular + pointLight.specular;;
    
      vec3 ambient = vec3(1.) * .1;

      color = surface.baseColor * (diffuse + specular + ambient);  
  
      return color;
}

vec3 fog(vec3 color, float distance, vec3 fogColor, float b) {
      float fogAmount = 1. - exp(-distance * b);
      return mix(color, fogColor, fogAmount);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) / min(resolution.x, resolution.y);
    vec2 mouse = (mouse*resolution.xy.xy - resolution.xy * .5) / min(resolution.x, resolution.y);
    
    vec3 move = vec3(0., 0., -time) * 0.;
    vec3 ro = vec3(cos(time * 1.9) * .03, sin(time * 1.6 + .4) * .05, -4.) + move;
    vec3 target = vec3(cos(time * .9 + .2) * .3, sin(time * .5) * .3, -8.) + move/* + vec3(mouse * 1., 0.)*/;
    
    
    float fov = 1.2;
    
    vec3 up = vec3(0., 1., 0.);
    vec3 rd = camera(ro, target, up) * normalize(vec3(uv, fov));
    
    // raymarching
    float depth = 0.;
    float dist = 0.;
    vec2 result = vec2(0.);
    for(int i = 0; i < 99; i++) {
        result = scene(ro + rd * depth);
        dist = result.x;
        if(dist < stopThreshold) {
            break;
        }
        depth += result.x;
    }   
    
    vec3 color = vec3(0.);
   
    vec3 position = ro + rd * depth;
    vec3 normal = getNormal(position, .001);
    
    Surface surface;
    surface.depth = depth;
    surface.dist = dist;
    surface.position = position;
    surface.normal = normal;
    surface.material = result.y;
    
    vec3 sceneColor = vec3(0.);
    
    vec3 bgColor = vec3(.08,  .05, .09);
 
    directionalLight.position = vec3(0., 0., 1.);
    directionalLight.intensity = .5;
    directionalLight.color = vec3(.8, .8, 1.);

    pointLight.position = vec3(0., 0., -4.2) + move;
    pointLight.intensity = .4;
    pointLight.color = vec3(.8, .8, 1.);
    
    if(dist >= stopThreshold) {
        // no hit
        sceneColor = bgColor;
    } else {
        // hit
        surface.baseColor = palette(
            /*surface.position.x / 10.
                + surface.position.y / 10.
                + */(surface.position.z - time * 1.4) / 1.2,
            vec3(.9),
            vec3(.6),
            vec3(.2),
            vec3(.4, .9, 1.)    
        );
        sceneColor = lighting(surface, ro, rd);           
    }

    // fog
    sceneColor = fog(sceneColor, depth, bgColor, .2);
    // vignet
    sceneColor *= smoothstep(1.6, .35, length(uv.xy));
    
    glFragColor = vec4(sceneColor, 1.);
    
}
