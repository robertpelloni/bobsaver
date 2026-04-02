#version 420

// original https://www.shadertoy.com/view/wt3XWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv;
  
    uv = vec2(0.5 * 3.14159, 0.5 * 3.14159) + (vec2(resolution.x / 2.0, resolution.y / 2.0) - gl_FragCoord.xy) / (8.0);
    
    float value = sin(uv.x) * cos(uv.y) * time * 6.0;
    float color = sin(value) * 3.0;

    float low = abs(color);
    float med = abs(color) - 1.0;
    float high = abs(color) - 2.5;
    if(color > 0.0) {
      glFragColor = vec4(med, high, med,1.0);
    } else {
      glFragColor = vec4(min(0.5, med / 2.0), high, med,1.0);
    }
}
