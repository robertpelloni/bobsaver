#version 420

// original https://www.shadertoy.com/view/mdyXzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define P 8.
#define Q 3.

#define HTiters 100
#define JGiters 5

#define TWOPI 6.283185307179
#define PI 3.141592653589
#define SS2 0.707106781186
#define S42 1.189207115002
#define R vec2(1.,0.)
#define I vec2(0.,1.)

vec2 cmul(vec2 z, vec2 c) {
    return vec2(z.x * c.x - z.y * c.y, z.x * c.y + z.y * c.x);
}

vec2 cdiv(vec2 z, vec2 c) {
    float r = dot(c, c);
    return vec2(z.x * c.x + z.y * c.y, z.y * c.x - z.x * c.y) / r;
}

vec2 cpow(vec2 z, vec2 p) {
    float a = atan(z.y, z.x);
    float lnr = 0.5 * log(dot(z,z));
    float m = exp(p.x * lnr - p.y * a);
    float angle = p.x * a + p.y * lnr + TWOPI;
    return vec2(cos(angle), sin(angle)) * m;
}

vec2 conj(vec2 z) {
    return vec2(z.x, -z.y);
}

vec2 hypershift(vec2 z, vec2 s) {
    return cdiv(z + s, cmul(z,conj(s))+vec2(1.0,0.0));
}

vec2 mobius(vec2 z, vec2 a, vec2 b, vec2 c, vec2 d) {
    return cdiv(cmul(a,z)+b,cmul(c,z)+d);
}

vec2 hypertile(vec2 z, float p, float q, int iterations) {
    float spq = sin(PI/2. + PI/q);
    float spp = sin(PI/p);
    float pshift = (1./sqrt(spq*spq / (spp*spp) - 1.)) * (spq / spp - 1.);
    vec2 rot = vec2(cos(TWOPI/p), sin(TWOPI/p));
    for(int i = 0; i < iterations; i++) {
        z = cmul(z, rot);
        z = hypershift(z,vec2(pshift,0.0));
        z.x = abs(z.x);
        z = hypershift(z,vec2(-pshift,0.0));
    }
    return z;
}

vec2 juliaGrid(vec2 z, int iterations) {
    for(int i = 0; i < iterations; i++) {
        z = cmul(z, vec2(SS2,SS2));
        z = cpow(z, R*2.);
        z = mobius(z,R,R,-R,R);
    }
    return z;
}

vec2 cn2dn(vec2 z) {
    z = cmul(z, vec2(-SS2,SS2)*S42);
    z = cpow(z, R*2.);
    z += I;
    return mobius(z,R,R,-R,R);
}

float l(float r) {
    return 2.0 / PI * atan(r);
}

float hue2rgb(float p, float q, float t) {
    do{
      if(t < 0.0) t += 1.0;
      if(t > 1.0) t -= 1.0;
    } while (t < 0.0 || t > 1.0);

  if(t < 1.0 / 6.0) return p + (q - p) * 6.0 * t;
  if(t < 1.0 / 2.0) return q;
  if(t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
  return p;
}

vec3 hslToRgb(float h, float s, float l) {
  float r, g, b;

  if(s == 0.0) {
    r = g = b = l; // achromatic
  } else {
    float q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
    float p = 2.0 * l - q;

    r = hue2rgb(p, q, h + 1.0 / 3.0);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1.0 / 3.0);
  }

  return vec3(r,g,b);
}

vec3 domainColoring(vec2 z, float symmetry) {
    float H = mod(atan(z.y/z.x),0.25)+0.1 - TWOPI / symmetry;
    float S = 1.0;
    float L = l(length(z));
    return hslToRgb(H,S,L);
}

void main(void)
{
    vec2 uv = 2.0 * (gl_FragCoord.xy - 0.5*resolution.xy) / -resolution.y;
    float time = time * 0.25;

    uv = mobius(uv, R, R * tan(time), -R * tan(time), R);

    uv = juliaGrid(cn2dn(uv), JGiters);

    vec3 col = dot(uv,uv) < 1. ? domainColoring(hypertile(uv, P, Q, HTiters)*2.5, P) : domainColoring(cdiv(R,uv), P);

    glFragColor = vec4(col,1.0);
}
