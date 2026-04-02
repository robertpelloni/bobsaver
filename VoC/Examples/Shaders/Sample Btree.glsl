#version 420

// original https://www.shadertoy.com/view/ltKcW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define f fract
#define s smoothstep
void main(void)
{
    vec2 c = gl_FragCoord.xy;
    vec4 o = glFragColor;
    vec2 w = 2.1*(c/resolution.xy - .5);
    float t = f(time), T = t + 1.,
        u = w.x*T, v = w.y * w.y - t / 4.,
         l = v * 4., m = pow(2., floor(l) + 1.), b = u * m, 
        x = (floor(b) + .5 + .25 * sign(f(b) - .5) * s(0., 1., f(l))) / m / T,
        d = abs(x - w.x) - .01;
    o = o-o+s(0., -.01, d);
    glFragColor = o;
}
