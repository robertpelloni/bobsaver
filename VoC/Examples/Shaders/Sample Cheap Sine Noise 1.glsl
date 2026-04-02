#version 420

// original https://www.shadertoy.com/view/WscBz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//identity rotated GOLDEN_ANGLE around x, then around y
#define m3 mat3(-0.73736, 0.45628, 0.49808, 0, -0.73736, 0.67549, 0.67549, 0.49808, 0.54371)

void main(void)
{
    float twist = sin(time * 0.3) * 2.;
    vec2 uv = gl_FragCoord.xy/resolution.y;
    vec3 q = vec3(uv * 6.2831, time * .2);
    float a = 1.;
       vec3 c = vec3(0);
    for(int i = 0; i <8; i++){
        q = m3 * q; 
        vec3 s = sin( q.zxy / a) * a;
        q += s * twist;
        c += s;
        a *= .75;
    }
    glFragColor = vec4(c * .17 + .5, 1.);
}
