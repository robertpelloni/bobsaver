#version 420

// original https://www.shadertoy.com/view/Xd3BWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    uv -= 0.5;
    uv *= 2.0;
    
    float d = length(uv);
    float angle = atan(uv.y, uv.x);
    float PI_TWO = 6.283185;
    
    float timeMultiplier = time * time / 30.0;
    
    float c1 = sin(d * 20.0  + angle * 5.0 + timeMultiplier * 4.0);
    float c2 = sin(d * 100.0 + angle * 2.0 + timeMultiplier * 8.0 + (0.33 * PI_TWO));
    float c3 = sin(d * 40.0  + angle * 3.0 + timeMultiplier * 12.0 + (0.66 * PI_TWO));
    
    vec3 color1 = vec3(c1);
    color1.r *= mix(0.2, 0.8, d);
    color1.g *= mix(0.9, 0.6, d);
    color1.b *= mix(0.5, 0.2, d);
    
    vec3 color2 = vec3(c2);
    color2.r *= mix(0.3, 0.8, d);
    color2.g *= mix(0.4, 0.3, d);
    color2.b *= mix(0.4, 0.2, d);
    
    vec3 color3 = vec3(c3);
    color3.r *= mix(0.7, 0.2, d);
    color3.g *= mix(0.1, 0.7, d);
    color3.b *= mix(0.2, 0.6, d);
    

    glFragColor = vec4(color1 + color2 + color3, 1.0);
}
