#version 420

// original https://www.shadertoy.com/view/XdS3RK

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsv(float h, float s, float v)
{
  return mix(vec3(1.0),clamp((abs(fract(h+vec3(3.0, 2.0, 1.0)/3.0)*6.0-3.0)-1.0), 0.0, 1.0),s)*v;
}

float shape(vec2 p)
{
    return abs(p.x)+abs(p.y)-1.0;
}

void main(void)
{
    vec2 pos = gl_FragCoord.xy-resolution.xy*.5;
    float a = .777+time*.0001*(1.0+.3*pow(length(pos.xy/resolution.y),2.0));
    pos = pos*cos(a)+vec2(pos.y,-pos.x)*sin(a);
    pos = mod(pos/80.0, 2.0)-1.0;
    float h= abs(sin(0.3*time*shape(3.0*pos)));
    float c= 0.05/h;
    vec3 col = hsv(fract(0.1*time+h),1.0,1.0);
    glFragColor = vec4(col*(c*.5+.5),1.0);
}
