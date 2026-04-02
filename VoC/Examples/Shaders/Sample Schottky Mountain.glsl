#version 420

// original https://www.shadertoy.com/view/4sdGWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Created by soma_arc - 2016
This work is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported.
*/

const float PI = 3.14159265;
vec2 circleInverse(vec2 pos, vec2 circlePos, float circleR){
    return ((pos - circlePos) * circleR * circleR)/(length(pos - circlePos) * length(pos - circlePos) ) + circlePos;
}

float LINE_THRESHOLD = 0.0001;
vec3 getLine(vec2 p1, vec2 p2){
  float xDiff = p2.x - p1.x;
  float yDiff = p2.y - p1.y;
  if(abs(xDiff) < LINE_THRESHOLD){
    //x = c
    return vec3(1, 0, p1.x);
  }else if(abs(yDiff) < LINE_THRESHOLD){
    //y = c
    return vec3(0, 1, p1.y);
  }else{
    //y = ax + b
    return vec3(yDiff / xDiff, p1.y - p1.x * (yDiff / xDiff), 0);
  }
}

float calcX(vec3 line, float y){
  if(line.z == 0.){
    return (y - line.y) / line.x;
  }else{
    return line.z;
  }
}

float calcY(vec3 line, float x){
  if(line.z == 0.){
    return line.x * x + line.y;
  }else{
    return line.z;
  }
}

vec2 calcIntersection(vec3 line1, vec3 line2){
  if(line1.z == 0. && line2.z == 0.){
    float x1 = 1.;
    float x2 = 5.;
    float y1 = calcY(line1, x1);
    float y2 = calcY(line1, x2);

    float x3 = 4.;
    float x4 = 8.;
    float y3 = calcY(line2, x3);
    float y4 = calcY(line2, x4);

    float ksi   = ( y4-y3 )*( x4-x1 ) - ( x4-x3 )*( y4-y1 );
    float eta   = ( x2-x1 )*( y4-y1 ) - ( y2-y1 )*( x4-x1 );
    float delta = ( x2-x1 )*( y4-y3 ) - ( y2-y1 )*( x4-x3 );

    float lambda = ksi / delta;
    float mu    = eta / delta;
    return vec2(x1 + lambda*( x2-x1 ), y1 + lambda*( y2-y1 ));
  }else{
    if(line1.x == 1.){
      return vec2(line1.z, calcY(line2, line1.z));
    }else if(line1.y == 1.){
      return vec2(calcX(line2, line1.z), line1.z);
    }else if(line2.x == 1.){
      return vec2(line2.z, calcY(line1, line2.z));
    }
    return vec2(calcX(line1, line2.z), line2.z);
  }
}

const vec2 commonCirclePos = vec2(0, 0);
const float commonCircleR = 10.;
const vec2 p = commonCirclePos + vec2(0, commonCircleR);
const vec2 q = commonCirclePos + vec2(-commonCircleR, 0);
const vec2 r = commonCirclePos + vec2(0, -commonCircleR);
const vec2 s = commonCirclePos + vec2(commonCircleR, 0);

vec2 c1Pos, c2Pos, c3Pos, c4Pos;
float c1R, c2R, c3R, c4R;

void calcContactCircles(vec2 commonCirclePos, float commonCircleR){
  vec2 pqMid = (p + q)/2.;
  vec2 u = (pqMid - commonCirclePos)/distance(commonCirclePos, pqMid);
  vec2 a = u * commonCircleR * (sin(time) * 6. + 6.72) + commonCirclePos;
  c1Pos = a;
  c1R = distance(a, p);

  vec3 aq = getLine(a, q);
  vec3 qrMidPer = getLine(commonCirclePos, (q + r) / 2.);
  vec2 b = calcIntersection(aq, qrMidPer);
  c2Pos = b;
  c2R = distance(b, q);

  vec3 br = getLine(b, r);
  vec3 rsMidPer = getLine(commonCirclePos, (r + s) / 2.);
  vec2 c = calcIntersection(br, rsMidPer);
  c3Pos = c;
  c3R = distance(c, r);

  vec3 cs = getLine(c, s);
  vec3 spMidPer = getLine(commonCirclePos, (s + p) / 2.);
  vec2 d = calcIntersection(cs, spMidPer);
  c4Pos = d;
  c4R = distance(d, s);
}

float loopNum = 0.;
const int ITERATIONS = 6;
float IIS(vec2 pos){
    loopNum = 0.;
    bool cont = false;
    for(int i = 0 ; i < ITERATIONS ; i++){
        cont = false;
        if(distance(pos, c1Pos) < c1R){
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
        }else if(distance(pos, c4Pos) < c4R){
            pos = circleInverse(pos, c4Pos, c4R);
            cont = true;
            loopNum++;
        }
        if(cont == false) break;
    }
    if(length(pos) < commonCircleR)
        return float(ITERATIONS) + abs(loopNum - float(ITERATIONS));
    return loopNum;
}

float calcHeight(vec2 p){
    return IIS(p) * 1.3;
}

const vec3 BLACK = vec3(0);
float march(vec3 rayOrigin, vec3 rayDir){
    const float delt = 0.04;
    const float mint = 3.;
    const float maxt = 100.;
    for( float t = mint; t < maxt; t += delt ) {
        vec3 p = rayOrigin + rayDir * t;
        if( p.y < calcHeight(p.xz)) {
            return t - 0.5 * delt;
        }
    }
    return maxt;
}

const vec2 d = vec2(0.1, 0.);
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
        vec3 matColor = vec3(hsv2rgb(vec3(loopNum / 10. ,1., 1.)));
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

const vec3 target = vec3(0., 0, 0);
const vec3 up = vec3(0, 1, 0);
float fov = radians(60.);

const float sampleNum = 50.;
void main(void) {
    calcContactCircles(commonCirclePos, commonCircleR);
    vec3 eye = vec3(15. * cos(time/2.) , 25. + 15. * (sin(time)), 15. *sin(time/2.));
    const vec2 coordOffset = vec2(0.5);
      vec3 ray = calcRay(eye, target, up, fov,
                       resolution.x, resolution.y,
                       gl_FragCoord.xy + coordOffset);

      glFragColor = vec4(gammaCorrect(calcColor(eye, ray)), 1.);

}
