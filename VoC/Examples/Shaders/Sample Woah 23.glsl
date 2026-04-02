#version 420

// original https://www.shadertoy.com/view/MlsfDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float ratio = resolution.y/resolution.x;
    vec2 uv = gl_FragCoord.xy / resolution.x - vec2(0.5,ratio/2.0);
    vec2 P = 75.0 * uv;
    float TI = mod(5.0 * time,6.2831855);
    float ST = sin(time);
    float L = length(P);
    float A = (atan(P.x,P.y) + L*ST*ST + TI);
    float C = 1.5 * sin(A * 5.0);
    glFragColor = vec4(-C, C*ST*ST*ST, C, 1.0);
}
