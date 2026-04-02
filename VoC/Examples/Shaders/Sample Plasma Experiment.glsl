#version 420

// original https://www.shadertoy.com/view/cdKGD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float time = time * 0.2 + 32.0;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y; //aspect ratio
    float PI = 3.14159;
    float a = atan(uv.y, uv.x) / PI;
    float b = length(uv);
    float q = a; //removing these, and combining them together to above changes the output...oddly.
    float p = b; //
    a += 0.85 * cos(2.0 * PI * b - time * 8.0);
    b += 0.10 * sin(2.0 * PI * a + time * 8.5);
    q += 0.75 * cos(2.0 * PI * p - time * 8.0);
    p += 0.15 * sin(2.0 * PI * q + time * 8.5);
    
    vec2 d = vec2(b * cos(a * PI), b * sin(a * PI));
    vec2 f = vec2(p * cos(q * PI), p * sin(q * PI));

    vec3 col = vec3(
    smoothstep(0.5, 0.1, length(f)) + uv.y * uv.y * b * b,
    smoothstep(0.5, 0.1, length(d)) + uv.y * uv.x * b * a, 
    smoothstep(0.5, 0.1, length(uv)) + uv.y * uv.y * a * a);
    glFragColor = vec4(col, 1.0);
}
