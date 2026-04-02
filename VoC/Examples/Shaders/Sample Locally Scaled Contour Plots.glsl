#version 420

// original https://www.shadertoy.com/view/tsycWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Ricky Reusser
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// This function draws a contour plot, using the logarithmic (relative)
// gradient to select locally appropriate contour spacing. Click to show
// colors representing regions of a given spacing.
//
// For a version that blends between octaves, see: https://www.shadertoy.com/view/wsGyDV
// For a version with shading, see: https://www.shadertoy.com/view/tsyyDV

//const float minSpacing = 15.0;
const float divisions = 2.0;
const float lineWidth = 1.0;
const float antialiasWidth = 1.5;

// Complex division, semi-floating-point-carefully
vec2 cdiv (vec2 a, vec2 b) {
  float e, f;
  float g = 1.0;
  float h = 1.0;
  if( abs(b.x) >= abs(b.y) ) {
    e = b.y / b.x;
    f = b.x + b.y * e;
    h = e;
  } else {
    e = b.x / b.y;
    f = b.x * e + b.y;
    g = e;
  }
  return (a * g + h * vec2(a.y, -a.x)) / f;
}

// Complex multiplication
vec2 cmul (vec2 a, vec2 b) {
  return vec2(
    a.x * b.x - a.y * b.y,
    a.y * b.x + a.x * b.y
  );
}

// Floating-point-aware hypot function, algebraically equivalent to `length(vec2)`
float hypot (vec2 z) {
  float x = abs(z.x);
  float y = abs(z.y);
  float t = min(x, y);
  x = max(x, y);
  t = t / x;
  return x * sqrt(1.0 + t * t);
}

#define PI 3.14

vec3 randoColor (float x) {
    return 0.5 + 0.5 * vec3(cos(x), cos(x - PI * 2.0 / 3.0), cos(x - PI * 4.0 / 3.0));
}

// Draws contours which adjust to the local relative rate of change
//              f: input to be contoured
//       gradient: screen-space gradient of the input f
//     minSpacing: Smallest contour spacing, in (approximate) pixels
//      divisions: Number of divisions per size increment
//      lineWidth: Line width, in pixels
// antialiasWidth: Width of antialiasing blur
float locallyScaledLogContours (float f, vec2 gradient, float minSpacing, float divisions, float lineWidth,
 float antialiasWidth) {
    float screenSpaceLogGrad = hypot(gradient) / f;
    float localOctave = ceil(log2(screenSpaceLogGrad * minSpacing) / log2(divisions));
    float contourSpacing = pow(divisions, localOctave);
    float plotVar = log2(f) / contourSpacing;
    float widthScale = 0.5 * contourSpacing / screenSpaceLogGrad;

    return smoothstep(
        0.5 * (lineWidth + antialiasWidth),
        0.5 * (lineWidth - antialiasWidth),
        (0.5 - abs(fract(plotVar) - 0.5)) * widthScale
    );
}

vec2 sampleFunction (vec2 z, vec2 zMouse) {
  return cmul(cdiv(z - vec2(1, 0), z + vec2(1, 0)), z - zMouse);
}

// To show what's going on, add color when clicking
vec3 octaveColorDebug (float f, vec2 gradient, float minSpacing, float divisions) {
    float screenSpaceLogGrad = hypot(gradient) / f;
    float localOctave = ceil(log2(screenSpaceLogGrad * minSpacing) / log2(divisions));
    return randoColor(localOctave);
}

// Frag coord to some nice plot range
vec2 viewport (vec2 ij) {
    return 4.0 * vec2(1, resolution.y / resolution.x) * (ij / resolution.xy - 0.5);
}

void main(void) {
    vec2 z = viewport(gl_FragCoord.xy);
    vec2 zMouse = vec2(1.2 * cos(0.5 * time), 0.5 * sin(time));

    vec2 f = sampleFunction(z, zMouse);
    
    float minSpacing = resolution.x / 50.0;
    
    // The gradient and its magnitude:
    float fMag = hypot(f);
    vec2 fMagGradient = vec2(dFdx(fMag), dFdy(fMag));
    
    vec3 debugColor = vec3(1);
    float contour = 1.0 - locallyScaledLogContours(fMag, fMagGradient, minSpacing, divisions, lineWidth, antialiasWidth);

    glFragColor = vec4(pow(contour * debugColor, vec3(0.454)),1.0);
}
