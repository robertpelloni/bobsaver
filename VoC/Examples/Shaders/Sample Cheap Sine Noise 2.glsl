#version 420

// original https://www.shadertoy.com/view/tddBz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//variation of: https://www.shadertoy.com/view/WscBz2

//identity rotated golden angle around x, then around y
#define m3 mat3(-0.73736, 0.45628, 0.49808, 0, -0.73736, 0.67549, 0.67549, 0.49808, 0.54371)

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    vec3 q = vec3(uv * 10., time * .2);
       vec3 c = vec3(0);
    for(int i = 0; i <8; i++){
        q = m3 * q; 
        vec3 s = sin(q.zxy);
        q += s * 2.;
        c += s;
    }
    glFragColor = vec4(mix(vec3((c.x + c.y + c.z) * 0.5), c, 0.5) * .15 + .5, 1.);
}
