#version 420

// original https://www.shadertoy.com/view/Xlj3Rm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float speed = 1.8;
const float widthFactor = 4.0;

vec3 calcSine(vec2 uv, 
              float frequency, float amplitude, float shift, float offset,
              vec3 color, float width, float exponent)
{
    float angle = time * speed * frequency + (shift + uv.x) * 6.2831852;
    
    float y = sin(angle) * amplitude + offset;
    
    float scale = pow(smoothstep(width * widthFactor, 0.0, distance(y, uv.y)), exponent);
    
    return color * scale;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 color = vec3(0.0);
    
    color += calcSine(uv, 0.20, 0.15, 0.0, 0.5, vec3(0.0, 0.0, 1.0), 0.2, 15.0);
    color += calcSine(uv, 0.40, 0.15, 0.0, 0.5, vec3(0.0, 1.0, 1.0), 0.1, 17.0);
    color += calcSine(uv, 0.60, 0.15, 0.0, 0.5, vec3(0.5, 0.8, 1.0), 0.05, 23.0);

    color += calcSine(uv, 0.18, 0.07, 0.0, 0.7, vec3(0.0, 0.0, 0.7), 0.2, 15.0);
    color += calcSine(uv, 0.26, 0.07, 0.0, 0.7, vec3(0.0, 0.6, 0.7), 0.1, 17.0);
    color += calcSine(uv, 0.46, 0.07, 0.0, 0.7, vec3(0.2, 0.4, 0.7), 0.05, 23.0);

    color += calcSine(uv, 0.58, 0.05, 0.0, 0.3, vec3(0.0, 0.0, 0.7), 0.2, 15.0);
    color += calcSine(uv, 0.34, 0.05, 0.0, 0.3, vec3(0.0, 0.6, 0.7), 0.1, 17.0);
    color += calcSine(uv, 0.52, 0.05, 0.0, 0.3, vec3(0.2, 0.4, 0.7), 0.05, 23.0);

    glFragColor = vec4(color,1.0);
}
