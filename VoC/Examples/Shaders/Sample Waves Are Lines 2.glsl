#version 420

// original https://www.shadertoy.com/view/ctKyRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define T time*1.5
#define S(t) smoothstep(P, 0., t)

float L (float i, vec2 u) { 
    return pow(sin(u.x * 3. - sin(i * 6.28) * .5), 30.) * sin(T + i * 3.) * .2 + u.y - i;
} 

void main(void)
{
    vec2 I = gl_FragCoord.xy;
    vec2 u = I/R;
    float P = 1.5/R.y, c = 0.;
    for (float i = 1.; i > -0.2; i -= .02) {
        c = max(c, S(abs(L(i, u)) - P) - S(L(i - .06, u)) - S(L(i - .12, u)) - S(L(i - .18, u)));
    }
    glFragColor = vec4(c);
}