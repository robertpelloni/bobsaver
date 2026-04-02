#version 420

// original https://www.shadertoy.com/view/fdjXRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 * Complex domain coloring
 * Copyright 2019 Ricky Reusser. MIT License.
 *
 * See Common tab for cubehelix license: 
 * https://github.com/d3/d3-color
 * Copyright 2010-2016 Mike Bostock
 *
 * Features:
 *
 * - Adaptively selects and blends multiple octaves for polar phase and
 *   magnitude of a complex analytic function.
 *
 * - Antialiased grid lines
 *
 * - Antialiased shading
 * 
 * - Partial implementation of automatic differentiation for avoiding
 *   standard derivatives (in the end standard derivatives are so easy and
 *   the anisotropy is not overwhelming, so why overcomplicate things?)
 * 
 * - Avoids some (though not all?) preventable overflow/underflow via the
 *   `hypot` function instead of `length`
 *
 * TO DO:
 *
 * - fix gamma/colorspace usage (well, *non-usage*, to be precise)
 *
 * - add switch for rectangular contours
 *
 */

// Complex math! Beware that these functions are not all great for overflow,
// even though a GPU is precisely the sort of place where you ought to be 
// *very* concerned about overflow.
//
// This also includes a partial implementation of automatic differentiation
// for complex arithmetic using vec4 as a + bi --> vec4(a, b, da, db). This
// may be used to successfully avoid standard derivatives, though I just
// didn't find it worthwhile when standard derivatives are so easy and well
// supported.

#define PI 3.141592653589793238
#define TO_RADIANS 0.01745329251
#define HALF_PI 1.57079633
#define HALF_PI_INV 0.15915494309
#define PI_INV 0.31830988618
#define TWO_PI 6.28318530718

float hypot (vec2 z) {
  float x = abs(z.x);
  float y = abs(z.y);
  float t = min(x, y);
  x = max(x, y);
  t = t / x;
  return x * sqrt(1.0 + t * t);
}

vec2 cadd (vec2 a, vec2 b) {
  return a + b;
}

vec2 csub (vec2 a, vec2 b) {
  return a - b;
}

float cmod (vec2 z) {
  return hypot(z);
} 

vec2 csqrt (vec2 z) {
  float t = sqrt(2.0 * (cmod(z) + (z.x >= 0.0 ? z.x : -z.x)));
  vec2 f = vec2(0.5 * t, abs(z.y) / t);

  if (z.x < 0.0) f.xy = f.yx;
  if (z.y < 0.0) f.y = -f.y;

  return f;
}

/*
float sinh (float x) {
  return 0.5 * (exp(x) - exp(-x));
}

float cosh (float x) {
  return 0.5 * (exp(x) + exp(-x));
}*/

vec2 sinhcosh (float x) {
  vec2 ex = exp(vec2(x, -x));
  return 0.5 * (ex - vec2(ex.y, -ex.x));
}

float cabs (vec2 z) {
  return cmod(z);
}

vec2 clog(vec2 z) {
  return vec2(
    log(hypot(z)),
    atan(z.y, z.x)
  );
}

vec2 catan (vec2 z) {
  float a = z.x * z.x + (1.0 - z.y) * (1.0 - z.y);
  vec2 b = clog(vec2(1.0 - z.y * z.y - z.x * z.x, -2.0 * z.x) / a);
  return 0.5 * vec2(-b.y, b.x);
} 

vec2 catanh (vec2 z) {
  float oneMinus = 1.0 - z.x;
  float onePlus = 1.0 + z.x;
  float d = oneMinus * oneMinus + z.y * z.y;

  vec2 x = vec2(onePlus * oneMinus - z.y * z.y, z.y * 2.0) / d;

  vec2 result = vec2(log(hypot(x)), atan(x.y, x.x)) * 0.5;

  return result;
} 

