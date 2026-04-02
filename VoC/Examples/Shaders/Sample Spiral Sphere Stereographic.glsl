#version 420

// original https://www.shadertoy.com/view/XcKSRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float halfpi = asin(1.);

vec3 plane2sphere(vec2 p) {
    float r = length(p);
    float c = 2.*r / (dot(p, p)+1.);
    return vec3(p*c/r, sin(2.*atan(r)-halfpi));
}

vec3 rotate(vec3 v, float xz, float yz) {
    float c1 = cos(yz);
    float s1 = sin(yz);
    float c2 = cos(xz);
    float s2 = sin(xz);
    vec3 u = vec3(v.x, c1*v.y-s1*v.z, c1*v.z+s1*v.y);
    return vec3(c2*u.x-s2*u.z, u.y, c2*u.z+s2*u.x);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    //vec2 mouse = mouse*resolution.xy.xy == vec2(0) ? vec2(time, 0.) : (mouse*resolution.xy.xy * 2.0 - resolution.xy) / resolution.y;
    vec2 mouse = vec2(time, 0.);
    vec3 v = rotate(plane2sphere(2.*uv), -2.*mouse.x, 2.*mouse.y);
    vec2 p0 = vec2(atan(v.y, v.x), asin(v.z))/halfpi;
    vec2 p = mod(2.*p0, 1.);
    
    vec3 col = abs(p.x+p.y-0.5) < 0.25 || abs(1.5-p.x-p.y) < 0.25 ? vec3(0., 0.6, 0.9) : vec3(0., 0.4, 0.6);
    if (p0.x > 0.) col = 1.-col;
    if (p0.y > 0.) col = 1.-col;
    if (p0.x > 1. || p0.x < -1.) col = 1.-col;
    
    glFragColor = vec4(col, 1.);
}