#version 420

// original https://www.shadertoy.com/view/WstSRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.141592;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 cuv = 2.0 * (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    float t = time * 2.0;
    float col = 0.0;
    vec3 pixel = vec3(0.0);
    cuv *= 7.812;
    
    float v1 = sin(cuv.x + t*0.4);
    float v2 = sin(cuv.y + sin(t));
    float v3 = tan(sin(atan(cuv.x, cuv.y) + t));
    float v4 = sin(sin(length(cuv)) + t);
    col = v1 + v2 + v3 + v4;
    col = cos(sin(1.3*col));
    col = 0.5 + 0.5 * col;

    if (!(abs(uv.x) < 0.1) && !(abs(uv.x) > 0.9)) {
           pixel += 0.4 * vec3(col * 0.3, 0.5+0.5*sin(v1 + col * PI), col);
    }
    if (!(abs(uv.y) < 0.2) && !(abs(uv.y) > 0.8)) {
        pixel += 0.5 * vec3(col * 0.2, sin(v2 + col * PI), sin(v4 + col * 2.0 * PI));
    }
    pixel = abs(pixel * 4.0) ;

    glFragColor = vec4(pixel, 1.0);
}
