#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XttBWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
 ivec2 uv = ivec2(gl_FragCoord.xy / 2.);

 int mask = (int(time / 2.) & 7) << 2;

 vec3 bg = vec3(.3, .3, .3),
    warp = vec3(gl_FragCoord.xy/resolution.xy, 1.),
    weft = vec3(.8, .8, .5);

 glFragColor = vec4(((uv.x^uv.y) & mask) == 0
  ? 1 == ((uv.x ^ uv.x >> 1) & 1) ? warp : bg
  : 1 == ((uv.y ^ uv.y >> 1) & 1) ? weft : bg,
                  1.0);
}
