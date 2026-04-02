#version 420

// original https://www.shadertoy.com/view/wdcfRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int octaves = 4;
const int steps = 8;
const int zoomOctaves = 5;
const float smoothLoopFudgeFactor = 10.5;
const int AA = 3;
const float period = 3.0;
const float blur = 1.4 / 60.0 / period;

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
#define E 2.71828182845904590

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

vec2 f (vec2 zView, float t) {
    t = fract(t);
    float range = exp(-t * float(zoomOctaves) * log(float(steps)));
    vec2 phase = cexp(vec2(0, 1.0 * PI * t));
    vec2 z0 = mix(vec2(0.0), vec2(5.0 / 2.0), (exp(-smoothLoopFudgeFactor * t) - 1.0) / (exp(-smoothLoopFudgeFactor) - 1.0));

    zView = cmul(zView, cmul(phase, phase));
    vec2 fz = z0 + zView * range;// * 1.25;
    return fz; 
}

float checkerboard (vec2 xy) {
  vec2 f = fract(xy * 0.5) * 2.0 - 1.0;
  return f.x * f.y > 0.0 ? 1.0 : 0.0;
}

float rectangularDomainColoring (vec4 f_df,
                     vec2 steps,
                     vec2 baseScale,
                     float justCheckerboard
) {
  float cmagRecip = 1.0 / hypot(f_df.xy);
  baseScale *= 10.0;

  vec2 znorm = f_df.xy * cmagRecip;
  float cmagGradientMag = hypot(vec2(dot(znorm, f_df.zw), dot(vec2(znorm.y, -znorm.x), f_df.zw)));

  float xContinuousScale = log2(cmagGradientMag) / log2(steps.x);
  float xDiscreteScale = floor(xContinuousScale);
  float xScalePosition = 1.0 - (xContinuousScale - xDiscreteScale);

  float yContinuousScale = log2(cmagGradientMag) / log2(steps.y);
  float yDiscreteScale = floor(yContinuousScale);
  float yScalePosition = 1.0 - (yContinuousScale - yDiscreteScale);

  vec2 scalePosition = 1.0 - vec2(xContinuousScale, yContinuousScale) + vec2(xDiscreteScale, yDiscreteScale);
  vec2 scaleBase = vec2(pow(steps.x, -xDiscreteScale), pow(steps.y, -yDiscreteScale)) / baseScale;

  float totalWeight = 0.0;
  float shading = 0.0;
  vec2 invSteps = 1.0 / steps;
  vec2 octaveScale = vec2(1.0);
  vec2 grid = vec2(0.0);
  vec2 gridScaleBase = vec2(
    pow(steps.x, xScalePosition),
    pow(steps.y, yScalePosition)
  );

  for(int i = 0; i < octaves; i++) {
    float w0 = i == 0 ? 1e-4 : 1.0 + float(i);
    float w1 = i == octaves - 1 ? 1e-4 : 1.0 + float(i + 1);
    float w = mix(w0, w1, xScalePosition);
    totalWeight += w;
    vec2 value = f_df.xy * scaleBase * octaveScale;

    vec2 gridSlope = baseScale * gridScaleBase / octaveScale / steps;

    shading += w * checkerboard(value);
    
    octaveScale *= invSteps;
  }

  return 1.0 - shading / totalWeight;
}

float color (vec2 z, float t) {
  //float justCheckerboard = (1.0 - smoothstep(0.1, 0.3, t) * smoothstep(0.95, 0.8, t));
  //t = smoothstep(0.1, 0.9, t);
  vec2 fz = f(2.0 * z - 0.4, t);

  vec4 fdf = vec4(fz, vec2(hypot(dFdx(fz)), hypot(dFdy(fz))));

  return rectangularDomainColoring(
      fdf,
      vec2(float(steps)), // steps
      vec2(0.5), // scale
      0.0 //justCheckerboard
  );
}

void main(void) {
    float sum = 0.0;
    float t = time / period;

    float tf = fract(t);
    vec2 uv = 0.5 + (gl_FragCoord.xy / resolution.xy - 0.5) * vec2(resolution.x / resolution.y, 1.0);

    for (int i = 0; i < AA; i++) {
      for (int j = 0; j < AA; j++) {
        vec2 offset = (vec2(i + 1, j + 1) / float(AA + 1) - 0.5) / resolution.xy;
        //float tOffset = random(gl_FragCoord.xy + t + float(i) * 0.005915 + float(j) * 0.025901);
        float tOffset = fract(100.0 * 1.61803398875 * float(i + j * AA));
        float tt = fract(t + tOffset * blur);

        vec2 z = ((uv + offset) - 0.5) * 8.0;

        float c = color(z, tt);

        sum += c;
      }
    }
    sum /= float(AA * AA);
    glFragColor = vec4(vec3(pow(clamp(sum, 0.0, 1.0), 0.75)), 1.0);
}
