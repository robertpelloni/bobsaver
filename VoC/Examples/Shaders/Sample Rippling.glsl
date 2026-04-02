#version 420

// original https://neort.io/art/c4ufkf43p9fe3sqpildg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define COLOR_N vec3(0.15, 0.34, 0.6)
#define COLOR_T vec3(0.313, 0.816, 0.816)
#define COLOR_M vec3(0.745, 0.118, 0.243)
#define COLOR_K vec3(0.475, 0.404, 0.765)
#define COLOR_H vec3(1.0, 0.776, 0.224)

#define pi acos(-1.0)

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);
    
    float a = atan(uv.y, uv.x) + time * 0.9;
    float t = sin(a * 5.0) * (0.5 / abs(sin(length(uv * 15.0) - time * 5.0)));
    t -= abs(sin(length(uv*3.0) - time * 5.0));
    t -= abs(sin(length(uv*7.0) + time * 3.0));
    color += 0.2 / abs(0.7 + t - length(uv)) * COLOR_N;

    glFragColor = vec4(color, 1.0);
}
