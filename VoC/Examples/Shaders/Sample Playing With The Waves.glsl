#version 420

// original https://neort.io/art/c38tqgk3p9f8s59bekfg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define F(R) (sin(R-time*10.)*.02-cos(R-time*10.))*exp(-R*.02)/R

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    float R;
    vec2 q;
    vec2 n = vec2(0);
    
    q = p * 50.;
    R = length(q);
    n += q * F(R);
    
    q = (p - (mouse * 2.0 - 1.0) * resolution.xy / min(resolution.x, resolution.y)) * 50.;
    R = length(q);
    n += q * F(R);
    
    float s = max(dot(normalize(vec3(-1,2,5)), normalize(vec3(n,1))), 0.);
    vec3 col = vec3(pow(s, 60.) + s * 0.7);
    
    glFragColor = vec4(col, 1.0);
}
