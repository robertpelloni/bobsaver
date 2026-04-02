#version 420

// original https://www.shadertoy.com/view/stlBzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    
    // (better to use gl_FragCoord.xy for a pixelated version)
    // uv = floor(0.25 * resolution.y * uv) / (0.25 * resolution.y);
    
    float s;   
    float m = mod(floor(0.5 * time), 10.) + 1.;
    
    float n = 40.;
    for (float i = 0.; i < n; i++) {
        float t = 0.2 * time + 2. * pi * i / n; 
        
        // Uncomment for other versions
        float y = sin(m * t + 11. * uv.x) -  4. * uv.x * cos(t * 0.5);
        // y = sin(m * t + 11. * uv.x) -  4. * uv.x * cos(t);
         y = sin(t + 11. * uv.x) -  4. * uv.x * cos(t * 0.5);
        
        float k = 1. / resolution.y;
        s = max(s, smoothstep(-k, k, -abs(uv.y - 0.25 * y) + k));
    }

    vec3 col = vec3(s);
    
    glFragColor = vec4(col,1.0);
}
