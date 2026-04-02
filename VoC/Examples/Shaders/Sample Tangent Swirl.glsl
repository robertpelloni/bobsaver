#version 420

// original https://www.shadertoy.com/view/tdGXDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

void main(void) {
    float s = 10.0;
    vec2 uv = (gl_FragCoord.xy * s - 0.5 * s * resolution.xy) / resolution.xy;
    vec2 uvr = rotate(uv, time / 4.0);
    vec2 uvl = rotate(uv, -time / 4.0);
    for (int i = 0; i < 5; i++) {
      uvl += uv * dot(uvl, cos(uvr)) / 50.0;
      uvr += uv * dot(uvr, sin(uvl)) / 50.0;
    }
    vec3 col = 1.0 - pow(tan(uvr.yxy) + tan(uvl.yxx / 2.0) + tan(uvr.yxy / 3.0), vec3(1.0,1.0,1.0) * 1.5) * 0.15;
    glFragColor.rgb = col;
}
