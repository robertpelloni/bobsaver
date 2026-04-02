#version 420

// original https://www.shadertoy.com/view/MtyczK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define       TAU 6.28318530717958647
#define thickness .005
#define         e 7.5/resolution.y
#define         r .35
#define         R .5

vec3 hsv2rgb(vec3 c) {
  // Íñigo Quílez
  // https://www.shadertoy.com/view/MsS3Wc
  vec3 rgb = clamp(abs(mod(c.x*6.+vec3(0.,4.,2.),6.)-3.)-1.,0.,1.);
  rgb = rgb * rgb * (3. - 2. * rgb);
  return c.z * mix(vec3(1.), rgb, c.y);
}

vec3 circle(in vec2 uv, in vec2 c, in float aa){
    float ba = fract(atan(uv.y, uv.x) / TAU + .5);
    float la = fract(atan(uv.x - c.x, uv.y - c.y) / TAU + .5 - time * .5 - aa);
    vec3 col = hsv2rgb(vec3(ba, smoothstep(0., .2, 1. - la), la));
    return col * smoothstep( (thickness + e) * la, thickness * la, abs(r - length(uv - c)));
}

void main(void) {
  vec2 uv = (2. * gl_FragCoord.xy - resolution.xy ) / resolution.y;
  for(float i=0.; i<=360.; i+=30.)
        glFragColor.rgb += circle(uv, vec2(R * cos(radians(i)), R * sin(radians(i))), radians(i * 4.));
}