vec2 cacos (vec2 z) {
  vec2 a = csqrt(vec2(
    z.y * z.y - z.x * z.x + 1.0,
    -2.0 * z.x * z.y
  ));

  vec2 b = clog(vec2(a.x - z.y, a.y + z.x));
  return vec2(HALF_PI - b.y, b.x);
} 

vec2 cacosh (vec2 z) {
  vec2 a = cacos(z);

  if (a.y <= 0.0) {
    return vec2(-a.y, a.x);
  }

  return vec2(a.y, -a.x);
} 

vec2 cacot (vec2 z) {
  return catan(vec2(z.x, -z.y) / dot(z, z));
} 

vec2 cacoth(vec2 z) {
  return catanh(vec2(z.x, -z.y) / dot(z, z));
} 

vec2 casin (vec2 z) {
  vec2 a = csqrt(vec2(
    z.y * z.y - z.x * z.x + 1.0,
    -2.0 * z.x * z.y
  ));

  vec2 b = clog(vec2(
    a.x - z.y,
    a.y + z.x
  ));

  return vec2(b.y, -b.x);
} 

vec2 casinh (vec2 z) {
  vec2 res = casin(vec2(z.y, -z.x));
  return vec2(-res.y, res.x);
} 

vec2 cacsch(vec2 z) {
  return casinh(vec2(z.x, -z.y) / dot(z, z));
} 

vec2 casec (vec2 z) {
  float d = dot(z, z);
  return cacos(vec2(z.x, -z.y) / dot(z, z));
} 

vec2 casech(vec2 z) {
  return cacosh(vec2(z.x, -z.y) / dot(z, z));
} 

vec2 cconj (vec2 z) {
  return vec2(z.x, -z.y);
} 

vec2 ccos (vec2 z) {
  return sinhcosh(z.y).yx * vec2(cos(z.x), -sin(z.x));
} 

vec2 ccosh (vec2 z) {
  return sinhcosh(z.x).yx * vec2(cos(z.y), sin(z.y));
} 

vec2 ccot (vec2 z) {
  z *= 2.0;
  vec2 sch = sinhcosh(z.y);
  return vec2(-sin(z.x), sch.x) / (cos(z.x) - sch.y);
} 

vec2 ccoth(vec2 z) {
  z *= 2.0;
  vec2 sch = sinhcosh(z.x);
  return vec2(sch.x, -sin(z.y)) / (sch.y - cos(z.y));
} 

vec2 ccsc (vec2 z) {
  float d = 0.25 * (exp(2.0 * z.y) + exp(-2.0 * z.y)) - 0.5 * cos(2.0 * z.x);

  return sinhcosh(z.y).yx * vec2(sin(z.x), -cos(z.x)) / d;
} 

vec2 ccsch (vec2 z) {
  vec2 sch = sinhcosh(z.x);
  float d = cos(2.0 * z.y) - (exp(2.0 * z.x) + exp(-2.0 * z.x)) * 0.5;
  return vec2(-cos(z.y), sin(z.y)) * sch / (0.5 * d);
} 

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

vec2 cexp(vec2 z) {
  return vec2(cos(z.y), sin(z.y)) * exp(z.x);
} 

vec2 cinv (vec2 b) {
  float e, f;
  vec2 g = vec2(1, -1);

  if( abs(b.x) >= abs(b.y) ) {
    e = b.y / b.x;
    f = b.x + b.y * e;
    g.y = -e;
  } else {
    e = b.x / b.y;
    f = b.x * e + b.y;
    g.x = e;
  }

  return g / f;
} 

vec2 cmul (vec2 a, vec2 b) {
  return vec2(
    a.x * b.x - a.y * b.y,
    a.y * b.x + a.x * b.y
  );
}

vec2 cmul (vec2 a, vec2 b, vec2 c) {
  return cmul(cmul(a, b), c);
}

vec2 cmul (vec2 a, vec2 b, vec2 c, vec2 d) {
  return cmul(cmul(a, b), cmul(c, d));
}

