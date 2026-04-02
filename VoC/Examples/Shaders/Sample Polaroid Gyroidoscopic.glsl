#version 420

// original https://www.shadertoy.com/view/7dGfRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// playing with gyroid cyclic noise and polar coordinates
// trying to find elegance with simplicity

#define t time*.1

float gyroid (vec3 seed) { return dot(sin(seed),cos(seed.yzx)); }
float fbm (vec3 seed) {
    float result = 0.;
    float a = .5;
    for (int i = 0; i < 3; ++i) {
        result += sin(gyroid(seed/a)*3.+t/a)*a;
        a /= 2.;
    }
    return result;
}
void main(void) {
    
    vec3 p = vec3((gl_FragCoord.xy-resolution.xy/2.)/resolution.y,0);
    vec3 color = vec3(p*.5+.5);
    
    p = vec3(
        atan(p.y,p.x) * .5,
        log(length(p)) - t,
        t+p.y );
    
    float shade = (fbm(p)+1.)/2.;
    glFragColor = vec4(mix(color,vec3(1),shade)*shade, 1);
}
