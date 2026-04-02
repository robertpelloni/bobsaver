#version 420

// original https://www.shadertoy.com/view/MsVSRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Created by soma_arc - 2016
This work is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported.
*/

const float PI = 3.14159265;
const vec2 c1Pos = vec2(0, 1);
const vec2 c2Pos = vec2(4, 4);
const vec2 c3Pos = vec2(-4, 4);
const float c1R = 1.;
const float c2R = 4.;
const float c3R = 4.;

vec2 circleInverse(vec2 pos, vec2 circlePos, float circleR){
    float d = distance(pos, circlePos);
    return ((pos - circlePos) * circleR * circleR)/(d*d) + circlePos;
}

float loopNum = 0.;
const int ITERATIONS = 6;
float IIS(vec2 pos){
    loopNum = 0.;
    bool cont = false;
    for(int i = 0 ; i < ITERATIONS ; i++){
        cont = false;
        if(distance(pos,c1Pos) < c1R){
            pos = circleInverse(pos, c1Pos, c1R);
            cont = true;
            loopNum++;
        }else if(distance(pos, c2Pos) < c2R){
            pos = circleInverse(pos, c2Pos, c2R);
            cont = true;
            loopNum++;
        }else if(distance(pos, c3Pos) < c3R){
            pos = circleInverse(pos, c3Pos, c3R);
            cont = true;
            loopNum++;
        }else if(pos.y < 0.){
            pos = vec2(pos.x, -pos.y);
            cont = true;
            loopNum++;
        }
        if(cont == false) break;
    }
    if(length(pos) < 3.5)
        return float(ITERATIONS) + abs(loopNum - float(ITERATIONS));
    return loopNum;
}

float calcHeight(vec2 p){
    return IIS(p) * .8;
}

const vec3 BLACK = vec3(0);
float march(vec3 rayOrigin, vec3 rayDir){
    const float delt = 0.02;
    const float mint = .01;
    const float maxt = 50.;
    for( float t = mint; t < maxt; t += delt ) {
        vec3 p = rayOrigin + rayDir * t;
        if(p.y < calcHeight(p.xz)) {
            return t - 0.5 * delt;
        }
    }
    return -1.;
}

const vec2 d = vec2(0.01, 0.);
vec3 calcNormal(const vec3 p){
  return normalize(vec3(calcHeight(p.xz - d.xy) - calcHeight(p.xz + d.xy),
                         2. * d.x,
                         calcHeight(p.xz - d.yx) - calcHeight(p.xz + d.yx)));
}

const float PI_4 = 12.566368;
vec3 diffuseLighting(const vec3 p, const vec3 n, const vec3 diffuseColor,
                     const vec3 lightPos, const vec3 lightPower){
      vec3 v = lightPos - p;
      float d = dot(n, normalize(v));
      float r = length(v);
      return (d > 0. ) ?
        (lightPower * (d / (PI_4 * r * r))) * diffuseColor
        : vec3(0.);
}

vec3 hsv2rgb(vec3 c){
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

const vec3 lightPos = vec3(0, 100, 0);
const vec3 lightPower = vec3(50000.);
vec3 calcColor(vec3 eye, vec3 ray){
      vec3 l = BLACK;
      float coeff = 1.;
    float t = march(eye, ray);
      
    //if(t > 0.){
        vec3 intersection = eye + ray * t;
        vec3 normal = calcNormal(intersection);
        vec3 matColor = intersection.y <= 0.1 ? vec3(0):vec3(hsv2rgb(vec3((loopNum -.5)/ 7. ,1., 1.)));
           l += diffuseLighting(intersection, normal, matColor, lightPos, lightPower);
    //}
      return l;
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

const vec3 up = vec3(0, 1, 0);
float fov = radians(60.);
void main(void) {
    float t = time;
    t -= 2.9;
    vec3 target = vec3(0., 0, 0);
    vec3 eye;
    target = vec3(sin(t), 0., 0.);
    eye = vec3(cos(t) + sin(t) * cos(t),
               6.5 + 9. * abs(cos(t)),
               1. + 5. * sin(t));
    const vec2 coordOffset = vec2(0.5);
      vec3 ray = calcRay(eye, target, up, fov,
                       resolution.x, resolution.y,
                       gl_FragCoord.xy + coordOffset);

      glFragColor = vec4(gammaCorrect(calcColor(eye, ray)), 1.);

}