vec2 cmul (vec2 a, vec2 b, vec2 c, vec2 d, vec2 e) {
  return cmul(cmul(a, b, c), cmul(d, e));
}

vec2 cmul (vec2 a, vec2 b, vec2 c, vec2 d, vec2 e, vec2 f) {
  return cmul(cmul(a, b, c), cmul(d, e, f));
} 

vec2 cpolar (vec2 z) {
  return vec2(
    atan(z.y, z.x),
    hypot(z)
  );
} 

vec2 cpow (vec2 z, float x) {
  float r = hypot(z);
  float theta = atan(z.y, z.x) * x;
  return vec2(cos(theta), sin(theta)) * pow(r, x);
}

vec2 cpow (vec2 a, vec2 b) {
  float aarg = atan(a.y, a.x);
  float amod = hypot(a);

  float theta = log(amod) * b.y + aarg * b.x;

  return vec2(
    cos(theta),
    sin(theta)
  ) * pow(amod, b.x) * exp(-aarg * b.y);
} 

vec2 csec (vec2 z) {
  float d = 0.25 * (exp(2.0 * z.y) + exp(-2.0 * z.y)) + 0.5 * cos(2.0 * z.x);
  return sinhcosh(z.y).yx * vec2(cos(z.x), sin(z.x)) / d;
} 

vec2 csech(vec2 z) {
  float d = cos(2.0 * z.y) + 0.5 * (exp(2.0 * z.x) + exp(-2.0 * z.x));
  vec2 sch = sinhcosh(z.x);

  return vec2(cos(z.y), -sin(z.y)) * sch.yx / (0.5 * d);
} 

vec2 csin (vec2 z) {
  return sinhcosh(z.y).yx * vec2(sin(z.x), cos(z.x));
} 

vec4 csincos (vec2 z) {
  float c = cos(z.x);
  float s = sin(z.x);
  return sinhcosh(z.y).yxyx * vec4(s, c, c, -s);
} 

vec2 csinh (vec2 z) {
  return sinhcosh(z.x) * vec2(cos(z.y), sin(z.y));
} 

vec2 csqr (vec2 z) {
  return vec2(
    z.x * z.x - z.y * z.y,
    2.0 * z.x * z.y
  );
} 

vec2 ctan (vec2 z) {
  vec2 e2iz = cexp(2.0 * vec2(-z.y, z.x));

  return cdiv(
    e2iz - vec2(1, 0),
    vec2(-e2iz.y, 1.0 + e2iz.x)
  );
} 

vec2 ctanh (vec2 z) {
  z *= 2.0;
  vec2 sch = sinhcosh(z.x);
  return vec2(sch.x, sin(z.y)) / (sch.y + cos(z.y));
}

vec4 cmul (vec4 a, vec4 b) {
  return vec4(
    cmul(a.xy, b.xy),
    cmul(a.xy, b.zw) + cmul(a.zw, b.xy)
  );
}

vec4 cmul (vec2 a, vec4 b) {
  return vec4(
    cmul(a.xy, b.xy),
    cmul(a.xy, b.zw)
  );
}

vec4 cmul (vec4 a, vec2 b) {
  return vec4(
    cmul(a.xy, b.xy),
    cmul(a.zw, b.xy)
  );
}

vec4 cmul (vec4 a, vec4 b, vec4 c) { return cmul(cmul(a, b), c); }
vec4 cmul (vec2 a, vec4 b, vec4 c) { return cmul(cmul(a, b), c); }
vec4 cmul (vec4 a, vec2 b, vec4 c) { return cmul(cmul(a, b), c); }
vec4 cmul (vec4 a, vec4 b, vec2 c) { return cmul(cmul(a, b), c); }
vec4 cmul (vec4 a, vec2 b, vec2 c) { return cmul(cmul(a, b), c); }
vec4 cmul (vec2 a, vec4 b, vec2 c) { return cmul(cmul(a, b), c); }
vec4 cmul (vec2 a, vec2 b, vec4 c) { return cmul(cmul(a, b), c); }

