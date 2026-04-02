#version 420

// original https://www.shadertoy.com/view/fttGRs

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
        vec3(0),
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

float shape(vec2 uv, float angle) {
    vec2 normalA = vec2(cos(angle), sin(angle));
    vec2 normalB = vec2(cos(angle + TAU / 3.), sin(angle + TAU / 3.));
    vec2 normalC = vec2(cos(angle - TAU / 3.), sin(angle - TAU / 3.));
    return max(
        max(
            (dot(uv, normalA)),
            (dot(uv, normalB))
        ),
        (dot(uv, normalC))
    );
}

void main(void)
{
  float time = fract(time / 3.0);
  // make the center of the canvas (0.0, 0.0) and
  // make the long edge of the canvas range from -1.0 to +1.0
  // we'll use the scale variable later for antialiasing bc it's the size of one pixel
  float scale = max(resolution.x, resolution.y);
  vec2 uv = (gl_FragCoord.xy - 0.50 * resolution.xy) / scale;

  // i blend each square's color in order to antialias this shader
  // are you proud of me yet Fabrice
  vec3 col = vec3(0., 0., 0.);
  float opacity = 0.;
  float colOffset = 0.09;
  const float iters = 48.;
  float size = 1.3;
  float sizeMult = 0.88;
  float angleOffset = 0.03 * (2.0 + sin(time * TAU));
  float evenOffset = (1. + sin(time * TAU));
  // i know, loops in glsl code, ew right
  for (float i = 0.; i < iters; i++) {
      // subtract from size and multiply by scale to get
      // a nice "pixels from boundary" value
      float dist = (shape(
          uv, -time * TAU + angleOffset * i + evenOffset * mod(i, 2.)
      ) - size) * -scale;
      //dist /= 8.; // antialias debug
      vec3 thisColor = color(time * 3. + colOffset * i);
      if (
          dist <= 0.
      ) {
          col += (1. - opacity) * thisColor;
          opacity = 1.;
      } else if (
          dist < 1.
      ) {
          float newOpacity = max(0., (1. - dist) * (1. - opacity));
          col += newOpacity * thisColor;
          opacity += newOpacity;
      } else {
          // do nothing
      }
      // i'm not sure if this saves time for gpu calculation
      // but i'm doing it anyway because it pleases me:
      if (opacity >= 1.) {break;}
      
      size *= sizeMult; // better than calling pow()
  }
  
  // Output to screen
  glFragColor = vec4(
    col, 1.0
  );
}
