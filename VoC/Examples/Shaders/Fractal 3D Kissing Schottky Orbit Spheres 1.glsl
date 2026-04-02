#version 420

// original https://www.shadertoy.com/view/MtjXDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Created by soma_arc, Kazushi Ahara - 2015
This work is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported.
*/

const float PI = 3.14159265;
const float angle = 60.0;
const float fov = angle * 0.5 * PI / 180.0;
const vec3  cPos = vec3(0.0, 0.0, 600.0);
const vec3 lightDir = vec3(-0.577, 0.577, 0.577);

const vec3 spherePos1 = vec3(300, 300, 0);
const vec3 spherePos2 = vec3(300, -300, 0);
const vec3 spherePos3 = vec3(-300, 300, 0);
const vec3 spherePos4 = vec3(-300, -300, 0);
const vec3 spherePos5 = vec3(0, 0, 424.26);
const vec3 spherePos6 = vec3(0, 0, -424.26);
const float sphereR = 300.;

vec3 rotate(vec3 p, float angle, vec3 axis){
  vec3 a = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float r = 1.0 - c;
  mat3 m = mat3(
      a.x * a.x * r + c,
      a.y * a.x * r + a.z * s,
      a.z * a.x * r - a.y * s,
      a.x * a.y * r - a.z * s,
      a.y * a.y * r + c,
      a.z * a.y * r + a.x * s,
      a.x * a.z * r + a.y * s,
      a.y * a.z * r - a.x * s,
      a.z * a.z * r + c
  );
  return m * p;
}

vec3 sphereInverse(vec3 pos, vec3 circlePos, float circleR){
  return ((pos - circlePos) * circleR * circleR)/(distance(pos, circlePos) * distance(pos, circlePos) ) + circlePos;
}

const int ITERATIONS = 30;
float loopNum = 0.;
const vec3 ROTATION = vec3(1.0, 0.5, 0.5);
float DE(vec3 pos){
  pos = rotate(pos, radians(time * 10.0), ROTATION);
  bool cont = false;
  for(int i = 0 ; i < ITERATIONS ; i++){
    cont = false;
    if(distance(pos, spherePos1) < sphereR){
      pos = sphereInverse(pos, spherePos1, sphereR);
      cont = true;
      loopNum++;
    }else if(distance(pos, spherePos2) < sphereR){
      pos = sphereInverse(pos, spherePos2, sphereR);
      cont = true;
      loopNum++;
    }else if(distance(pos, spherePos3) < sphereR){
      pos = sphereInverse(pos, spherePos3, sphereR);
      cont = true;
      loopNum++;
    }else if(distance(pos, spherePos4) < sphereR){
      pos = sphereInverse(pos, spherePos4, sphereR);
      cont = true;
      loopNum++;
    }else if(distance(pos, spherePos5) < sphereR){
      pos = sphereInverse(pos, spherePos5, sphereR);
      cont = true;
      loopNum++;
    }else if(distance(pos, spherePos6) < sphereR){
      pos = sphereInverse(pos, spherePos6, sphereR);
      cont = true;
      loopNum++;
    }
    if(cont == false) break;
  }

  return 0.01 * (length(pos) - 125.);
}

vec3 getNormal(vec3 p){
  float d = 0.01;
  return normalize(vec3(
      DE(p + vec3(  d, 0.0, 0.0)) - DE(p + vec3( -d, 0.0, 0.0)),
      DE(p + vec3(0.0,   d, 0.0)) - DE(p + vec3(0.0,  -d, 0.0)),
      DE(p + vec3(0.0, 0.0,   d)) - DE(p + vec3(0.0, 0.0,  -d))
  ));
}

const int MARCHING_LOOP = 850;
void main(void)
{
  vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
  vec3 ray = normalize(vec3(sin(fov) * p.x, sin(fov) * p.y, -cos(fov)));

  float dist = 0.0;
  float rLen = 0.0;
  vec3  rPos = cPos;

  float numMarch = 0.;
  for(int i = 0; i < MARCHING_LOOP; i++){
    dist = DE(rPos);
    rLen += dist;
    rPos = cPos + ray * rLen;
    numMarch++;
    if(dist < 0.1) break;
  }

  if(dist < 0.1){
    vec3 normal = getNormal(rPos);
    float diff = clamp(dot(lightDir, normal), 0.1, 1.0);        
    glFragColor = vec4(vec3(diff), 1.0);
  }else{
    glFragColor = vec4(0.,0.,0.,1.);
  }
}
