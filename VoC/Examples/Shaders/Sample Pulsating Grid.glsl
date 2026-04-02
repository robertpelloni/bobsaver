#version 420

// original https://www.shadertoy.com/view/sdtSzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.x;
    uv *= 10.0;      // Scale up the space by 3
    uv = fract(uv); // Wrap around 1.0
    
    float col = 1.0;
    float minLineThickness = 0.1;
    float speed = 5.0;
    float pulseWidth = 150.;
    
    float b = abs(cos(time*speed+gl_FragCoord.xy.x/pulseWidth)*0.03+minLineThickness);
    float c = abs(sin(time*speed+gl_FragCoord.xy.x/pulseWidth)*0.03+minLineThickness);
    
    
    col *= smoothstep(b, 0.00, abs(abs(uv.x)-0.5));
    col += smoothstep(c, 0.00, abs(abs(uv.y)-0.1));

    glFragColor = vec4(.0, col, 0.0,1.0);
}
