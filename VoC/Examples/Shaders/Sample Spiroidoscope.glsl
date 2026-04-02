#version 420

// original https://www.shadertoy.com/view/7sfSRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926
#define DPI 6.28318530

float getAngleDiff(float a1, float a2) {

    float diff = a1-a2;
    while (diff < -PI) diff += DPI;
    while (diff >  PI) diff -= DPI;
    
    return diff;

}

void main(void)
{
    float t = time*0.5;
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.xx;
    float r = length(uv);
    float alpha =(atan(uv.y, uv.x))*9.0 + t*1.37;
    alpha += sin(alpha*2.0)*sin(t*0.39);
    float alphaForR = mod(log(r) * sin(t*0.2)*5.0 - t*1.53, DPI) + sin(r*DPI*2.0-t*1.12)*2.0;

    
    glFragColor = vec4(1.0-smoothstep(0.55, 0.75, 1.0-abs(getAngleDiff(alpha, alphaForR)/PI)));

}