vec4 csqr (vec4 a) {
  return vec4(
    csqr(a.xy),
    2.0 * cmul(a.xy, a.zw)
  );
}
vec4 cdiv (vec4 a, vec4 b) {
  return vec4(
    cdiv(a.xy, b.xy),
    cdiv(cmul(b.xy, a.zw) - cmul(a.xy, b.zw), csqr(b.xy))
  );
}

vec4 cdiv (vec2 a, vec4 b) {
  return vec4(
    cdiv(a.xy, b.xy),
    cdiv(-cmul(a.xy, b.zw), csqr(b.xy))
  );
}

vec4 cdiv (vec4 a, vec2 b) {
  return vec4(
    cdiv(a.xy, b.xy),
    cdiv(cmul(b.xy, a.zw), csqr(b.xy))
  );
}

vec4 csub(vec4 a, vec4 b) {
  return a - b;
}

vec4 csub(vec2 a, vec4 b) {
  return vec4(a.xy - b.xy, -b.zw);
}

vec4 csub(vec4 a, vec2 b) {
  return vec4(a.xy - b.xy, a.zw);
}

vec4 cadd(vec4 a, vec4 b) {
  return a + b;
}

vec4 cadd(vec2 a, vec4 b) {
  return vec4(a.xy + b.xy, b.zw);
}

vec4 cadd(vec4 a, vec2 b) {
  return vec4(a.xy + b.xy, a.zw);
}

vec4 cinv(vec4 a) {
  vec2 ainv = cinv(a.xy);
  return vec4(ainv, cmul(a.zw, -csqr(ainv)));
}

vec4 cexp(vec4 a) {
  vec2 expa = cexp(a.xy);
  return vec4(expa, cmul(expa, a.zw));
}

vec4 csqrt(vec4 a) {
  float r = hypot(a.xy);
  float b = sqrt(2.0 * (r + a.x));
  float c = sqrt(2.0 * (r - a.x));
  float re = a.x >= 0.0 ? 0.5 * b : abs(a.y) / c;
  float im = a.x <= 0.0 ? 0.5 * c : abs(a.y) / b;
  vec2 s = vec2(re, a.y < 0.0 ? -im : im);
  return vec4(s, cmul(a.zw, 0.5 * cinv(s)));
}

/*vec4 cpow(vec4 a, float n) {
  float theta = atan(a.y, a.x);
  float r = hypot(a.xy);
  float tn = theta * n;
  float rn = pow(r, n);
  vec2 s = rn * vec2(sin(tn), cos(tn));
  float rn1 = pow(r, n - 1.0);
  float tn1 = theta * (n - 1.0);
  return vec4(s, cmul(a.zw, n * rn1 * vec2(sin(tn1), cos(tn1))));
}*/

vec4 clog(vec4 z) {
  return vec4(
    log(hypot(z.xy)),
    atan(z.y, z.x),
    cdiv(z.zw, z.xy)
  );
}

vec4 csin(vec4 a) {
  vec4 asincos = csincos(a.xy);
  return vec4(asincos.xy, cmul(asincos.zw, a.zw));
}

vec4 ccos(vec4 a) {
  vec4 asincos = csincos(a.xy);
  return vec4(asincos.zw, cmul(-asincos.xy, a.zw));
}

vec4 ctan(vec4 a) {
  return cdiv(csin(a), ccos(a));
}

vec4 casin(vec4 z) {
  vec4 s = clog(vec4(-z.y, z.x, -z.w, z.z) + csqrt(csub(vec2(1, 0), csqr(z))));
  return vec4(s.y, -s.x, s.w, -s.z);
}

vec4 cacos(vec4 z) {
  vec4 s = -casin(z);
  s.x += HALF_PI;
  return s;
}

