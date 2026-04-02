#version 420

// original https://neort.io/art/bmrg0fs3p9f7m1g02nq0

// ref: http://glslsandbox.com/e#58164.0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    uv *= 12.;
    
    float p0 = .95;
    float p1 = 1.15;
    float p2 = 1.2;
    vec2 v0 = vec2(0.);
    
    for (int i = 0; i < 6; i++) {
        vec2 r = vec2( cos(uv.y*p0 - v0.x + time/p1), sin(uv.x*p0 + v0.x - time/p1) )/p2;
        r += vec2(r.y, r.x) * .2;
        
        uv += r;
        
        p0 = 1.55;
        p1 = 1.45;
        p2 = 1.5;
        
        v0 = r+.9*time*p1;
    }
    
    float r = sin(uv.x - time) *.3 +.5;
    float g = sin(uv.y + time) *.2 +.4;
    float b = cos((sqrt(uv.x*uv.x + uv.y*uv.y) + time*2.)) *.3 +.4;
    
    glFragColor = vec4(vec3(r,g,b), 1.0);
}
