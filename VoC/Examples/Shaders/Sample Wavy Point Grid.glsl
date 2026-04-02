#version 420

// original https://www.shadertoy.com/view/tdKyR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.yy;
    float r = 0.3;
    
    vec2 pCoord = uv * 30.;
    float xWaveSize = (1. + sin(time*0.7)) * 2.;
    float yWaveSize = (1. + sin(time*0.5)) * 2.;
    pCoord.x += time + xWaveSize * cos(0.25 * pCoord.y + time*2.);
    pCoord.y += time + yWaveSize * sin(0.25 * pCoord.x + time*3.);
    float dist = length(fract(pCoord) - vec2(0.5, 0.5));
    float result = 1. - dist*3.;
    float py = smoothstep(r, r-0.2, result);

    vec3 col = vec3(uv.x * py, uv.y * py, (1.-uv.y) * py);

    glFragColor = vec4(col,1.0);
}