vec4 catan(vec4 z) {
  vec2 s = clog(cdiv(cadd(vec2(0, 1), z.xy), csub(vec2(0, 1), z.xy)));
  return vec4(
     0.5 * vec2(-s.y, s.x),
     cmul(z.zw, cinv(cadd(vec2(1, 0), csqr(z))))
  );
}

vec4 csinh(vec4 z) {
  vec4 ez = cexp(z);
  return 0.5 * (ez - cinv(ez));
}

vec4 ccosh(vec4 z) {
  vec4 ez = cexp(z);
  return 0.5 * (ez + cinv(ez));
}

vec4 ctanh(vec4 z) {
  vec4 ez = cexp(z);
  vec4 ezinv = cinv(ez);
  return 0.5 * cdiv(ez - ezinv, ez + ezinv);
}

vec4 casinh(vec4 z) {
  return clog(cadd(z, csqrt(cadd(vec2(1, 0), csqr(z)))));
}

vec4 cacosh(vec4 z) {
  return clog(z + cmul(csqrt(cadd(z, vec2(1, 0))), csqrt(csub(z, vec2(1, 0)))));
}

vec4 catanh(vec4 z) {
  return 0.5 * clog(cdiv(cadd(z, vec2(1,  0)), csub(vec2(1, 0), z)));
}

// https://github.com/d3/d3-color
// Copyright 2010-2016 Mike Bostock
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// 
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// 
// * Neither the name of the author nor the names of contributors may be used to
//   endorse or promote products derived from this software without specific prior
//   written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
vec3 cubehelix(vec3 c) {
  vec2 sc = vec2(sin(c.x), cos(c.x));
  return c.z * (1.0 + c.y * (1.0 - c.z) * (
    sc.x * vec3(0.14861, 0.29227, -1.97294) + 
    sc.y * vec3(1.78277, -0.90649, 0.0)
  ));
}

vec3 rainbow(float t) {
  return cubehelix(vec3(
    TWO_PI * t - 1.74533,
    (0.25 * cos(TWO_PI * t) + 0.25) * vec2(-1.5, -0.9) + vec2(1.5, 0.8)
  ));
}

// Available functions: cadd, csub, cmul, cdiv, cinv, csqr, cconj,
// csqrt, cexp, cpow, clog, csin, ccos, ctan, ccot, ccsc, csec, casin,
// cacos, catan, csinh, ccosh, ctanh, ccoth, ccsch, csech, casinh,
// cacosh, catanh
vec2 f (vec2 z, float t, vec2 mouse) {
    vec2 a = vec2(sin(t), 0.5 * sin(2.0 * t));
    vec2 b = vec2(cos(t), 0.5 * sin(2.0 * (t - HALF_PI)));
    vec2 m = mouse;
    
    // Try a different equation:
    // return csin((cmul(z - a, z - b, z - m)));
    
    return cdiv(cmul(z - a, m - b), cmul(z - b, m - a));
}

const bool animate = true;
const bool grid = true; // (when not animating)

// 1: counters split in six
// 0: contours split in two
#if 0
const vec2 steps = vec2(6, 6);
const int magOctaves = 5;
const int phaseOctaves = 5;
#else
const vec2 steps = vec2(2, 2);
const int magOctaves = 9;
const int phaseOctaves = 9;
#endif

// Other constants
// Defines the scale of the smallest octave (in some arbitrary units)
const vec2 scale = vec2(0.05);

// Grid lines:
const float lineWidth = 1.0;
const float lineFeather = 1.0;
const vec3 gridColor = vec3(0);

// Power of contrast ramp function
const float contrastPower = 2.5;

vec2 pixelToXY (vec2 point) {
      vec2 aspect = vec2(1, resolution.y / resolution.x);
    return (point / resolution.xy - 0.5) * aspect * 5.0;
}

