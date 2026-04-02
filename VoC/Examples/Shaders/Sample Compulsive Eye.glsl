#version 420

// original https://www.shadertoy.com/view/wsGXRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

// Tileable Noise > https://www.shadertoy.com/view/4dlGW2

float Hash(in vec2 p, in float scale) {
    return fract(sin(dot(mod(p, scale), vec2(27.16898, 38.90563))) * 5151.5473453);
}

float Noise(in vec2 p, in float scale ) {
    vec2 f;
    p *= scale;
    f = fract(p);
    p = floor(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(Hash(p, scale),
            Hash(p + vec2(1.0, 0.0), scale), f.x),
            mix(Hash(p + vec2(0.0, 1.0), scale),
            Hash(p + vec2(1.0, 1.0), scale), f.x), f.y);
}

float fBm(in vec2 p) {
    float f = 0.0;
    float scale = 10.;
    p = mod(p, scale);
    float amp   = .6;
    for (int i = 0; i < 5; i++)
    {
        f += Noise(p, scale) * amp;
        amp *= .5;
        scale *= 2.;
    }
    return min(f, 1.0);
}

// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm

float sdPie( in vec2 p, in vec2 c, in float r ) {
    p.x = abs(p.x);
    float l = length(p) - r;
    float m = length(p-c*clamp(dot(p,c),0.0,r));
    return max(l,m*sign(c.y*p.x-c.x*p.y));
}

float sdArc( in vec2 p, in vec2 sca, in vec2 scb, in float ra, float rb ) {
    p *= mat2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

vec4 over( in vec4 a, in vec4 b ) {
    return mix(a, b, 1.-a.w);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y*2.;
    float l = length(uv);
    vec4 col = vec4(.04,.22, .34, 1.);
    if( l < .86) {
        vec3 main = vec3(0);
        float a = atan(uv.y, uv.x);
        float anim = sin(time*PI*.3)*.04;
        main += vec3(.1, .7, 1.) * smoothstep(.0, .99, fBm(vec2(a/PI*09.+sin(l*29.+a*11.)*.06, l*(2.00+anim*2.))))*.9;
        main += vec3(.0, 1., .6) * smoothstep(.5, .70, fBm(vec2(a/PI*13.+sin(l*29.+a*11.)*.10, l*(1.50+anim))))*.3;
        main += vec3(.4, .9, .9) * smoothstep(.2, .96, fBm(vec2(a/PI*11.+sin(l*11.+a*17.)*.11, l*(1.50+anim))))*.3;
        float ta = PI*.3;
        float tb = PI-2.5;
        float bulge = smoothstep(.3, .0, abs(l-.5));
        float reflection = smoothstep(.07, .0, sdArc(uv,vec2(sin(ta),cos(ta)),vec2(sin(tb),cos(tb)), .52, .01));
        col = over(vec4(main*.8 + bulge*.2 + reflection*.2, smoothstep(.14, 0.001, l-.69)), col); // iris
        col = over(vec4(vec3(.8,.5,.14), smoothstep(.0, .97, fBm(vec2(a/PI*2., l+anim))*(sin(PI+min(l,PI*.25)*PI*4.)))*.7), col); // iris brown blotch
        col = over(vec4(vec3(.0), smoothstep(.16, .02-anim, l-.21)), col); // pupil black
        col = over(vec4(vec3(.96, .97, .99), smoothstep(.024, .0, length(uv-vec2(-.06,.13))-.04-anim*.02)*.9), col); // pupil reflection
        col = over(vec4(vec3(.96, .97, .99)*.2, smoothstep(.01, .0, length(uv-vec2(.07,-.14))-.01)), col); // pupil reflection tiny
    }
    col = over(vec4(vec3(.95,.9, .88), smoothstep(-.04, .01, l-.83)), col); // eye skin
    glFragColor = col;
}
