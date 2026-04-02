#version 420

// original https://www.shadertoy.com/view/XsGGWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Created by soma_arc - 2016
This work is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported.
*/

const float MTL_PSEUDO_KLEINIAN = 1.;
const float MTL_KLEIN = 2.;

vec2 opUnion(const vec2 d1, const vec2 d2){
  return (d1.x < d2.x) ? d1 : d2;
}

const vec3 ROTATION_AXIS = normalize(vec3(0.1, 1, 0.5));
vec3 rotate(vec3 p, float angle){
  float s = sin(angle);
  float c = cos(angle);
  float r = 1.0 - c;
  mat3 m = mat3(ROTATION_AXIS.x * ROTATION_AXIS.x * r + c,
                ROTATION_AXIS.y * ROTATION_AXIS.x * r + ROTATION_AXIS.z * s,
                ROTATION_AXIS.z * ROTATION_AXIS.x * r - ROTATION_AXIS.y * s,
                ROTATION_AXIS.x * ROTATION_AXIS.y * r - ROTATION_AXIS.z * s,
                ROTATION_AXIS.y * ROTATION_AXIS.y * r + c,
                ROTATION_AXIS.z * ROTATION_AXIS.y * r + ROTATION_AXIS.x * s,
                ROTATION_AXIS.x * ROTATION_AXIS.z * r + ROTATION_AXIS.y * s,
                ROTATION_AXIS.y * ROTATION_AXIS.z * r - ROTATION_AXIS.x * s,
                ROTATION_AXIS.z * ROTATION_AXIS.z * r + c);
  return m * p;
}

const vec3 spherePos1 = vec3(5, 5, 0);
const vec3 spherePos2 = vec3(5, -5, 0);
const vec3 spherePos3 = vec3(-5, 5, 0);
const vec3 spherePos4 = vec3(-5, -5, 0);
const vec3 spherePos5 = vec3(0, 0, 7.071);
const vec3 spherePos6 = vec3(0, 0, -7.071);
const float SPHERE_R = 5.;
const float SPHERE_R2 = SPHERE_R * SPHERE_R;

int kleinIteration = 8;
float kleinSphereR = 5.;
float loopNum = 0.;
const int SPHERE_NUM = 6;
const vec3 KLEIN_POS = vec3(0, 0, -5);
const int MAX_KLEIN_ITARATION = 20;
const vec4 INITIAL_SP = vec4(-1.);
vec2 distKlein(vec3 pos){
  pos = rotate(pos + KLEIN_POS, radians(time * 30.));
  loopNum = 0.;
  float dr = 1.;
  vec4 sp;
  for(int i = 0 ; i < MAX_KLEIN_ITARATION ; i++){
    if(i > kleinIteration) break;
    sp = INITIAL_SP;

    float d = distance(pos, spherePos1);
    sp = (d < SPHERE_R) ? vec4(spherePos1, d) : sp;
    d = distance(pos, spherePos2);
    sp = (d < SPHERE_R) ? vec4(spherePos2, d) : sp;
    d = distance(pos, spherePos3);
    sp = (d < SPHERE_R) ? vec4(spherePos3, d) : sp;
    d = distance(pos, spherePos4);
    sp = (d < SPHERE_R) ? vec4(spherePos4, d) : sp;
    d = distance(pos, spherePos5);
    sp = (d < SPHERE_R) ? vec4(spherePos5, d) : sp;
    d = distance(pos, spherePos6);
    sp = (d < SPHERE_R) ? vec4(spherePos6, d) : sp;

    if(sp.x == -1.){
      break;
    }else{
      vec3 diff = (pos - sp.xyz);
      dr *= SPHERE_R2 / dot(diff, diff);
      pos = (diff * SPHERE_R2)/(sp.w * sp.w) + sp.xyz;
      loopNum++;
    }
  }
  return vec2((length(pos) - kleinSphereR) / abs(dr) * 0.08, MTL_KLEIN);
}

