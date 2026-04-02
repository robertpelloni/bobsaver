#version 420

// original https://www.shadertoy.com/view/XsjcDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 p, float theta)
{
    vec2 sncs = vec2(sin(theta), cos(theta));
    return vec2(p.x * sncs.y - p.y * sncs.x, dot(p, sncs));
}

float swirl(vec2 coord, float t)
{
    float l = length(coord) / resolution.x;
    float phi = atan(coord.y, coord.x + 1e-6);
    return sin(l * 10.0 + phi - t * 4.0) * 0.5 + 0.5;
}

float halftone(vec2 coord, float angle, float t, float amp)
{
    coord -= resolution.xy * 0.5;
    float size = resolution.x / (60.0 + sin(time * 0.5) * 50.0);
    vec2 uv = rotate(coord / size, angle / 180.0 * 3.14); 
    vec2 ip = floor(uv); // column, row
    vec2 odd = vec2(0.5 * mod(ip.y, 2.0), 0.0); // odd line offset
    vec2 cp = floor(uv - odd) + odd; // dot center
    float d = length(uv - cp - 0.5) * size; // distance
    float r = swirl(cp * size, t) * size * 0.5 * amp; // dot radius
    return 1.0 - clamp(d  - r, 0.0, 1.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    glFragColor = vec4(uv,0.5+0.5*sin(time),1.0);
    
    vec3 c1 = 1.0 - vec3(1, 0, 0) * halftone(gl_FragCoord.xy,   0.0, time * 1.00, 0.7);
    vec3 c2 = 1.0 - vec3(0, 1, 0) * halftone(gl_FragCoord.xy,  30.0, time * 1.33, 0.7);
    vec3 c3 = 1.0 - vec3(0, 0, 1) * halftone(gl_FragCoord.xy, -30.0, time * 1.66, 0.7);
    vec3 c4 = 1.0 - vec3(1, 1, 1) * halftone(gl_FragCoord.xy,  60.0, time * 2.13, 0.4);
    glFragColor = vec4(c1 * c2 * c3 * c4,1);
}
