#version 420

// original https://www.shadertoy.com/view/XtdSRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Xavier Benech
// Mandala 2D (2nd version)
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define PI 3.14159265

#define CART2POLAR(x,y) vec2( sqrt(x*x + y*y), atan(y, x) )

//////////////////////////////////////////////////////////////////////////////
// Primitives

float circle(vec2 p, float r, float width)
{
    float d = 0.;
    d += smoothstep(1., 0., width*abs(p.x - r));
    return d;
}

float stripes(vec2 p, float a, float width)
{
    float d = 0.;
    d += smoothstep(1., 0., width*abs(abs(p.y) - a));
    return d;
}

float zebra(vec2 p, float width)
{
    float d = 0.;
    d += smoothstep(1., 0., width*abs(p.x - p.y));
    d += smoothstep(1., 0., width*abs(p.x + p.y));
    return d;
}

float mirror(float x, float v, float width)
{
    float d = 0.;
    d += smoothstep(1., 0., width*abs(x - v));
    d += smoothstep(1., 0., width*abs(x - abs(v)));
    d += smoothstep(1., 0., width*abs(abs(x) - v));
    d += smoothstep(1., 0., width*abs(abs(x) - abs(v)));
    return d;
}

//////////////////////////////////////////////////////////////////////////////
// Shapes

float leaf(vec2 p, float width) {
    float d = 0.;
    d += smoothstep(1., 0., width*abs(p.x - abs(sin(-p.y)* exp(-p.y))));
    d += smoothstep(1., 0., width*abs(abs(p.x) - abs(sin(p.y)* exp(p.y))));
    return d;
}

float spiral(vec2 p, float width) {
    return mirror(p.x, 0.5 * p.y / PI, width);
}

float rose(vec2 p, float t, float width) {
    const float a = 6.;
    p.x *= 7. + 8. * t;
    return mirror(p.x, sin(a * p.y), width);
}

float rose2(vec2 p, float t, float width) {
    const float a = 6.;
    p.x *= 7. + 8. * t;
    return mirror(p.x, cos(a * p.y), width);
}

float fun(vec2 p, float t, float width) {
    const float a = 6.;
    p.x *= 7. + 8. * t;
    return mirror(sin(a * p.x / PI), cos(a * p.y / PI), width);
}

float fun2(vec2 p, float t, float width) {
    const float a = 6.;
    p.x *= 7. + 8. * t;
    return mirror(p.x, sin(a * p.y)+cos(a * p.y), width);
}

//////////////////////////////////////////////////////////////////////////////
// Mandala

float Shape1(vec2 p, vec2 m, float a, float d) {
    const float w = 8.;
    vec2 f = mod(p, m) - 0.5 * m;
    f.x *= a;
    float res = 0.;
    res += fun2(vec2(f.x, f.y*f.y), d, w);
    res += fun2(vec2(f.x + 0.01, f.y*f.y + 0.05), d, w);
    res += fun2(vec2(f.x - 0.01, f.y*f.y + 0.05), d, w);
    res += fun2(vec2(f.x + 0.02, f.y*f.y + 0.075), d, w);
    res += fun2(vec2(f.x - 0.02, f.y*f.y + 0.075), d, w);
    return res;
}

float Shape2(vec2 p, vec2 m, float a, float d) {
    const float w = 8.;
    vec2 f = mod(p, m) - 0.5 * m;
    f.x *= a;
    float res = 0.;
    res += rose(vec2(f.x, f.y*f.y), d, w);
    res += rose(vec2(f.x + 0.01, f.y*f.y + 0.05), d, w);
    res += rose(vec2(f.x - 0.01, f.y*f.y + 0.05), d, w);
    res += rose(vec2(f.x + 0.02, f.y*f.y + 0.075), d, w);
    res += rose(vec2(f.x - 0.02, f.y*f.y + 0.075), d, w);
    return res;
}

float Shape3(vec2 p, vec2 m, float a, float d) {
    const float w = 8.;
    vec2 f = mod(p, m) - 0.5 * m;
    f.x *= a;
    float res = 0.;
    res += rose(vec2(f.x, f.y*f.y), d, w);
    res += rose(vec2(f.x + 0.01, f.y*f.y + 0.05), d, w);
    res += rose(vec2(f.x - 0.01, f.y*f.y + 0.05), d, w);
    res += rose(vec2(f.x + 0.02, f.y*f.y + 0.075), d, w);
    res += rose(vec2(f.x - 0.02, f.y*f.y + 0.075), d, w);
    return res;
}

