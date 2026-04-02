#version 420

// original https://www.shadertoy.com/view/fdtyR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TURN 6.283185
// rotation matrix. idk why it works. thanks fabriceneyret!
#define rot(a) mat2( cos( a + vec4(0,33,11,0) ) )

#define HEX(x) vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255) / 255.
#define COLOR_SMOOTHING 0.1
vec3 color(float x) {
    float factor = mod(x, 4.);
    float f0 = smoothstep(0., 0. + COLOR_SMOOTHING, factor);
    float f1 = smoothstep(1., 1. + COLOR_SMOOTHING, factor);
    float f2 = smoothstep(2., 2. + COLOR_SMOOTHING, factor);
    float f3 = smoothstep(3., 3. + COLOR_SMOOTHING, factor);
    return (
        HEX(0x009BE8) * (f0 - f1) +
        HEX(0xEB0072) * (f1 - f2) +
        HEX(0xfff100) * (f2 - f3) +
        HEX(0x010a31) * (f3 - f0 + 1.)
    );
}

#define SQRT3 (1.7320508)
float hex(vec2 uv) {
    uv = abs(uv);
    return max(
        (uv.x + uv.y * SQRT3) / 2.,
        uv.x
    );
}

float zigzag(float x) {
    return 1. - abs(1. - 2. * fract(x));
}

float fluct(float x) {
float x2 = x*x;
    return -0.6 * x2 * x2
    + 2.4 * x2 * x
    -2.3 * x2
    + 0.1 * x;
}

float fxor(float a, float b) {
    return a + b - 2. * a * b;
}

#define LAYERSPERLOOP 4.
#define LAYERS 24.
#define LAYERFADE 2.
#define LAYERSCALE 3.0

void main(void)
{
    float t = fract(time / 2.);
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / length(resolution.xy);
    
    const vec3 bg0 = HEX(0xC4D7F0);
    const vec3 bg1 = HEX(0xFFFFFF);
    float r = log(length(uv));
    float aaR = min(0.5, fwidth(r) * 6.);
    float zigR = smoothstep(
        -aaR, aaR, zigzag(4. * r - 2.5 * t) - 0.5
    );
    float theta = atan(uv.y, uv.x) * 24. / TURN;
    float aaTheta = min(fwidth(atan(uv.y, uv.x)), fwidth(atan(uv.x, uv.y))) * 6.;
    float zigTheta = smoothstep(
        -aaTheta, aaTheta, zigzag(theta + 0.5 * t) - 0.5
    );
    vec3 bg = mix(bg0, bg1,
        zigR + zigTheta - 2. * zigR * zigTheta
    );
    vec3 col = bg;
    
    for (float i = 0.; i < LAYERS; i++) {
        float z = LAYERS - (i + t * LAYERSPERLOOP);
        float layerDark = clamp(
            (i + (t - 1.) * LAYERSPERLOOP) * LAYERFADE,
            0., 1.
        );
        float layerAlpha = clamp(z * 5., 0., 1.); 
        vec2 uvScale = (uv
        * max(0.03, z * LAYERSCALE)
        + fluct(z * 0.35) * vec2(0., -1.))
        * rot(z * TURN / -6. / LAYERSPERLOOP)
        ;
        float hex = hex(uvScale);
        float aa = fwidth(hex) * 1.3;
        col = mix(
            col,
            mix(
                bg,
                mix(
                    color(-i),
                    vec3(0),
                    fxor(
                        step(0.5, zigzag(uv.y * z * 12.0 + z * 0.2)),
                        step(0.5, zigzag(uv.x * z * 12.0))
                    )
                ),
                layerDark
            ),
            smoothstep(
                0., aa,
                0.12 - abs(0.5 - hex)
            ) * layerAlpha
        );
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
