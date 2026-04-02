#version 420

// original https://www.shadertoy.com/view/Md2Gzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsv(float h, float s, float v)
{
  return mix(vec3(1.0),clamp((abs(fract(
    h+vec3(3.0, 2.0, 1.0)/3.0)*6.0-3.0)-1.0), 0.0, 1.0),s)*v;
}

float shape(vec2 p)
{
    return abs(p.x)+abs(p.y)-1.0;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 pos = uv*2.0-1.0;
    pos.x *= resolution.x/resolution.y;
    pos = pos*cos(0.00005)+vec2(pos.y,-pos.x)*sin(0.00005);
    pos = mod(pos*4.0, 2.0)-1.0;
    float c= 0.05/abs(sin(0.3*time*shape(3.0*pos)));
    vec3 col = hsv(fract(0.1*time),1.0,1.0);
    glFragColor = vec4(col*c,1.0);
}
