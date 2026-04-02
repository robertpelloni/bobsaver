#version 420

// original https://www.shadertoy.com/view/MsfcWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926
#define T time
void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = uv * 5.;
    float phi = atan(p.y, p.x);
    vec3 a = cos(sin(p.x)-cos(p.y)+vec3(.1,.4,.222)+T+phi);
    vec3 b = sin(a*p.x*p.y-p.y+T+vec3(.1,.8,.222)+phi);
    vec3 col = vec3(0.);
    for (int i = 0; i < 3; i++)
    {
        col = 1.-abs(b*b-a*a)*col;
    }
    col = pow(col, vec3(8.));
    col = smoothstep(0., 1., col);
    glFragColor = vec4(col,1.0);
}
