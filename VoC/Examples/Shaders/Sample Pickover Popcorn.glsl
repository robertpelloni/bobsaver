#version 420

// original https://www.shadertoy.com/view/4tcXzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Xavier Benech - xbe/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// Pickover Popcorn
//

#define PI 3.141592654
#define NBIT 56
#define NBITF 56.

vec2 popcorn1(in vec2 r, in float h, in float a, in float b) {
   return vec2(
       h * cos(b*r.y + sin(a*r.y)),
       h * sin(a*r.x + cos(b*r.x)));
}

vec2 popcorn2(in vec2 r, in float h, in float a, in float b) {
   return vec2(
       h * sin(b*r.y + sin(a*r.y)),
       h * sin(a*r.x + sin(b*r.x)));
}

vec2 popcorn3(in vec2 r, in float h, in float a, in float b) {
   return vec2(
       h * cos(b*r.y + sin(a*r.y)),
       h * cos(a*r.x + sin(b*r.x)));
}

vec2 popcorn4(in vec2 r, in float h, in float a, in float b) {
   return vec2(
       h * sin(b*r.y + cos(a*r.y)),
       h * sin(a*r.x + cos(b*r.x)));
}

vec2 popcorn5(in vec2 r, in float h, in float a, in float b) {
   return vec2(
       h * sin(b*r.y + tan(a*r.y)),
       h * sin(a*r.x + tan(b*r.x)));
}

vec3 iterate(in vec2 p, float t, float pc) {
    float a = PI * (0.75 + 0.5 * sin(t));
    float b = PI * (0.75 + 0.5 * cos(t));
    float h = 0.04 + 0.02*cos(PI*t);
    vec2 r = p;
    float d = 0.;
    for (int i=0; i < NBIT; ++i) {
        if (pc < 1.)
            r.xy -= popcorn1(r.xy, h, a, b);
        else if (pc < 2.)
            r.xy -= popcorn2(r.xy, h, a, b);
        else if (pc < 3.)
            r.xy -= popcorn3(r.xy, h, a, b);
        else
            r.xy -= popcorn4(r.xy, h, a, b);
        d += distance(r.xy,p);
   }
    d /= NBITF;
    vec3 s = vec3(0.);
    s.x = 1.0/(0.1+d);
    s.y = sin(atan( r.y-p.y, r.x-p.x ));
    s.z = exp(-0.2*d);
    return s;
}

void main(void)
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0*q;
    p.x *= resolution.x/resolution.y;
    p *= 1.33;
    
    float t = 0.0625 * time;

    float pcf = mod(0.025*time, 4.);
    vec3 s = vec3(0.);
    if (fract(pcf) < 0.5) {
        s = iterate(p, t, pcf);
    } else {
        s = 0.7 * iterate(iterate(p, t + 0.5 * PI, pcf).xy, t, pcf+1.);
    }
    
    vec3 col = 0.5 + 0.25*cos( vec3(0.0,0.4,0.6) + 2.5 + s.z*6.2831 );
    
    if (fract(pcf) < 0.5) {
        col += 0.25 * vec3(0.8, 0.6, 0.4) * s.y;
        col *= 0.33 * s.x;
        col *= 0.85+0.15*sin(10.0*abs(s.y));
    } else {
        col += 0.75 * vec3(0.8, 0.6, 0.4) * s.y;
        col *= 0.66 * s.x;
        col *= 0.70 + 0.15*sin(10.0*abs(s.z)) + 0.15*sin(-6.*s.y);
    }
    
    col *= vec3(0.7, 0.5, 0.35);
    
    vec3 nor = normalize( vec3( dFdx(s.x), 0.02, dFdy(s.x) ) );
    float dif = dot( nor, vec3(0.7,0.1,0.7) );
    col += 0.05*vec3(dif);

    col *= 0.3 + 0.7*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.2 );

    col = pow(clamp(col, 0., 1.), vec3(0.45));
    glFragColor = vec4(clamp(col, 0., 1.), 1.0);
}
