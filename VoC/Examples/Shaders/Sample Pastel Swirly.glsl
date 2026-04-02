#version 420

// original https://www.shadertoy.com/view/fltXRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (3.14159265 * 2.)
#define HEX(x) vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255) / 255.
#define ZIGZAG(x) (1. - abs(1. - 2. * fract(x)))
vec3 color(float x){
    const int colorCount = 6;
    vec3[] c = vec3[](
        HEX(0x70c0ff),
        HEX(0xff70c0),
        HEX(0xffd070),
        HEX(0xcf80e0),
        HEX(0x70ffc0),
        HEX(0xffa8e0)
    );
    x *= float(colorCount);
    int lo = int(floor(x));
    
    return mix(
        c[lo],
        c[(lo + 1) % colorCount],
        smoothstep(0.95, 1., fract(x))
    );
}

#define COLWID 0.4

void main(void)
{
    float time = fract(time / 4.);
    // Scales pixel coordinates, so that
    // the center is distance 0 and
    // diagonals are distance 1
    vec2 uvR = 2. * gl_FragCoord.xy - resolution.xy;
    vec2 uv = uvR / length(resolution.xy);

    float lenSq = log(uv.x * uv.x + uv.y * uv.y);
    float angle = atan(uv.y, uv.x) / TAU;
    
    vec3 colA = color(fract(
      ZIGZAG(
        0.22 * lenSq
        + -1. * angle + 1. * time
      ) * COLWID
      + 0.05 * lenSq
      + 2. * time
    ));
    

    // Time varying pixel color
    vec3 col = colA;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
