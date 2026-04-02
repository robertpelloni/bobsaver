#version 420

// original https://www.shadertoy.com/view/3sKcDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy * 0.5;
    
    vec2 mouse = vec2(mouse*resolution.xy)/vec2(resolution);
    
    float width = 50.;
    float width2 = 100.;
    
    vec3 ramp = vec3(uv.x+200.0 * mouse.x, (uv.x*0.33+uv.y*0.66) * 1.51, (uv.x*0.33-uv.y*0.66) * 1.51);

    vec3 wave = abs(mod(ramp, width2) / width - 1.0);
//    vec3 col = vec3(v); 
    // Output to screen
//    float v = (wave.x+wave.y)-wave.z;
//    float v = max(max(wave.x,wave.y),wave.z);
//    float v = min(min(wave.x,wave.y),wave.z);
    wave -= wave.yzx;
    float v = max(max(wave.x,wave.y), wave.z);
//    float v = abs(step(wave.x-wave.y,wave.y-wave.z));
    glFragColor = vec4(vec3(v),1.0);
}
