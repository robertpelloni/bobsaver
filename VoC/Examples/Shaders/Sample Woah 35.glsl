#version 420

// original https://www.shadertoy.com/view/7ltSRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float RADIUS = 10.0 * sin(time / 4.0);
    float RADIUS2 = 64.0;
    float RATE = 2.0 / RADIUS;
    
    vec2 origin = vec2(resolution.x / 2.0, resolution.y / 2.0) + (RADIUS2 * vec2(cos(RATE * time), sin(RATE * time)));
    
    vec2 dMouse = origin - gl_FragCoord.xy;
    float brightness = 1.0 - (length(dMouse) / RADIUS);
    
    
    // Output to screen
    glFragColor = vec4(sin(brightness), cos(brightness), sin(time + brightness), 1.0);
}
