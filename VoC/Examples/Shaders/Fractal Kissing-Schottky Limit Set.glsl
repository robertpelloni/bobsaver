#version 420

// original https://www.shadertoy.com/view/4lBSDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Created by soma_arc, Kazushi Ahara - 2015
This work is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported.
*/

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
const float commonCircleR = 100.;
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

vec2 circleInverse(vec2 pos, vec2 circlePos, float circleR){
    return ((pos - circlePos) * circleR * circleR)/(length(pos - circlePos) * length(pos - circlePos) ) + circlePos;
}

const int ITERATIONS = 30;
float loopNum = 0.;
float DE(vec2 pos){
    bool cont = false;
    for(int i = 0 ; i < ITERATIONS ; i++){
        cont = false;
        if(length(pos - c1Pos) < c1R){
            pos = circleInverse(pos, c1Pos, c1R);
            cont = true;
            loopNum++;
        }else if(length(pos - c2Pos) < c2R){
            pos = circleInverse(pos, c2Pos, c2R);
            cont = true;
            loopNum++;
        }else if(length(pos - c3Pos) < c3R){
            pos = circleInverse(pos, c3Pos, c3R);
            cont = true;
            loopNum++;
        }else if(length(pos - c4Pos) < c4R){
            pos = circleInverse(pos, c4Pos, c4R);
            cont = true;
            loopNum++;
        }
        if(cont == false) break;
    }

    return length(pos) - commonCircleR;
}

void main(void)
{
    vec2 position = ( gl_FragCoord.xy / resolution.xy ) - vec2(0.5, 0.5);
    position = position * 600.;

    calcContactCircles(commonCirclePos, commonCircleR);

    float d = DE(position);
    
    if(d < 0.01){
        glFragColor = vec4(0., 0.5 + loopNum/10., 0.4 + loopNum/10., 1.0 );
    }else{
        glFragColor = vec4(0.,0.,0.,1.);
    }
}
