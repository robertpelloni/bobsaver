#version 420

// original https://www.shadertoy.com/view/4lVBDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/// This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License. 
/// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/.

/// mathematical constants
const float PI = 3.1415926535897932384626433832795;
const float PI_2 = 1.57079632679489661923;

// distance function from Inigo Quilez
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p) - b;
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

/// my code
// translate distance function
vec2 translate(vec2 p, vec2 offset)
{
    return p - offset;
}
// draw antialiased point with minimum pixel size 
vec3 draw(in vec3 buffer, in float d, in float r, in vec3 color)
{
    float up = min(resolution.x, resolution.y);
    d = up * d;
    r = r * up / 360.0;
      float aa = fwidth(d);
       return mix(buffer, color, 1.0 - smoothstep(r - aa, r + aa, d));
}

void main(void)
{
    // normalize pixel coordinates centered at origin
    vec2 coord = gl_FragCoord.xy - resolution.xy/2.0;
    vec2 uv = coord/min(resolution.x,resolution.y);
    vec2 p = uv;
    // time
    const float speed = 2.0;
    float time = speed * time;
    // repeat and ripple
    const float r = 1.0 / 16.0;
    float offset = 6.0 * r * (cos(time / 2.0) * cos(floor(p.x / r) / 2.0) + cos(floor(p.y / r) / 2.0));
    float phaseTime = time + offset;
    vec2 translation = vec2(cos(phaseTime), sin(2.0 * phaseTime)) * r / 4.0;
    vec2 q = translate(p, translation);
    const vec2 c = vec2(r);
    q = mod(q, c) - 0.5 * c;
    // scale
    float s = 0.5001 + 32.0 * translation.y;
    // distance
    float d = sdBox(q / s, vec2(r / 8.0)) * s;
    // color and antialias
    const vec3 yellow = vec3(1.0, 233.8095 / 255.0, 69.6405 / 255.0);
    const vec3 blue = vec3(0.0, 32.181 / 255.0, 76.8825 / 255.0);
    vec3 col = mix(blue, yellow, 0.5 + 32.0 * translation.y);
    col = draw(vec3(0.0), d, 1.5, col);
    // Output to screen
    glFragColor = vec4(col,1.0);
}