// Select an animation state
float selector (float time) {
    const float period = 10.0;
    float t = fract(time / period);
    return smoothstep(0.4, 0.5, t) * smoothstep(1.0, 0.9, t);
}

vec3 colorscale (float phase) {
    return rainbow(phase / 2.0 - 0.25);
}

float complexContouringGridFunction (float x) {
  return 8.0 * abs(fract(x - 0.5) - 0.5);
}

float domainColoringContrastFunction (float x, float power) {
  x = 2.0 * x - 1.0;
  return 0.5 + 0.5 * pow(abs(x), power) * sign(x);
}
vec4 domainColoring (vec4 f_df,
                     vec2 steps,
                     vec2 scale,
                     vec2 gridOpacity,
                     vec2 shadingOpacity,
                     float lineWidth,
                     float lineFeather,
                     vec3 gridColor,
                     float phaseColoring,
                     float contrastPower
                     //sampler2D colormap
) {
    float invlog2base, logspacing, logtier, n, invSteps;

    vec2 res = scale * vec2(1.0, 1.0 / 6.28) * 20.0 * steps;

    // Complex argument, scaled to the range [0, 4]
    float carg = atan(f_df.y, f_df.x) * HALF_PI_INV * 2.0;

    // Reciprocal of the complex magnitude
    float cmagRecip = 1.0 / hypot(f_df.xy);

    // Normalize z before using it to compute the magnitudes. Without this we lose half
    // of the floating point range due to overflow.
    vec2 znorm = f_df.xy * cmagRecip;

    // Computed as d|f| / dz, evaluated in the +real direction (though any direction works)
    float cmagGradientMag = hypot(vec2(dot(znorm, f_df.zw), dot(vec2(znorm.y, -znorm.x), f_df.zw)));

    float cargGradientMag = cmagGradientMag * cmagRecip;

    // Shade at logarithmically spaced magnitudes
    float mappedCmag = -log2(cmagRecip);
    float mappedCmagGradientMag = cmagGradientMag * cmagRecip;

    // Magnitude steps
    // This is just a number we use a few times
    invlog2base = 1.0 / log2(steps.x);
    
    // Compute the spacing based on the screen space derivative, and clamp it to a sane
    // range so it looks a little nicer when it overflows
    logspacing = log2(mappedCmagGradientMag * res.x) * invlog2base;
    logspacing = clamp(logspacing, -50.0, 50.0);
    
    // The above is a continuous representation of the spacing, but we clamp so that
    // we have an integer interval
    logtier = floor(logspacing);
    
    // I'm having trouble working back through this line, though I think it's supposed
    // to use the spacing (which is like a difference) back into a log-value, using the
    // function value. Sorry this line isn't more clear. I'm suspicious it's actually not
    // exactly the line I want it to be.
    n = log2(abs(mappedCmag)) * invlog2base - logtier;

    // Line widths
    float width1 = max(0.0, lineWidth - lineFeather);
    float width2 = lineWidth + lineFeather;
    
    // Position within a given octave in the [0, 1] sense
    float position = 1.0 - logspacing + logtier;

    float w, scaleFactor, value, gridValue;
    float totalWeight = 0.0;
    float magnitudeGrid = 0.0;
    float magnitudeShading = 0.0;
    float octave = pow(steps.x, n) * sign(mappedCmag);
    scaleFactor = pow(steps.x, logtier) / cargGradientMag * 0.25;
    invSteps = 1.0 / steps.x;
    
    // Loop through octaves for magnitude
    for(int i = 0; i < magOctaves; i++) {
        // Select the weight of either side of this octave to fade the 
        // smallest and largest octaves in/out. Also increase the weight
        // a bit on each successive octave so that larger scales dominate
        // and it's not excessively noisy.
        float w0 = i == 0 ? 1e-4 : 1.0 + float(i);
        float w1 = i == magOctaves - 1 ? 1e-4 : 1.0 + float(i + 1);
        w = mix(w0, w1, position);
        
        totalWeight += w;
        
        // Compute a grid value so we can draw lines
        gridValue = complexContouringGridFunction(octave) * scaleFactor;
        
        // Accumulate the above into grid lines
        magnitudeGrid += w * smoothstep(width1, width2, gridValue);
        
        // Compute a looping ramp for magnitude
        value = fract(-octave);
        
        // Add magnitude's contribution to shading. The contrast function applies
        // some contrast, and the final min() function uses the grid function to blur
        // the sharp edge where the ramp repeats, effectively antialiasing it.
        magnitudeShading += w * (0.5 + (domainColoringContrastFunction(value, contrastPower) - 0.5) * min(1.0, gridValue * 1.5));
        
        // Increment the octave
        scaleFactor *= steps.x;
        octave *= invSteps;
    }
    
    // We add weighted ramp functions in [0, 1]. We divide by the total weight to blend
    // them, which also ensures the result is in [0, 1] as well.
    magnitudeGrid /= totalWeight;
    magnitudeShading /= totalWeight;

    // Perform identically the same computation, except for phase.
    invlog2base = 1.0 / log2(steps.y);
    logspacing = log2(cargGradientMag * 2.0 * res.y) * invlog2base;
    logspacing = clamp(logspacing, -50.0, 50.0);
    logtier = floor(logspacing);
    n = log2(abs(carg) + 1.0) * invlog2base - logtier;
    position = 1.0 - logspacing + logtier;

    totalWeight = 0.0;
    float phaseShading = 0.0;
    float phaseGrid = 0.0;
    octave = pow(steps.y, n) * sign(carg);
    scaleFactor = pow(steps.y, logtier) / (cargGradientMag * 2.0) * 2.0;
    invSteps = 1.0 / steps.y;

    // See above for a description of all the terms in this computation.
    for (int i = 0; i < phaseOctaves; i++) {
        float w0 = i == 0 ? 1e-4 : 1.0 + float(i);
        float w1 = i == phaseOctaves - 1 ? 1e-4 : 1.0 + float(i + 1);
        
        w = mix(w0, w1, position);
        totalWeight += w;
        gridValue = complexContouringGridFunction(octave) * scaleFactor;
        phaseGrid += w * smoothstep(width1, width2, gridValue);
        value = fract(octave);
        phaseShading += w * (0.5 + (domainColoringContrastFunction(value, contrastPower) - 0.5) * min(1.0, gridValue * 1.5));
        scaleFactor *= steps.y;
        octave *= invSteps;
    }

    phaseGrid /= totalWeight;
    phaseShading /= totalWeight;

    // Combine the grids into a single grid value
    float grid = 1.0;
    grid = min(grid, 1.0 - (1.0 - magnitudeGrid) * gridOpacity.x);
    grid = min(grid, 1.0 - (1.0 - phaseGrid) * gridOpacity.y);
    
    // Add up the shading so that `shading` is 1.0 when there is none, and darkens as you add shading.
    float shading = 0.5 + (shadingOpacity.y * (0.5 - phaseShading)) + shadingOpacity.x * (magnitudeShading - 0.5);

    // Compute a color based on the argument, then multiply it by shading
    vec3 color = colorscale(carg) * (0.5 + 0.5 * shading);
    
    // Combine the result into a bit of an ad hoc function, again tailored so that things reduce
    // to a nice result when you remove shading or coloring.
    vec3 result = mix(vec3(shading + (1.0 - phaseColoring) * 0.5 * (1.0 - shadingOpacity.x - shadingOpacity.y)), color, phaseColoring);

    // Combine the color and grid
    result = mix(gridColor, result, grid);

    // --
    return vec4(result, 1.0);
}
vec2 lerp2(vec2 a, vec2 b, float t){
    return a*(1.0-t)+t*b;
}

