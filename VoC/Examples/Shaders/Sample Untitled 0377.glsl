#version 420

// original https://www.shadertoy.com/view/wdfSW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x-=cos(-uv.x*3.)*.5;
     float t = time*.5;
    uv.x+=sin(uv.x-uv.y*1.3+t*.71);
    uv.y+=t;
    uv.y = sin(uv.y*sin(uv.y*.01)*1.1) * .15;
    float p = 100.*(sin(time*.1)+1.)+1.;
    float x = p*(uv.x+uv.y);
    float g = .01+floor(sin(x*.5))*.1;
    glFragColor = vec4(fract(x*g));
}
