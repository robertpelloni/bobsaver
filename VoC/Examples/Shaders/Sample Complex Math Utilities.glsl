#version 420

// original https://www.shadertoy.com/view/sst3WH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time (0.25 * time)

// Constants
#define pi 3.14159265359  // Ratio between the circumference and diameter of a circle
#define rho 1.57079632679 // π/2
#define tau 6.28318530718 // 2π
#define e 2.7182818284    // Euler's number
#define i vec2(0.0, 1.0)  // Complex unit

// Hue to RGB conversion (https://www.desmos.com/calculator/amac5m7utl)
vec3 hue2rgb(in float hue) {
    //return abs(2.0 * smoothstep(0.0, 1.0, fract(vec3(hue, hue - 1.0 / 3.0, hue + 1.0 / 3.0))) - 1.0);
    //return smoothstep(0.0, 1.0, abs(2.0 * fract(vec3(hue, hue - 1.0 / 3.0, hue + 1.0 / 3.0)) - 1.0)) * 1.2;
    //return clamp(abs(6.0 * fract(vec3(hue, hue - 1.0 / 3.0, hue - 2.0 / 3.0)) - 3.0) - 1.0, 0.0, 1.0);
    return smoothstep(0.0, 1.0, clamp(abs(6.0 * fract(vec3(hue, hue - 1.0 / 3.0, hue - 2.0 / 3.0)) - 3.0) - 1.0, 0.0, 1.0));
}

// -------------------------- Complex math --------------------------
vec2 Complex(in float real, in float imag) { return vec2(real, imag); }
vec2 Complex(in float real) { return vec2(real, 0.0); }

// Complex number querying
float re(in vec2 z) { return z.x; }
float im(in vec2 z) { return z.y; }

float carg(in vec2 z) { return atan(z.y, z.x); }
float cmod(in vec2 z) { return length(z); }

// Elementary operations (+, -, *, /)
vec2 cadd(in vec2 z, in vec2 w) { return z + w; }
vec2 cadd(in vec2 z, in float w) { return vec2(z.x + w, z.y); }
vec2 cadd(in float z, in vec2 w) { return vec2(z + w.x, w.y); }

vec2 csub(in vec2 z, in vec2 w) { return z - w; }
vec2 csub(in vec2 z, in float w) { return vec2(z.x - w, z.y); }
vec2 csub(in float z, in vec2 w) { return vec2(z - w.x, -w.y); }

vec2 cmul(in vec2 z, in vec2 w) { return mat2(z, -z.y, z.x) * w; }
vec2 cmul(in vec2 z, in float w) { return z * w; }
vec2 cmul(in float z, in vec2 w) { return z * w; }

vec2 cinv(in vec2 z) { return vec2(z.x, -z.y) / dot(z, z); }
vec2 cdiv(in vec2 z, in vec2 w) { return cmul(z, cinv(w)); }
vec2 cdiv(in vec2 z, in float w) { return z / w; }
vec2 cdiv(in float z, in vec2 w) { return z * cinv(w); }

// Not sure where to group this one
vec2 cconj(in vec2 z) { return vec2(z.x, -z.y); }

// Exponentials
vec2 cexp(in vec2 z) { return exp(z.x) * vec2(cos(z.y), sin(z.y)); }
vec2 clog(in vec2 z) { return vec2(0.5 * log(dot(z, z)), carg(z)); }

// Powers
vec2 cpow(in vec2 z, in vec2 w) { return cexp(cmul(clog(z), w)); }
vec2 cpow(in float z, in vec2 w) { return cexp(log(z) * w); }
vec2 cpow(in vec2 z, in float w) {
    float a = carg(z) * w;
    return vec2(cos(a), sin(a)) * pow(dot(z, z), 0.5 * w);
}

// Hyperbolic functions
vec2 csinh(in vec2 z) { return vec2(sinh(z.x) * cos(z.y), cosh(z.x) * sin(z.y)); }
vec2 ccosh(in vec2 z) { return vec2(cosh(z.x) * cos(z.y), sinh(z.x) * sin(z.y)); }
vec2 ctanh(in vec2 z) {
    vec4 c = vec4(sinh(z.x), cosh(z.x), sin(z.y), cos(z.y));
    return cdiv(c.xy * c.wz, c.yx * c.wz);
}

// Inverse hyperbolic functions
vec2 casinh(in vec2 z) { return clog(z + cpow(cadd(cmul(z, z), 1.0), 0.5)); }
vec2 cacosh(in vec2 z) { return clog(z + cpow(csub(cmul(z, z), 1.0), 0.5)); }
vec2 catanh(in vec2 z) { return 0.5 * clog(cdiv(cadd(1.0, z), csub(1.0, z))); }

// Trigonometric functions
vec2 csin(in vec2 z) { return csinh(z.yx).yx; }
vec2 ccos(in vec2 z) { return ccosh(vec2(z.y, -z.x)); }
vec2 ctan(in vec2 z) {
    vec4 c = vec4(sin(z.x), cos(z.x), sinh(z.y), cosh(z.y));
    return cdiv(c.xy * c.wz, vec2(c.y, -c.x) * c.wz);
}

// Inverse trigonometric functions
vec2 casin(in vec2 z) { return casinh(z.yx).yx; }
vec2 cacos(in vec2 z) { return csub(rho, casin(z)); }
vec2 catan(in vec2 z) { return catanh(z.yx).yx; }

// Complex function
#define m(z, c) (cmul(z, z) + c)
vec2 f(in vec2 z) {
    z *= 3.0;
    //return cmul(m(m(m(m(z, vec2(-0.5)), vec2(-0.5)), vec2(-0.5)), vec2(-0.5)) * 3.0, cexp(time * i)); // Julia
    //return cmul(m(m(m(m(vec2(0.0), z), z), z), z) * 3.0, cexp(time * i)); // Mandelbrot
    //return cmul(cdiv(cmul(csub(cmul(z, z), 1.0), cpow(z - Complex(2.0) - i, 2.0)), cmul(z, z) + Complex(2.0) + 2.0 * i), cexp(time * i)) * 0.1;
    return casin(cmul(ctan(z), cexp(time * i))) * 0.8;
    //return cpow(z, z);
}

void main(void) {
    vec2 z = f((gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y);
    glFragColor = vec4(hue2rgb(carg(z) / tau + 0.5) * cmod(z), 1.0);
    glFragColor.rgb = mix(glFragColor.rgb, vec3(0.0), smoothstep(fwidth(z.x) * 1.5, 0.0, abs(mod(z.x + 0.125, 0.25) - 0.125)));
    glFragColor.rgb = mix(glFragColor.rgb, vec3(0.0), smoothstep(fwidth(z.y) * 1.5, 0.0, abs(mod(z.y + 0.125, 0.25) - 0.125)));
    //glFragColor.rgb = hue2rgb(gl_FragCoord.xy.x / resolution.x);
}
