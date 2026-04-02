#version 420

// original https://www.shadertoy.com/view/3lc3WN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define saturate(x) clamp(x, 0., 1.)

const float PI = 3.1419;

float rand(float n){return fract(sin(n) * 43758.5453123);}

vec2 force(vec2 p, vec2 a) {
    // return normalize(p - a) / distance(p, a);
    // optim by Fabrice:
      p -= a;
    return p / dot(p,p);
}

vec2 calcVelocity(vec2 p) {
      vec2 v = vec2(0);
      vec2 a;
      float o, r, m;
     float s = 1.;
      const float limit = 15.;
      for (float i = 0.; i < limit; i++) {
        r = rand(i/limit)-.5;
        m = rand(i+1.)-.5;
        m *= (time+(23.78*1000.))*2.;
        o = i + r + m;
        a = vec2(
              sin(o / limit * PI * 2.),
              cos(o / limit * PI * 2.)
        );
        s *= -1.;
        v -= force(p, a) * s;
      }  
      v = normalize(v);
      return v;
}

float calcDerivitive(vec2 v, vec2 p) {
    float d = 2. / resolution.x;
    return (
          length(v - calcVelocity(p + vec2(0,d)))
        + length(v - calcVelocity(p + vec2(d,0)))
        + length(v - calcVelocity(p + vec2(d,d)))
        + length(v - calcVelocity(p + vec2(d,-d)))
    ) / 4.;
}

float spacing = 1./30.;

void main(void)
{
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.x;
    p *= 3.;
    vec2 v = calcVelocity(p);
    float a = atan(v.x, v.y) / PI / 2.;
    float lines = fract(a / spacing);
    // create stripes
    lines = min(lines, 1. - lines) * 2.;
    // thin stripes into lines
       lines /= calcDerivitive(v, p) / spacing;
    // maintain constant line width across different screen sizes
       lines -= resolution.x * .0005;
    // don't blow out contrast when blending below
    lines = saturate(lines);

    float disc = length(p) - 1.;
    disc /= fwidth(disc);
    disc = saturate(disc);
    lines = mix(1. - lines, lines, disc);
    lines = pow(lines, 1./2.2);
    glFragColor = vec4(lines);
}
