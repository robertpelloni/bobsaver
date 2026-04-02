#version 420

// original https://www.shadertoy.com/view/NlVGRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (6.283185307)
// i want to use hex codes like in image editing programs,
// so here's an improved macro by FabriceNeyret2
#define HEX(x) vec3( ( ivec3(x) >> ivec3(16,8,0) ) & 255 ) / 255.

vec3 color(float x){
    const int colorCount = 8;
    vec3[] c = vec3[](
        HEX(0xb810b0),
        HEX(0xe020c0),
        HEX(0xf0e040),
        HEX(0xc0ff80),
        vec3(1),
        HEX(0xa0ffe0),
        HEX(0x7080F0),
        HEX(0x8000a0)
    );
    x *= float(colorCount);
    int lo = 1048576 + int(floor(x));
    
    return mix(
        c[lo % colorCount],
        c[(lo + 1) % colorCount],
        fract(x)
    );
}

void main(void)
{
  float time = fract(time / 4.0);
  // make the center of the canvas (0.0, 0.0) and
  // make the long edge of the canvas range from -1.0 to +1.0
  float scale = max(resolution.x, resolution.y);
  vec2 uv = (gl_FragCoord.xy - 0.50 * resolution.xy) / scale;

  vec2 sep = vec2(sin(time * TAU * 0.5), cos(time * TAU * 0.5)) * 0.1;
  
  const float zoomSpeed = 6.;
  const float ringSpacing = 0.8;

  float dist = log(length(uv));
  float distA = log(length(uv - sep) * ringSpacing) - zoomSpeed * time;
  float distB = log(length(uv + sep) * ringSpacing) - zoomSpeed * time;
  
  float alphaA = step(0.8, fract(distA));
  float alphaB = step(0.8, fract(distB));

  vec3 colA = alphaA * color(time * 0.5);
  vec3 colB = alphaB * color(time * 0.5 + 0.5);
  
  vec3 col = mix(
  colA + colB,
  vec3(1.),
  clamp(alphaA + alphaB - 1.,
   0., 1.));
   
  float swirl = step(
    0.7,
    fract(
      dist * 4.
    + atan(uv.y, uv.x) * 8. / TAU
    + time * 8.
    )
  );
  col += smoothstep(-1.0, -0.6, dist) * swirl;
  
  // Output to screen
  glFragColor = vec4(
    col, 1.0
  );
}