vec2 normal(vec2 xy, vec2 p, float t){
    return cdiv(xy,lerp2(vec2(1.0,0.0),p,t));
}

vec2 translate(vec2 xy, vec2 p, float t){
    return lerp2(xy,xy-p,t);
}

vec2 invert(vec2 xy, float t){
    return lerp2(xy,cinv(xy),t);;
}

float circle(vec2 xy, float r){
    return step(length(xy),r);
}

vec2 h(vec2 xy, vec2 p){
    return xy-p;
}

vec2 h1(vec2 xy, vec2 p){
    return cdiv(xy,p);
}

vec2 h2(vec2 xy, vec2 p){
    return cinv(h(xy,p));
}

vec2 z1 = vec2(0.0,1.0);
vec2 z2 = vec2(1.0,0.0);
vec2 z3 = vec2(-1.0,0.0);
vec2 z4 = vec2(0.2,-0.1);
float r = 0.05;

vec2 g(vec2 xy){
    return h1(h((cinv(h(xy,z3))),cinv(h(z2,z3))),h((cinv(h(z1,z3))),cinv(h(z2,z3))));
}

void main(void) {
    vec2 xy = pixelToXY(gl_FragCoord.xy)*2.0;
    vec2 mouse = pixelToXY(mouse*resolution.xy.xy);
    float t = pow(sin(time / 5.0),2.0)*3.0;
    vec2 fz = vec2(0.0);//lerp2(xy,cinv(xy-z1),t);//f1(xy,vec2(0.5,0.5),t);//f(xy, time * 0.2, mouse);
    if(t<0.5)
        fz = translate(xy,z3,2.0*t);
    else if(t<1.0)
        fz = invert(h(xy,z3),2.*t-1.0);
    else if(t<2.0)
        //fz = translate(xy,z1,1.0);
        fz = translate(cinv(h(xy,z3)),cinv(h(z2,z3)),t-1.0);
    else 
        fz = normal(translate(cinv(h(xy,z3)),cinv(h(z2,z3)),1.0),translate(cinv(h(z1,z3)),cinv(h(z2,z3)),1.0),t-2.0);//normal(translate(xy,z1,1.0),h(z2,z1),1.0-t);
        //fz = normal(translate(xy,z1,1.0),h(z2,z1),1.0-t);//invert(normal(translate(xy,z1,1.0),z2-z1,1.0),z3,3.0-t);
    //fz = g(xy);
    //fz = cinv(xy);
    // fwidth(fz) works, but it adds ugly anisotropy in the width of lines near zeros/poles.
    // Insead, we compute the magnitude of the derivatives separately.
    //
    // Also *NOTE* that this is a very important place in which we use `hypot` instead of an
    // algebraically equivalent built-in `length`. Floating point is limited and we lose lots
    // of our floating point domain if we're not careful about over/underflow.
    vec4 fdf = vec4(fz, vec2(hypot(dFdx(fz)), hypot(dFdy(fz))));

       float select = selector(time);
    if(circle(xy-z1,r)==1.0)
        glFragColor = vec4(1.0,0.0,0.0,1.0);
    else if(circle(xy-z2,r)==1.0)
        glFragColor = vec4(0.0,1.0,0.0,1.0);
    else if(circle(xy-z3,r)==1.0)
        glFragColor = vec4(0.0,0.0,1.0,1.0);
    else{
        vec4 color = domainColoring(
            fdf,
            steps,
            scale,
            vec2(1.0),  // grid
            vec2(0.35), // shading
            lineWidth,
            lineFeather,
            gridColor,
            0.9,
            contrastPower
        );
        //color = max(color, vec4(circle(xy-z3,r)));
        //color = max(color, vec4(circle(xy-z2,r)));
        //color = max(color, vec4(circle(xy-cinv(h(z2,z3)),r)));
        //color = max(color, vec4(circle(xy-z2,r)));

        glFragColor = color;
        }
}
