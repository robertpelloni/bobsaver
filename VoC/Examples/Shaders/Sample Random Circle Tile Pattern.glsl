#version 420

// original https://neort.io/art/bok2u0k3p9fd1q8octhg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

highp float rand(vec2 co){
    highp float a = 0.129898;
    highp float b = 0.78233;
    highp float c = 437.585453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

void main() {
    vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    st *= 10.0;
    vec2 rst = mod(st,2.0);
    rst -= 1.0;
    vec2 id = rst - st;
    vec3 color = vec3(
      fract(sin(length(rst) + (length(rst) + rand(id) - time))),
      fract(sin(length(id)) + rand(id)),
      fract((length(rst.x) * length(rst.y)))
    );

    color *= vec3(fract(time + rand(id)));

    glFragColor = vec4(color, 1.0);
}
