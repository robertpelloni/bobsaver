#version 420

// original https://www.shadertoy.com/view/XlG3Rd

uniform float time;
uniform vec2 mouse;
uniform vec4 date;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 g = gl_FragCoord.xy;
    vec2 s = resolution.xy;
    vec2 uv = (g+g-s)/s.y*3.;
    
    uv = vec2(atan(uv.x/uv.y)/atan(-1.), length(uv));
    
    uv.y += uv.x;
    uv.x += uv.y;
    uv.y -= time * 0.1;
    uv.x += time;
    
    uv = abs(fract(uv)-0.5);
    
    float r = length(uv)*2.;
    uv += vec2(cos(r),sin(r))*r;
    
    glFragColor = 1.2 - vec4(max(uv.x, uv.y));
}
