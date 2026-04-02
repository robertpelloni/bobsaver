#version 420

// original https://www.shadertoy.com/view/wlVfWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 motionFunction (float i) {
  float t = time;

  return vec2(
    (cos(t * .31 + i * 3.) + cos(t * .11 + i * 14.) + cos(t * .78 + i * 30.) + cos(t * .55 + i * 10.)) / 4.,
    (cos(t * .13 + i * 33.) + cos(t * .66 + i * 38.) + cos(t * .42 + i * 83.) + cos(t * .9 + i * 29.)) / 4.
  );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.x;
    
    float alias = 100. + 40. * motionFunction(7.).x;
    uv = floor(uv * alias) / alias;
    vec2 uv1 = uv + motionFunction(1.);
    vec2 uv2 = uv + motionFunction(2.);
    vec2 uv3 = uv + motionFunction(3.);
    vec3 col1 = .5 + .5 * cos(length(uv1) * 20. + uv1.xyx + vec3(0, 2, 4));
    vec3 col2 = .5 + .5 * cos(length(uv2) * 10. + uv2.xyx + vec3(0, 2, 4));
    vec3 col3 = .5 + .5 * cos(length(uv3) * 10. + uv3.xyx + vec3(0, 2, 4));
    vec3 col = col1 - col2 + col3;

    glFragColor = vec4(col, 1.);
}