float Mandala1(vec2 p) {
    float res = 0.;
    vec2 m;
    vec2 f;
    if (p.x > 0.6)
        return 0.;
    if (p.x < 0.25) {
        m = vec2(0.25, PI / 6.);
        f = mod(p, m) - 0.5 * m;
        f.x *= 1.5;
        f.y /= 2.;
        res += zebra(vec2(f.x, f.y), 32.);
    } 
    if (p.x > 0.32 && p.x < 0.5) {
        m = vec2(0.25, PI / 12.);
        f = mod(p, m) - 0.5 * m;
        f.x *= 2.;
        res += zebra(vec2(f.x, f.y), 32.);
        res += zebra(vec2(f.x, f.y - 0.05), 32.);
        res += zebra(vec2(f.x, f.y + 0.05), 32.);
        res += zebra(vec2(f.x, f.y - 0.1), 32.);
        res += zebra(vec2(f.x, f.y + 0.1), 32.);
    }
    if (p.x < 0.15) {
        res += 0.25 * Shape1(p, vec2(0.3, PI/6.), 1.5, 0.65);
    }
    if (p.x > 0.12 && p.x < 0.34) {
        res += 0.5 * Shape1(p, vec2(0.34, PI/4.), 1.5, 0.65);
        res += 0.25 * Shape1(p, vec2(0.42, PI/6.), 1.5, 0.65);
    }
    if (p.x > 0.32 && p.x < 0.5) {
        m = vec2(0.5, PI / 6.);
        f = mod(p, m) - 0.5 * m;
        res += stripes(vec2(f.x, f.y), 0.125, 48.);
    }
    res += 2.*circle(p, 0.015, 72.);
    res += 2.*circle(p, 0.105, 72.);
    res += circle(p, 0.27, 64.);
    res += 2.*circle(p, 0.32, 64.);
    res += 2.*circle(p, 0.5, 72.);
    res += 2.*circle(p, 0.525, 72.);
    return 0.5 * res;
}

float Mandala2(vec2 p) {
    float res = 0.;
    vec2 m;
    vec2 f;
    if (p.x > 0.6)
        return 0.;
    if (p.x < 0.4) {
        m = vec2(0.25, PI / 6.);
        f = mod(p, m) - 0.5 * m;
        f.y *= 0.5;
        res += 0.5 * rose2(vec2(f.x, f.y), 1., 3.);
    }
    if (p.x > 0.0125 && p.x < 0.5) {
        m = vec2(0.25, PI / 6.);
        f = mod(p, m) - 0.5 * m;
        f.y *= 0.5;
        res += zebra(vec2(f.x, f.y), 28.);
    }
    if (p.x < 0.5) {
        m = vec2(0.25, PI / 6.);
        f = mod(p, m) - 0.5 * m;
        res += 0.5 * fun(vec2(f.x, f.y), 0.125, 28.);
    }
    res += 2.*circle(p, 0.015, 72.);
    res += 2.*circle(p, 0.105, 72.);
    res += circle(p, 0.38, 64.);
    res += 2.*circle(p, 0.5, 72.);
    res += 2.*circle(p, 0.525, 72.);
    return 0.5 * res;
}

float Mandala3(vec2 p) {
    float res = 0.;
    vec2 m;
    vec2 f;
    if (p.x > 0.6)
        return 0.;
    if (p.x < 0.25) {
        m = vec2(0.25, PI / 6.);
        f = mod(p, m) - 0.5 * m;
        f.y *= 0.5;
        res += 0.25 * rose2(vec2(f.x, f.y), 1., 4.);
    }
    if (p.x > 0.0125 && p.x < 0.5) {
        m = vec2(0.25, PI / 6.);
        f = mod(p, m) - 0.5 * m;
        f.y *= 0.5;
        res += zebra(vec2(f.x, f.y), 28.);
    }
    if (p.x < 0.5) {
        m = vec2(0.3, PI / 6.);
        f = mod(p, m) - 0.5 * m;
        res += 0.5 * fun(vec2(f.x, f.y), 0.125, 28.);
    }
    if (p.x < 0.5) {
        m = vec2(0.25, PI / 6.);
        f = mod(p, m) - 0.5 * m;
        f.x *= 2.5;
        f.y += 0.135;
        res += 0.5 * fun2(vec2(f.x, f.y), 0.25, 3.);
    }
    res += 2.*circle(p, 0.015, 72.);
    res += 2.*circle(p, 0.125, 96.);
    res += 2.*circle(p, 0.5, 72.);
    res += 2.*circle(p, 0.525, 72.);
    return 0.5 * res;
}

