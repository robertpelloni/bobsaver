#version 420

// original https://www.shadertoy.com/view/4llfR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float curve(in vec2 p, in float fy, in float minLimit, in float maxLimit) {
    
    vec2 dist = vec2(0.,0.);
    
    if(p.x < minLimit)
        return 0.;
    
    if(p.x > maxLimit)
        return 0.;
    
    //dist.x = min(abs(p.x - minLimit), abs(p.x - maxLimit));
    
    dist.y = 1. - 75.*abs(p.y - fy);
    
    float d = dist.y; // min(dist.x, dist.y);
    
    d = clamp(d, 0., 1.);
    
    return d;
}
float gR = 1.61;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;   
    
    uv.y = uv.y - 0.5;
    uv.y /= .5;
    
    float ph = 500. + 2.*time;
    
    float s0 = sin(ph - gR*ph - ph*uv.x + 6.28*uv.x) * 0.2;
    float s1 = sin(ph*uv.x + 1.68*uv.x) * 0.2;
    float s2 = sin(gR*ph - ph*uv.x + 13.28*uv.x) * 0.1;
    float s3 = sin(gR*ph - ph*uv.x + 34.28*uv.x) * 0.15;
    
    float wave = s0 + s1 + s2 + s3;
    
    float value = curve(uv, -0.5 + 1.*uv.x - wave, 0., 1.);
    
    //if(value > 0.9999)
    //    value = 1.;
    
    glFragColor = vec4(vec3(value),1.0);
}