vec3 orb;
const vec3 PSEUDO_KLEINIAN_POS = vec3(10, 6, 2.5);
const vec3 TRAP_POINT = vec3(1000.);
const vec3 PSEUDO_KLEINIAN_CUBE_SIZE = vec3(9.2436, 9.0756, 9.2436);
const float PSEUDO_KLEINIAN_SIZE = 110.;
vec2 distPseudoKleinian(vec3 p){
  orb = TRAP_POINT;
  p = p + PSEUDO_KLEINIAN_POS;
  float DEfactor = 1.;
  vec3 ap = p + 1.;
  for(int i = 0; i < 7 ; i++){
    ap = p;
    p= -p + 2. * clamp(p, -PSEUDO_KLEINIAN_CUBE_SIZE, PSEUDO_KLEINIAN_CUBE_SIZE);
    orb = min( orb, vec3(abs(p)));
    float k = PSEUDO_KLEINIAN_SIZE / dot(p, p);
    p *= k;
    DEfactor *= k;
  }
  return vec2(abs(0.5*abs(p.z)/DEfactor), MTL_PSEUDO_KLEINIAN);
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

const vec4 K = vec4(1.0, .666666, .333333, 3.0);
vec3 hsv2rgb(const vec3 c){
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 eye = vec3(0, 0, 800);
vec3 target = vec3(0, 0, 7);
const vec3 up = vec3(0, 1, 0);
//const float fov = radians(60.0);
const float fov = 1.04719;

vec2 distFunc(vec3 p){
  return opUnion(distPseudoKleinian(p), distKlein(p));;
}

const vec2 d = vec2(0.01, 0.);
vec3 getNormal(const vec3 p){
  return normalize(vec3(distFunc(p + d.xyy).x - distFunc(p - d.xyy).x,
                        distFunc(p + d.yxy).x - distFunc(p - d.yxy).x,
                        distFunc(p + d.yyx).x - distFunc(p - d.yyx).x));
}

const float PI_4 = 12.566368;
const vec3 LIGHTING_FACT = vec3(0.1);
vec3 diffuseLighting(const vec3 p, const vec3 n, const vec3 diffuseColor,
                     const vec3 lightPos, const vec3 lightPower){
  vec3 v = lightPos - p;
  float dot = dot(n, normalize(v));
  float r = length(v);
  return (dot > 0.) ?
    (lightPower * (dot / (PI_4 * r * r))) * diffuseColor
    : LIGHTING_FACT * diffuseColor;
}

const vec3 LIGHT_POS1 = vec3(100., 100., 100.);
const vec3 LIGHT_POS2 = vec3(-100., -100., -100);
const vec3 LIGHT_POWER1 = vec3(10.);
const vec3 LIGHT_POWER2 = vec3(10.);

vec3 lighting(const float kd, const vec3 matColor, vec3 l,
              const vec3 intersection, const vec3 normal){
  return (kd > 0.) ?
    l + (diffuseLighting(intersection, normal, matColor,
                         LIGHT_POS1, LIGHT_POWER1) * kd) +
    (diffuseLighting(intersection, normal, matColor,
                     LIGHT_POS2, LIGHT_POWER2) * kd)
    : l;
}

const int MAX_MARCHING_LOOP = 700;
vec3 march(const vec3 origin, const  vec3 ray, const float threshold){
  vec3 rayPos = origin;
  vec2 dist = vec2(0., -1);
  float rayLength = 0.;
  for(int i = 0 ; i < MAX_MARCHING_LOOP ; i++){
    dist = distFunc(rayPos);
    rayLength += dist.x;
    rayPos = origin + ray * rayLength ;
    if(dist.x < threshold) break;
  }
  return vec3(dist, rayLength);
}

const float FOG_START = 10.;
const float FOG_END = 100.;
const float FOG_END_START_RECIPROCAL = 1. / (FOG_END - FOG_START);
const vec3 FOG_F = vec3(1.);
const vec3 BLACK = vec3(0);
int reflectNum = 3;
vec3 trace(vec3 eye, vec3 ray){
  vec3 l = BLACK;
  float coeff = 1.;
  for(int depth = 0 ; depth < 5 ; depth++){
    if(depth >= reflectNum) break;
    float threshold = 0.003 * pow(1.3 , float(depth));
    vec3 result = march(eye, ray, threshold);
    vec3 intersection = eye + ray * result.z;
    vec3 matColor = vec3(0);
    vec3 normal = getNormal(intersection);
    if(result.x < threshold){
      float ks = 0.;
      if(result.y == MTL_KLEIN){
        ks = (loopNum < 4.) ? 0.5 * coeff : 0.;
        matColor = hsv2rgb(vec3(0.1 + loopNum * 0.1 , 1., 1.));
      }else{
        matColor = vec3(clamp(6.0*orb.y,0.0,1.0), clamp(1.0-2.0*orb.z,0.0,1.0), .5);
        ks = (matColor.r > 0.8 &&
              matColor.g > 0.8 ) ? 0.8 * coeff : 0.;
      }

      if(ks > 0.){
        l = mix(FOG_F, lighting(1. - ks, matColor, l, intersection, normal),
                clamp((FOG_END - result.z) * FOG_END_START_RECIPROCAL, 0.5, 1.0));
        coeff = ks;
        eye = eye + ray * result.z * 0.9;
        ray = reflect(ray, normal);
      }else{
        l = mix(FOG_F, lighting(1. - ks, matColor, l, intersection, normal),
                clamp((FOG_END - result.z) * FOG_END_START_RECIPROCAL, 0.5, 1.0));
        break;
      }
    }else{
        l = mix(FOG_F, l, clamp((FOG_END - result.z) * FOG_END_START_RECIPROCAL, 0.5, 1.0));
      break;
    }
  }
  return l;
}

void expandSphere(const float t,
                  const float minR, const float maxR, const int iteration){
  kleinIteration = iteration;
  kleinSphereR = mix(minR, maxR,
                     smoothstep(minR, maxR, t));
}

void shrinkSphere(const float t,
                  const float minR, const float maxR, const int iteration){
  kleinIteration = iteration;
  kleinSphereR = mix(maxR, minR,
                     smoothstep(minR, maxR, minR + t));
}

const float DISPLAY_GAMMA_COEFF = 1. / 2.2;
vec3 gammaCorrect(vec3 rgb) {
  return vec3((min(pow(rgb.r, DISPLAY_GAMMA_COEFF), 1.)),
              (min(pow(rgb.g, DISPLAY_GAMMA_COEFF), 1.)),
              (min(pow(rgb.b, DISPLAY_GAMMA_COEFF), 1.)));
}

const float EYE_RAD = 8.9;
void main(void) {
  float t = mod(time, 85.);
  const float minR = 0.;
  const float maxR = 3.;
  vec3 eye = vec3(EYE_RAD * sin(time), 0., 7. + EYE_RAD *  cos(time));
  target = -(eye - target);
  if(t < 3.){
    expandSphere(t, minR, maxR, 0);
  }else if(t < 6.){
    shrinkSphere(t - 3., minR, maxR, 0);
  }else if(t < 9.){
    expandSphere(t - 6., minR, maxR, 1);
  }else if(t < 12.){
    shrinkSphere(t - 9., minR, maxR, 1);
  }else if(t < 15.){
    expandSphere(t - 12., minR, maxR, 2);
  }else if(t < 18.){
    shrinkSphere(t - 15., minR, maxR, 2);
  }else if(t < 21.){
    expandSphere(t - 18., minR, maxR, 3);
  }else if(t < 24.){
    shrinkSphere(t - 21., minR, maxR, 3);
  }else if(t < 27.){
    expandSphere(t - 24., minR, maxR, 4);
  }else if(t < 30.){
    shrinkSphere(t - 27., minR, maxR, 4);
  }else if(t < 40.){
    expandSphere(t - 30., minR, 5., 12);
    reflectNum = 4;
  }else if(t < 55.){
    expandSphere(t - 40., 5., 6.3, 12);
    reflectNum = 4;
  }else if(t < 65.){
    shrinkSphere(t - 55., 2.0833, 6.5, 8);
  }else if(t < 70.){
    shrinkSphere(t - 65., minR, 2.0833, 8);
  }else if(t < 71.){
    kleinSphereR = 0.;
    kleinIteration = 7;
  }else if(t < 72.){
    kleinSphereR = 0.;
    kleinIteration = 6;
  }else if(t < 73.){
    kleinSphereR = 0.;
    kleinIteration = 5;
  }else if(t < 76.){
    kleinSphereR = 0.;
    kleinIteration = 4;
  }else if(t < 78.){
    kleinSphereR = 0.;
    kleinIteration = 3;
  }else if(t < 80.){
    kleinSphereR = 0.;
    kleinIteration = 2;
  }else if(t < 82.){
    kleinSphereR = 0.;
    kleinIteration = 1;
  }else{
    kleinSphereR = 0.;
    kleinIteration = 0;
  }
  const vec2 coordOffset = vec2(0.5);
  vec3 ray = calcRay(eye, target, up, fov,
                     resolution.x, resolution.y,
                     gl_FragCoord.xy + coordOffset);

  glFragColor = vec4(gammaCorrect(trace(eye, ray)), 1.);
  //glFragColor = 1.0-vec4(gammaCorrect(trace(eye, ray)), 1.);
  //glFragColor = 0.5-vec4(trace(eye, ray), 1.);
}
