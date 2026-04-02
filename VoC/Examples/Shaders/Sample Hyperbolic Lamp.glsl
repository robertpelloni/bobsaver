#version 420

// original https://www.shadertoy.com/view/4sVSzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Created by soma_arc - 2016
This work is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported.
*/

// from Syntopia http://blog.hvidtfeldts.net/index.php/2015/01/path-tracing-3d-fractals/
vec2 rand2n(vec2 co, float sampleIndex) {
    vec2 seed = co * (sampleIndex + 1.0);
    seed+=vec2(-1,1);
    // implementation based on: lumina.sourceforge.net/Tutorials/Noise.html
    return vec2(fract(sin(dot(seed.xy ,vec2(12.9898,78.233))) * 43758.5453),
                fract(cos(dot(seed.xy ,vec2(4.898,7.23))) * 23421.631));
}

vec2 tp1 = vec2(0.26607724, 0);
vec2 tp2 = vec2(0, 0.14062592);
vec2 cPos = vec2(2.01219217, 3.62584500);
float r = 4.02438434;
const float PI = 3.14159265359;
const float EPSILON = 0.001;

void calcCircle(float theta, float phi){
    float tanTheta = tan(PI/2. - theta);
    float tanPhi = tan(phi);
    float tanTheta2 = tanTheta * tanTheta;
    float tanPhi2 = tanPhi * tanPhi;
    
    tp1 = vec2(sqrt((1. + tanTheta2)/(-tanPhi2 + tanTheta2)) - 
               tanTheta * sqrt((1. + tanPhi2)/(-tanPhi2 + tanTheta2))/tanTheta, 0.);
    tp2 = vec2(0., -tanPhi * sqrt(-(1. + tanTheta2)/(tanPhi2 - tanTheta2))+
              tanTheta * sqrt(-(1. + tanPhi2)/(tanPhi2 - tanTheta2)));
    
    
    cPos = vec2(sqrt((1. + tanTheta2)/(-tanPhi2 + tanTheta2)),
                 sqrt((1. + tanPhi2)*tanTheta2/(-tanPhi2 + tanTheta2))
               );
    r = sqrt((1. + tanPhi2)*(1. + tanTheta2) /(-tanPhi2 + tanTheta2));
}

vec2 circleInverse(vec2 pos, vec2 circlePos, float circleR){
    return ((pos - circlePos) * circleR * circleR)/(length(pos - circlePos) * length(pos - circlePos) ) + circlePos;
}

const int ITERATIONS = 50;
float loopNum = 0.;

int IIS(vec2 pos){
    if(length(pos) > 1.) return 0;

    bool fund = true;
    int invCount = 1;
    for(int i = 0 ; i < ITERATIONS ; i++){
        fund = true;
        if (pos.x < 0.){
            pos *= vec2(-1, 1);
            invCount++;
               fund = false;
        }
        if(pos.y < 0.){
            pos *= vec2(1, -1);
            invCount++;
            fund = false;
        }
        if(distance(pos, cPos) < r ){
            pos = circleInverse(pos, cPos, r);
            invCount++;
            fund = false;
        }
        if(fund)
            return invCount;
    }

    return invCount;
}

vec2 stereoProject(vec3 p){
    return vec2(p.x / (1. - p.z), p.y / (1. - p.z));
}

vec2 twistedReflect(vec2 p){
    return -p / (p.x * p.x + p.y * p.y);
}

vec4 intersectSphere(vec3 sphereCenter, float radius, 
                      vec3 rayOrigin, vec3 rayDir, vec4 isect){
    vec3 v = rayOrigin - sphereCenter;
    float b = dot(rayDir, v);
    float c = dot(v, v) - radius * radius;
    float d = b * b - c;
    if(d >= 0.){
        float s = sqrt(d);
        float t = -b - s;
        if(t <= EPSILON) t = -b + s;
        if(EPSILON < t && t < isect.x){
            vec3 p = (rayOrigin + t * rayDir);
            int d = 0;
            if(p.y > 0.5)
                d = IIS(twistedReflect(stereoProject(p.xzy)));
            else
                d = IIS(stereoProject(p.xzy));
            if(mod(float(d), 2.) == 0.)
                return vec4(t, normalize(p - sphereCenter));
            t = -b + s;
            if(EPSILON < t && t < isect.x){
                p = (rayOrigin + t * rayDir);
                if(p.y > 0.5)
                    d = IIS(twistedReflect(stereoProject(p.xzy)));
                else
                       d = IIS(stereoProject(p.xzy));
                if(mod(float(d), 2.) == 0.)
                    return vec4(t, normalize(p - sphereCenter));
            }
        }
    }
    return isect;
}

