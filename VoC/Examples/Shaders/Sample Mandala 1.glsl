#version 420

// original https://www.shadertoy.com/view/MtcSz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Xavier Benech
// Mandala 2D
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define PI 3.14159265

float aspect = resolution.x/resolution.y;

float circle(vec2 p, float r, float width)
{
    float d = 0.;
    d += smoothstep(1., 0., width*abs(p.x - r));
    return d;
}

float arc(vec2 p, float r, float a, float width)
{
    float d = 0.;
    if (abs(p.y) < a) {
        d += smoothstep(1., 0., width*abs(p.x - r));
    }
    return d;
}

float rose(vec2 p, float t, float width)
{
    const float a0 = 6.;
    float d = 0.;
    p.x *= 7. + 8. * t;
    d += smoothstep(1., 0., width*abs(p.x - sin(a0*p.y)));
    d += smoothstep(1., 0., width*abs(p.x - abs(sin(a0*p.y))));
    d += smoothstep(1., 0., width*abs(abs(p.x) - sin(a0*p.y)));
    d += smoothstep(1., 0., width*abs(abs(p.x) - abs(sin(a0*p.y))));
    return d;
}

float rose2(vec2 p, float t, float width)
{
    const float a0 = 6.;
    float d = 0.;
    p.x *= 7. + 8. * t;
    d += smoothstep(1., 0., width*abs(p.x - cos(a0*p.y)));
    d += smoothstep(1., 0., width*abs(p.x - abs(cos(a0*p.y))));
    d += smoothstep(1., 0., width*abs(abs(p.x) - cos(a0*p.y)));
    d += smoothstep(1., 0., width*abs(abs(p.x) - abs(cos(a0*p.y))));
    return d;
}

float spiral(vec2 p, float width)
{
    float d = 0.;
    d += smoothstep(1., 0., width*abs(p.x - 0.5 * p.y / PI));
    d += smoothstep(1., 0., width*abs(p.x - 0.5 * abs(p.y) / PI));
    d += smoothstep(1., 0., width*abs(abs(p.x) - 0.5 * p.y / PI));
    d += smoothstep(1., 0., width*abs(abs(p.x) - 0.5 * abs(p.y) / PI));
    return d;
}

void main(void)
{
     vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = uv - 0.5;
    p.x *= aspect;

    vec2 f = vec2 ( sqrt(p.x*p.x + p.y*p.y), atan(p.y, p.x) );

    float T0 = cos(0.3*time);
    float T1 = 0.5 + 0.5 * cos(0.3*time);
    float T2 = sin(0.15*time);
    
    float m0 = 0.;
    float m1 = 0.;
    float m2 = 0.;
    float m3 = 0.;
    float m4 = 0.;
    if (f.x < 0.7325) {
        f.y += 0.1 * time;
        vec2 c;
        vec2 f2;
        c = vec2(0.225 - 0.1*T0, PI / 4.);
        if (f.x < 0.25) {
            for (float i=0.; i < 2.; ++i) {
                f2 = mod(f, c) - 0.5 * c;
                m0 += spiral(vec2(f2.x, f2.y), 192.);
            }
        }
        c = vec2(0.225 + 0.1*T0, PI / 4.);
        if (f.x > 0.43) {
            for (float i=0.; i < 2.; ++i) {
                f.y += PI / 8.;
                f2 = mod(f, c) - 0.5 * c;
                m1 += rose((0.75-0.5*T0)*f2, 0.4*T1, 24.);
                m1 += rose2((0.5+0.5*T1)*f2, 0.2 + 0.2*T0, 36.);
            }
        }
        c = vec2(0.6 - 0.2*T0, PI / 4.);
        if (f.x > 0.265) {
            for (float i=0.; i < 2.; ++i) {
                f.y += PI / 8.;
                f2 = mod(f, c) - 0.5 * c;
                m2 += spiral(vec2((0.25 + 0.5*T1)*f2.x, f2.y), 392.);
                m2 += rose2((1.+0.25*T0)*f2, 0.5, 24.);
            }
        }
        c = vec2(0.4 + 0.23*T0, PI / 4.);
        if (f.x < 0.265) {
            for (float i=0.; i < 2.; ++i) {
                f.y += PI / 8.;
                f2 = mod(f, c) - 0.5 * c;
                m3 += spiral(vec2(f2.x, f2.y), 256.);
                m3 += rose(f2, 1.5 * T1, 16.);
            }
        }
        m4 += circle(f, 0.040, 192.);
        m4 += circle(f, 0.265, 192.);
        m4 += circle(f, 0.430, 192.);
    }
    m4 += circle(f, 0.7325, 192.);

    // color
    float z = m0 + m1 + m2 + m3 + m4;
    z *= z;
    z = clamp(z, 0., 1.);
    vec3 col = vec3(z) * vec3(0.33*T2);
    
    // Background
    vec3 bkg = vec3(0.32,0.36,0.4) + p.y*0.1;
    col += bkg;
    
    // Vignetting
    vec2 r = -1.0 + 2.0*(uv);
    float vb = max(abs(r.x), abs(r.y));
    col *= (0.15 + 0.85*(1.0-exp(-(1.0-vb)*30.0)));

    glFragColor = vec4( col, 1.0);
}
