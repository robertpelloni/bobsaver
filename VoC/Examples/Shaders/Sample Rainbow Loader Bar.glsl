#version 420

// original https://www.shadertoy.com/view/7dVXzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define HEIGHT      0.05   // Height of the Bar
#define BACKLIGHT   0.6    // Backlight
#define BRIGHTNESS  0.33   // overall Brightness
#define GLOW        1.25   // Glow intensity of the Bar

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy - 0.5;
    
    float c = BACKLIGHT;
    float a = abs(uv.y);
    float s = 1.0 - smoothstep(0.0, HEIGHT, a);
    c *= 1.33 - smoothstep(0.0, 0.5, a);
    c*=c*c;
    
    if(abs(uv.y) < HEIGHT) { c += s; }
    
    glFragColor = vec4(cos(6.283 * (uv.x + time + vec3(0.0,.33,0.66))) + GLOW, 1.0) * c * BRIGHTNESS;
}
