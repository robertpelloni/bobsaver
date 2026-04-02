#version 420

// original https://www.shadertoy.com/view/4s2yRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Created by soma_arc - 2016
This work is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported.
*/
precision mediump float;

// from Syntopia http://blog.hvidtfeldts.net/index.php/2015/01/path-tracing-3d-fractals/
vec2 rand2n(vec2 co, float sampleIndex) {
    vec2 seed = co * (sampleIndex + 1.0);
    seed+=vec2(-1,1);
    // implementation based on: lumina.sourceforge.net/Tutorials/Noise.html
    return vec2(fract(sin(dot(seed.xy ,vec2(12.9898,78.233))) * 43758.5453),
                 fract(cos(dot(seed.xy ,vec2(4.898,7.23))) * 23421.631));
}

const float EPSILON = 0.0001;
const float PI = 3.14159265;
const float PI_2 = 3.14159265 / 2.;

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

const vec4 K = vec4(1.0, .666666, .333333, 3.0);
vec3 hsv2rgb(const vec3 c){
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

bool intersectBox(vec3 rayOrg, vec3 rayDir, vec3 boxMin, vec3 boxMax,
                  out float hit0, out float hit1) {
    float t0 = -10000.0, t1 = 10000.0;
    hit0 = t0;
    hit1 = t1;
    
    vec3 tNear = (boxMin - rayOrg) / rayDir;
    vec3 tFar  = (boxMax - rayOrg) / rayDir;
    
    if (tNear.x > tFar.x) {
        float tmp = tNear.x;
        tNear.x = tFar.x;
        tFar.x = tmp;
    }
    t0 = max(tNear.x, t0);
    t1 = min(tFar.x, t1);

    if (tNear.y > tFar.y) {
        float tmp = tNear.y;
        tNear.y = tFar.y;
        tFar.y = tmp;
    }
    t0 = max(tNear.y, t0);
    t1 = min(tFar.y, t1);

    if (tNear.z > tFar.z) {
        float tmp = tNear.z;
        tNear.z = tFar.z;
        tFar.z = tmp;
    }
    t0 = max(tNear.z, t0);
    t1 = min(tFar.z, t1);

    if (t0 <= t1) {
        hit0 = t0;
        hit1 = t1;
        return true;
    }
    return false;
}

const vec3 SPHERE_POS1 = vec3(100, 100, 0);
const vec3 SPHERE_POS2 = vec3(100, -100, 0);
const vec3 SPHERE_POS3 = vec3(-100, 100, 0);
const vec3 SPHERE_POS4 = vec3(-100, -100, 0);
const vec3 SPHERE_POS5 = vec3(0, 0, 141.42);
const vec3 SPHERE_POS6 = vec3(0, 0, -141.42);
const float SPHERE_R = 100.;
const float SPHERE_R2 = SPHERE_R * SPHERE_R;

vec3 sphereInvert(vec3 pos, vec3 circlePos, float circleR){
  return ((pos - circlePos) * circleR * circleR)/(distance(pos, circlePos) * distance(pos, circlePos) ) + circlePos;
}

const float MAX_KLEIN_ITARATION = 30.;
float IIS(vec3 pos){
  float loopNum = 0.;
  float dr = 1.;
  bool loopEnd = true;
  for(float i = 0. ; i < MAX_KLEIN_ITARATION ; i++){
    loopEnd = true;
    if(distance(pos, SPHERE_POS1) < SPHERE_R){
      pos = sphereInvert(pos, SPHERE_POS1, SPHERE_R);
      loopEnd = false;
      loopNum++;
    }else if(distance(pos, SPHERE_POS2) < SPHERE_R){
      pos = sphereInvert(pos, SPHERE_POS2, SPHERE_R);
      loopEnd = false;
      loopNum++;
    }else if(distance(pos, SPHERE_POS3) < SPHERE_R){
      pos = sphereInvert(pos, SPHERE_POS3, SPHERE_R);
      loopEnd = false;
      loopNum++;
    }else if(distance(pos, SPHERE_POS4) < SPHERE_R){
      pos = sphereInvert(pos, SPHERE_POS4, SPHERE_R);
      loopEnd = false;
      loopNum++;
    }else if(distance(pos, SPHERE_POS5) < SPHERE_R){
      pos = sphereInvert(pos, SPHERE_POS5, SPHERE_R);
      loopEnd = false;
      loopNum++;
    }else if(distance(pos, SPHERE_POS6) < SPHERE_R){
      pos = sphereInvert(pos, SPHERE_POS6, SPHERE_R);
      loopEnd = false;
      loopNum++;
    }
    if(loopEnd == true) break;
  }
  
  return loopNum;
}

vec4 sampleVolume(vec3 p) {
    float itCount, minDist, maxDist;
    float loopNum = IIS(p);
    if(loopNum == 0.) return vec4(0);
    return vec4(hsv2rgb(vec3(2.5 * loopNum / MAX_KLEIN_ITARATION , 1., 1.)), 
                pow(loopNum / MAX_KLEIN_ITARATION, 1.4));
}

vec3 calcColor(float time, vec3 eye, vec3 ray){
      vec4 l = vec4(0);

    float t0, t1;
       bool hit = intersectBox(eye, ray, 
                            vec3(-250), vec3(250),
                            t0, t1);
    
    if(!hit) return l.rgb;
    
    const float MAX_SAMPLES = 150.;
    float t = t0;
    float tStep = (t1 - t0) / MAX_SAMPLES;
    
    vec3 p0 = eye + t0 * ray;
    vec3 p1 = eye + t1 * ray;
    vec3 distP = p0 - p1;
    float dist = abs(dot(vec3(1, 0, 0), distP));
    dist = max(dist, abs(dot(vec3(0, 1, 0), distP)));
    dist = max(dist, abs(dot(vec3(0, 0, 1), distP)));
    float sliceWidth = .05;
    float samples = floor(dist / sliceWidth) + 1.;
    //tStep = (t1 - t0) / samples;
    samples = MAX_SAMPLES;
    for (float i = 0.; i < MAX_SAMPLES; i++){
        if((min(min(l.x, l.y), l.z)) > 1.0 ||
           l.w > 0.999 ||
           t >= t1 ||
          samples < i) break;
        
        vec3 p = eye + t * ray;
        
        vec4 volCol = sampleVolume(p);
        volCol.a *= 1.;
        volCol.rgb *= volCol.a;
        l = (1. - l.a) * volCol + l;
        
        t += tStep; 
    }
    
      return l.rgb;
}

const float DISPLAY_GAMMA_COEFF = 1. / 2.2;
vec3 gammaCorrect(vec3 rgb) {
  return vec3((min(pow(rgb.r, DISPLAY_GAMMA_COEFF), 1.)),
              (min(pow(rgb.g, DISPLAY_GAMMA_COEFF), 1.)),
              (min(pow(rgb.b, DISPLAY_GAMMA_COEFF), 1.)));
}

const vec3 target = vec3(0, 0, 0);
const vec3 up = vec3(0, 1, 0);
float fov = radians(60.);

const float SAMPLE_NUM = 2.;
void main(void) {
    float r = 400.;
    vec3 eye = vec3(r * sin(time) , r/1.5 * sin(time), 
                    r * cos(time) );
      vec3 sum = vec3(0);
    float t = time;
      for(float i = 0. ; i < SAMPLE_NUM ; i++){
        vec2 coordOffset = rand2n(gl_FragCoord.xy, i);
          
        vec3 ray = calcRay(eye, target, up, fov,
                           resolution.x, resolution.y,
                           gl_FragCoord.xy + coordOffset);
          
        sum += calcColor(t, eye, ray);
      }
     vec3 col = (sum/SAMPLE_NUM);
  
    
      glFragColor = vec4(gammaCorrect(col), 1.);
}