float Mandala4(vec2 p) {
    float res = 0.;
    vec2 m;
    vec2 f;
    if (p.x > 0.6)
        return 0.;
    if (p.x < 0.125) {
        res += 0.25 * Shape1(p, vec2(0.25, PI/6.), 2.5, 0.25);
           res += 0.25 * Shape1(p, vec2(0.5, PI/6.), 0.7, .125);
    }
    if (p.x > 0.195 && p.x < 0.32) {
        m = vec2(0.5, PI / 4.);
        f = mod(p, m) - 0.5 * m;
        f.x *= 3.;
        res += leaf(vec2(f.x, f.y), 28.);
    }
    if (p.x > 0.16 && p.x < 0.19) {
        m = vec2(0.5, PI / 12.);
        f = mod(p, m) - 0.5 * m;
        res += stripes(vec2(f.x, f.y), 0.125, 32.);
    }
    if (p.x < 0.175) {
        m = vec2(0.5, PI / 4.);
        f = mod(p, m) - 0.5 * m;
        float d = 0.375;
        res += 0.5 * fun2(vec2(f.x, f.y*f.y), d, 16.);
        res += 0.5 * fun2(vec2(f.x + 0.01, f.y*f.y + 0.05), d, 16.);
        res += 0.5 * fun2(vec2(f.x - 0.01, f.y*f.y + 0.05), d, 16.);
        res += 0.5 * fun2(vec2(f.x + 0.02, f.y*f.y + 0.075), d, 16.);
        res += 0.5 * fun2(vec2(f.x - 0.02, f.y*f.y + 0.075), d, 16.);
    }
    if (p.x > 0.2 && p.x < 0.32) {
        float w = 20.;
        m = vec2(0.4, PI / 4.);
        f = mod(p, m) - 0.5 * m;
        f.x *= 1.5;
        f.y *= 2.;
        res += 0.25*fun(vec2(f.x, f.y*f.y), -0.4, w);
        res += 0.25*fun(vec2(f.x + 0.01, f.y*f.y + 0.05), -0.4, w);
        res += 0.125*fun(vec2(f.x + 0.01, f.y*f.y - 0.05), -0.4, w);
        res += 0.25*fun(vec2(f.x + 0.02, f.y*f.y + 0.075), -0.4, w);
        res += 0.125*fun(vec2(f.x + 0.02, f.y*f.y - 0.075), -0.4, w);
    }
    if (p.x > 0.2 && p.x < 0.6) {
        vec2 pp = p;
        pp.x *= 0.685;
        m = vec2(0.25, PI / 4.);
        f = mod(pp, m) - 0.5 * m;
        float d = 0.375;
        res += 0.5 * fun2(vec2(f.x, f.y*f.y), d, 16.);
        res += 0.25 * fun2(vec2(f.x + 0.01, f.y*f.y + 0.05), d, 16.);
        res += 0.5 * fun2(vec2(f.x - 0.01, f.y*f.y + 0.05), d, 16.);
        res += 0.25 * fun2(vec2(f.x + 0.02, f.y*f.y + 0.075), d, 16.);
        res += 0.5 * fun2(vec2(f.x - 0.02, f.y*f.y + 0.075), d, 16.);
    }
    if (p.x > 0.32 && p.x < 0.5) {
        vec2 pp = p;
        pp.x *= 0.825;
        m = vec2(0.25, PI / 12.);
        f = mod(pp, m) - 0.5 * m;
        f.x *= 5.;
        res += zebra(vec2(f.x, f.y), 32.);
        res += zebra(vec2(f.x, f.y - 0.05), 32.);
        res += zebra(vec2(f.x, f.y + 0.05), 32.);
    }
    res += 2.*circle(p, 0.015, 72.);
    res += circle(p, 0.16, 128.);
    res += circle(p, 0.19, 96.);
    res += 2.*circle(p, 0.32, 96.);
    res += circle(p, 0.41, 128.);
    res += 2.*circle(p, 0.5, 72.);
    res += 2.*circle(p, 0.525, 72.);
    return 0.5 * res;
}

//////////////////////////////////////////////////////////////////////////////
// Main

void main(void)
{
     vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = q - 0.5;
    p.x *= resolution.x/resolution.y;
    
    vec2 f = CART2POLAR(p.x, p.y);
    
    float z = 0.;
    float t = mod(0.3*time, 4.);
    float pcf = floor(t);
    float m = fract(t) - 0.5;
    m = smoothstep(0.0, 0.5, (m > 0. ? m : 0.));
    if (pcf < 1.) {
       z = mix(Mandala1(f), Mandala2(f), m);
    } else if (pcf < 2.) {
       z = mix(Mandala2(f), Mandala3(f), m);
    } else if (pcf < 3.) {
       z = mix(Mandala3(f), Mandala4(f), m);
    } else {
       z = mix(Mandala4(f), Mandala1(f), m);
    }
    
    z *= z;

    vec3 s = vec3(0.);
    s.x = 1.33/(0.15+z);
    s.y = cos(f.y) + 0.25*cos(4.*PI*f.x);
    s.z = exp(-2.*z);

    vec3 bkg = vec3(0.72,0.72,0.48);
    vec3 col = 0.6 + 0.4*cos( bkg + 2.5 + s.z*6.2831 );
    
    col += 0.2 * vec3(0.56,0.56,0.56) * s.y;
    col *= 0.2 * s.x;
       col *= 0.5 - 0.45*cos(16.0*s.z);
       col += 0.25 - 0.25*cos(16.0*s.z) * vec3(0.48, 0.64, 0.92);
    
    vec3 nor = normalize( vec3( dFdx(s.z), 0.02, dFdy(s.z) ) );
    float dif = dot( nor, vec3(0.8,0.8,0.2) );
    col += 0.125*vec3(dif);

    // Vigneting + gamma
    col *= 0.3 + 0.7*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.2 );
    col = pow(col, vec3(0.735));
    glFragColor = vec4( clamp(col, 0., 1.), 1.0);
}
