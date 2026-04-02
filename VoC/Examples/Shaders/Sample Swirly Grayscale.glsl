#version 420

// original https://www.shadertoy.com/view/4sXfWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.x;
    float col = 0.0;
    uv.x -= 0.5;
    uv.y -= resolution.y/resolution.x/2.0;
    float dir = atan(uv.x, uv.y)*10.0+time*10.0;
    if(sin(dir-pow(length(uv),3.0)*500.0) > 0.0) {
        col += 0.25;
    }
    dir = atan(uv.x, uv.y)*10.0+time*11.0;
    if(sin(dir-pow(length(uv),3.0)*300.0) > 0.0) {
        col += 0.25;
    }
    dir = atan(uv.x, uv.y)*10.0+time*9.0;
    if(sin(dir-pow(length(uv),3.0)*400.0) > 0.0) {
        col += 0.25;
    }
    dir = atan(uv.x, uv.y)*10.0+time*12.0;
    if(sin(dir-pow(length(uv),3.0)*600.0) > 0.0) {
        col += 0.25;
    }
    glFragColor = vec4(vec3(col),1.0);
}
