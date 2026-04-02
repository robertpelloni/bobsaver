#version 420

// original https://www.shadertoy.com/view/wtffDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2020 Patryk Ozga
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions: The above copyright
// notice and this permission notice shall be included in all copies or
// substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS",
// WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
// TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
// THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#define scale 10.

float rand(vec2 co) {
  return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 randPt(vec2 co) {
  float f1 = rand(co);
  float f2 = rand(co * f1);
  return vec2(f1 * .8 + .1, f2 * .8 + .1);
}

vec2 sqPoint(vec2 sq) {
  //float time = 2. * time + 1.;
  //time = 2.;
  //vec2 curPt = randPt(floor(sq) * floor(time));
  //vec2 nextPt = randPt(floor(sq) * floor(time + 1.));
  //return fract(time) * (nextPt - curPt) + curPt;
    if(mod(floor(sq.y),2.) == 0.){
          return vec2(.5, .1 + .8*abs((floor(sq.x)-cos(time))/scale));
    }
    else{
        return vec2(.5,.1 + .4*(1.+cos(2.*3.14*fract(time/5.)))*abs(floor(sq.y))/scale);
    }
}

float sdLine(in vec2 p, in vec2 a, in vec2 b) {
  vec2 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

float distToShade(float d) {
  float time = (1. + .3 * cos(3. * time));
  //time = 1.;
  return smoothstep(0.01, 1., 1. / (100. * time * d));
}

float cross2d(vec2 u, vec2 v) { return u.x * v.y - u.y * v.x; }

float triArea(vec2 a, vec2 b, vec2 c) { return cross2d(b - a, c - a) / 2.; }

const vec3[4] palette = vec3[4](vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67));

const float _2PI = 6.28318;

vec3 pal(in float t, in vec3[4] pal) {
    t *= 2.4;
    t += time/10.;
  return pal[0] + pal[1] * cos(_2PI * (pal[2] * t + pal[3]));
}

void main(void) {
  // Normalized pixel coordinates (from 0 to 1)
  vec2 uv = (-resolution.xy + 2.0 * gl_FragCoord.xy) / resolution.x;

  //float scale = 10.;//= 1.25 *(pow(sin( time/8.) + 4., 1.5));
  //scale = 2.;
  vec2 sq = uv * scale;
  vec2 uvSq = fract(sq);
  vec2 sqPt = sqPoint(sq);
  float c = 0.;
  vec3 col = vec3(0.);
  vec2[] offsets = vec2[](vec2(-1, -1), vec2(-1, 0), vec2(0, 1), vec2(1, 1),
                          vec2(1, 0), vec2(0, -1)
                          // vec2(-1, 1),
                          // vec2(0, 0),
                          // vec2(1, -1),
  );

  vec2 sqPtLast = sqPoint(sq + offsets[5]) + offsets[5];
  for (int i = 0; i < 6; ++i) {
    vec2 off = offsets[i];
    vec2 sq2 = sq + off;
    vec2 sqPt2 = sqPoint(sq2) + off;

    //vec2 triCenter = (sqPt2 + sqPtLast + sqPt) / 3.;

    float a = triArea(sqPt, sqPt2, sqPtLast);
    //col.g += smoothstep(.1, 0., length(triCenter - uvSq));
    float r1 = cross2d(uvSq - sqPt, sqPtLast - sqPt);
    float r2 = cross2d(sqPt2 - sqPt, uvSq - sqPt);
    
      r1 = smoothstep(0., .001, r1);
    r2 = smoothstep(0., .001, r2);
    col += r1 * r2 * pal(a, palette);

    float d = sdLine(uvSq, sqPt, sqPt2);
    c += distToShade(d);

    sqPtLast = sqPt2;
  }

  vec2[] diagOffsets = vec2[](vec2(-1, 0), vec2(0, 1),
                              // vec2(-1, 0), vec2(0, -1),
                              // vec2(1, 0), vec2(0, 1),
                              vec2(1, 0), vec2(0, -1));
  for (int i = 0; i < 4; i += 2) {
    vec2 off1 = diagOffsets[ i];
    vec2 sq1 = sq + off1;
    vec2 sqPt1 = sqPoint(sq1) + off1;
    vec2 vPt1 = sqPt1 - uvSq;

    vec2 off2 = diagOffsets[ i + 1];
    vec2 sq2 = sq + off2;
    vec2 sqPt2 = sqPoint(sq2) + off2;

    vec2 off3 = vec2(off1.x, off2.y);
    vec2 sq3 = sq + off3;
    vec2 sqPt3 = sqPoint(sq3) + off3;

    float a = triArea(sqPt1,sqPt2, sqPt3);
    
    float r1 = cross2d(uvSq - sqPt2, sqPt1 - sqPt2);
    float r2 = smoothstep(.01, 0., r1);
    r1 = smoothstep(0., .001, r1);
    col *= r2;
    col += r1*pal(a, palette);

    float d = sdLine(uvSq, sqPt1, sqPt2);
    c += distToShade(d);
  }

  col -= vec3(c);
  glFragColor = vec4(col, 1.);
}
