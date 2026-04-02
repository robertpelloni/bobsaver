#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/fdGXD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 3.14159265 * 2.
#define HEX(x) vec3((x >> 16) & 255, (x >> 8) & 255, x & 255)/255.
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
    int lo = int(floor(x));
    
    return mix(
        c[lo],
        c[(lo + 1) % colorCount],
        smoothstep(0., 1., fract(x))
    );
}

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
    
    float spiral = fract(
         lenSq * 0.3
       + angle * 0.25
       + time * -3.
       + 0.08 * sin((time * 2. + lenSq * 0.5 + angle * 0.25) * TAU)
       + 0.07 * sin((time * -1. + lenSq * 0.2 + angle * -0.5) * TAU)
    );

    // Time varying pixel color
    vec3 col = color(spiral);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
