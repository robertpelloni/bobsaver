#version 420

// original https://www.shadertoy.com/view/NdsSzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float heart(vec2 uv)
{   
    float absX = abs(uv.x);
    uv.y = uv.y * 1.2 + absX * absX * 1.1 - absX * 0.66;    
    return max(0., distance(uv, vec2(0.)));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.y;
    
    float d = fract(heart(uv * .4) * 5. - time);  
    float a = smoothstep(0.333, 0.34, d);
    float b = smoothstep(0.667, 0.68, d);  
    vec3 c = mix(vec3(0.96, 0.62, 0.80), mix(vec3(0.94, 0.26, 0.42), vec3(0.92, 0.00, 0.01), b), a);
    glFragColor = vec4(c, 1.0);
}
