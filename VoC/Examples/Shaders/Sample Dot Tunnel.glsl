#version 420

// original https://www.shadertoy.com/view/sly3WV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (3.14159265 * 2.)
#define HEX(x) vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255) / 255.
vec3 color(float x){
    const int colorCount = 8;
    vec3[] c = vec3[](
        HEX(0xb010b0),
        HEX(0xe020c0),
        HEX(0xf0e040),
        HEX(0xc0ff80),
        HEX(0xb0ffb0),
        HEX(0xa0ffe0),
        HEX(0x7080F0),
        HEX(0x8000a0)
    );
    x *= float(colorCount);
    int lo = int(floor(x));
    
    return mix(
        c[lo],
        c[(lo + 1) % colorCount],
        smoothstep(0.95, 1., fract(x))
    );
}

#define LENRES 3.
#define ANGRES 40.

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
    lenSq * 1.05;
    
    float lenRd = round(lenSq * LENRES);
    float angRd = round(angle * ANGRES);
    
    vec3 colA = color(fract(-0.33 * lenRd / LENRES + angRd / ANGRES * 1. - 1. * time));
    
    float spiral = sin(TAU * (
         lenRd * 0.3 / LENRES
       + angRd * 2./ ANGRES
       + time * 3.
    ));
    
    spiral = step(
    length(
    vec2(lenRd - lenSq * LENRES,
    angRd - angle * ANGRES)
    ),
    spiral * 0.2 + 0.3);

    // Time varying pixel color
    vec3 col = colA * (spiral);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
