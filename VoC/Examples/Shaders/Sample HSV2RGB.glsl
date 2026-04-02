#version 420

// original https://www.shadertoy.com/view/wlsSRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://github.com/hughsk/glsl-hsv2rgb/blob/master/index.glsl
vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(3. / 3., 2. / 3., 1. / 3., 3.);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6. - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 hsv2rgb2(vec3 c, float k) {
    return smoothstep(0. + k, 1. - k,
                      .5 + .5 * cos((vec3(c.x) + vec3(3., 2., 1.) / 3.) * radians(360.)));
}

void main(void)
{
    vec2 uv = 1.2 * (gl_FragCoord.xy / resolution.xy) - .1;

    //uv.x = round(uv.x * 8.) / 8.;

    vec3 col0 = hsv2rgb(vec3(uv.x, 1., 1.));
    vec3 col1 = hsv2rgb2(vec3(uv.x, 1., 1.), .07);

    vec3 col = mix(col0, col1, smoothstep(.4, .6, .5 + .5 * sin(3. * time)));

    if (uv.y > .5) {
        glFragColor = vec4(col, 1.);
    } else {
        glFragColor = vec4(smoothstep(.02, 0., abs(2.4 * uv.y - col)), 1.);
    }
}
