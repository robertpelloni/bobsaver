#version 420

// original https://www.shadertoy.com/view/7ltSzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(float x) {
    return fract(sin(x)*1e5);
}

float noise(float x) {
    float i = floor(x);
    float f = fract(x);
    return mix(rand(i), rand(i + 1.0), smoothstep(0.0, 1.0, f));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec3 color = vec3(0.0);
    
    uv.x *= 155.0;
    
    vec2 i =  floor(uv);
    
    uv.y *= max(6.5 * rand(i.x + 1.0), 0.02);
    
    float odd = step(1.0, mod(i.x, 2.0));
    float even = 1.0 - odd;
    
    uv.y += odd * pow(time, 0.52) * rand(i.x) * 5.0;
    uv.y += even * pow(time, 0.66) * rand(i.x) * 5.0;
    uv.y += time * 0.4;
    uv = fract(uv);
    
    float b = uv.x - uv.y + 0.3;
    
    color = vec3(noise(i.x + 1000.0) * b, noise(i.x + 30000.0 * 0.4) * b, noise(i.x) * b);
    
    // Output to screen
    glFragColor = vec4(color,1.0);
}