vec4 intersectPlane(vec3 p, vec3 n, 
                    vec3 rayOrigin, vec3 rayDir, vec4 isect){
    float d = -dot(p, n);
    float v = dot(n, rayDir);
    float t = -(dot(n, rayOrigin) + d) / v;
    if(EPSILON < t && t < isect.x){
        return vec4(t, n);
    }
    return isect;
}

float distFunc(vec3 p){
  return length(p) - 100.;
}

const vec2 d = vec2(0.01, 0.);
vec3 getNormal(const vec3 p){
    return normalize(vec3(distFunc(p + d.xyy) - distFunc(p - d.xyy),
                           distFunc(p + d.yxy) - distFunc(p - d.yxy),
                           distFunc(p + d.yyx) - distFunc(p - d.yyx)));
}

const vec3 BLACK = vec3(0);
vec3 spherePos = vec3(0, .5, 0);
float sphereR = 0.5;

bool visible(vec3 org, vec3 target){
    vec3 v = target - org;
    vec4 result = vec4(length(v));
    result = intersectSphere(spherePos, sphereR, org, normalize(v), result);
    if(result.x < length(v)) return false;
    result = intersectPlane(vec3(0), vec3(0, 1, 0), org, normalize(v), result);
    if(result.x < length(v)) return false;
    return true;
}

const float PI_4 = 12.566368;
const vec3 LIGHTING_FACT = vec3(0.1);
vec3 diffuseLighting(const vec3 p, const vec3 n, const vec3 diffuseColor,
                     const vec3 lightPos, const vec3 lightPower){
      vec3 v = lightPos - p;
      float d = dot(n, normalize(v));
      float r = length(v);
      return (d > 0. && visible(p, lightPos)) ?
        (lightPower * (d / (PI_4 * r * r))) * diffuseColor
        : vec3(0.);
}

const vec3 lightPos = vec3(3, 5, 0);
const vec3 lightPower = vec3(100.);
const vec3 lightPos2 = vec3(0, 0.5, 0);
const vec3 lightPower2 = vec3(50.);
const int MAX_MARCHING_LOOP = 800;
vec2 march(const vec3 origin, const  vec3 ray, const float threshold){
    vec3 rayPos = origin;
      float dist;
      float rayLength = 0.;
      for(int i = 0 ; i < MAX_MARCHING_LOOP ; i++){
        dist = distFunc(rayPos);
        rayLength += dist;
        rayPos = origin + ray * rayLength ;
        if(dist < threshold) break;
      }
      return vec2(dist, rayLength);
}

vec3 calcColor(vec3 eye, vec3 ray){
      vec3 l = BLACK;
      float coeff = 1.;
      vec4 result = intersectSphere(spherePos, sphereR, eye, ray, vec4(99999.));
    result = intersectPlane(vec3(0), vec3(0, 1, 0), eye, ray, result);
    
    vec3 matColor = vec3(1.);
      
      if(result.x > 0.){
        vec3 intersection = eye + ray * result.x;
        vec3 normal = result.yzw;
           l += diffuseLighting(intersection, normal, matColor, lightPos, lightPower);
           l += diffuseLighting(intersection, normal, matColor, lightPos2, lightPower2);

    }
      return l;
}

vec3 hsv2rgb(vec3 c){
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 calcRay (const vec3 eye, const vec3 target, const vec3 up, const float fov,
              const float width, const float height, const vec2 coord){
    float imagePlane = (height * .5) / tan(fov * .5);
      vec3 v = normalize(target - eye);
     vec3 xaxis = normalize(cross(v, up));
      vec3 yaxis =  normalize(cross(v, xaxis));
      vec3 center = v * imagePlane;
      vec3 origin = center - (xaxis * (width  *.5)) - (yaxis * (height * .5));
      return normalize(origin + (xaxis * coord.x) + (yaxis * (height - coord.y)));
}

const float DISPLAY_GAMMA_COEFF = 1. / 2.2;
vec3 gammaCorrect(vec3 rgb) {
    return vec3((min(pow(rgb.r, DISPLAY_GAMMA_COEFF), 1.)),
                (min(pow(rgb.g, DISPLAY_GAMMA_COEFF), 1.)),
                (min(pow(rgb.b, DISPLAY_GAMMA_COEFF), 1.)));
}

vec3 eye = vec3(1, 0.5, 1);
const vec3 target = vec3(0., 0.5, 0);
const vec3 up = vec3(0, 1, 0);
float fov = radians(60.);

const float sampleNum = 50.;
void main(void) {
    calcCircle(PI/(4. + sin(time)), PI/8.);
    eye = vec3(1.5 * cos(time/2.) , 1.5, 1.5 *sin(time/2.));
    const vec2 coordOffset = vec2(0.5);
      vec3 ray = calcRay(eye, target, up, fov,
                       resolution.x, resolution.y,
                       gl_FragCoord.xy + coordOffset);

      glFragColor = vec4(gammaCorrect(calcColor(eye, ray)), 1.);

}
