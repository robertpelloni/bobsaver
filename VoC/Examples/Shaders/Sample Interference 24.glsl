#version 420

// original https://www.shadertoy.com/view/DtSSzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y*2.0;
    float col = (sin(20.0*length(uv-vec2(sin(time), cos(time)))));
    col *= (sin((20.0+sin(time/10.0)*5.0)*length(uv-vec2(cos(time+1.0), sin(time*2.0 + 1.0)))));
    col = max(0.0, col);
    col = sqrt(col);
    glFragColor = vec4(col);
}
