#version 420

// original https://www.shadertoy.com/view/4lG3Rd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 g = gl_FragCoord.xy;
    vec2 s = resolution.xy;
    vec2 uv = (g+g-s)/s.y*3.;
    
    uv = vec2(atan(uv.x/uv.y)/atan(-1.), length(uv));
    
    uv.x += uv.y;
    uv.y -= time * 0.5;
    uv.x += time * 0.25;
    
    uv = abs(fract(uv)-0.5);
    
    float r = length(uv)*2.;
    uv += vec2(cos(r),sin(r))*r;
    
    glFragColor = 1.2 - vec4(max(uv.x, uv.y));
}
