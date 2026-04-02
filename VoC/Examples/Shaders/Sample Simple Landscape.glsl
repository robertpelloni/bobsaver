#version 420

// original https://www.shadertoy.com/view/3stGzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hypot(float x, float y)
{
    return sqrt(x * x + y * y);
}

void main(void)
{
    float PI = 3.14159265;
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec2 pos = vec2(uv.x * resolution.x / resolution.y - 0.5 * resolution.x / resolution.y, uv.y - 0.5);
    
    float a = atan(pos.x, pos.y);
    float val = 0.0;
    for (float i = 0.0; i < 1.0; i += 0.04)
    {
        float speed = (mod(pow(i * 10.0, 2.1) * 1.2, 3.8) - 1.9) * 0.5;
        float phase = time * speed + i * 0.256;
        
        float comp1 = pow(i * 10.0, 2.5);
        
        float freq = 2.0 * mod((comp1 - mod(comp1, 1.0)), 10.0) + 3.0;
        float f = pow(max(0.0, sin(a * freq + phase)), 0.2);
        
        val += pow(max(0.0, sin(a * freq + phase)), 0.3);
    }
    
    float c = 1.0 - (hypot(pos.x, pos.y) - 0.10) / (val + 0.02) * 40.0;
    
       c = pow(c, 3.0);
    c = clamp(c, 0.0, 1.0);
    
    vec3 sky_horizon = vec3(1.0, 0.3, 0.1);
    vec3 sky_zenith = vec3(0.0, 0.0, 0.0);
    vec3 sky = sky_zenith + sky_horizon * pow(1.0 - uv.y, 0.3);
    
    vec3 col = (vec3(1.0, 1.0, cos(time) * 0.1 + 0.9) - sky) * c + sky;
    
    for (float i = 0.0; i < 3.0; i += 1.0)
    {
        float terrain = sin((uv.x * pow(4.0 - i, 1.29) + time * 1.1) * 0.8 - 1.8 * i - 0.98) * 0.1 + 0.5 - i * 0.1;
        if (uv.y < terrain)
           {
            col = vec3(0.6, 0.3, 0.1) * (i / 22.0 + 0.2) * 0.7;
        }
    }
    // Output to screen
    glFragColor = vec4(col,1.0);
}

