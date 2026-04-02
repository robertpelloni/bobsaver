#version 420

// original https://www.shadertoy.com/view/NtsBWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI (3.141592653589)

vec2 rotate(vec2 uv, float theta) {
    return vec2(
        uv.x * cos(theta) - uv.y * sin(theta),
        uv.y * cos(theta) + uv.x * sin(theta)
    );
}

vec2 rotEffect(vec2 uv, float t) {
    float scale = exp2(-t * 0.5);
    return rotate(
        floor(
            rotate(
                uv * scale, t * PI / 4.
            )
        ) + 0.5,
        -t * PI / 4.
    ) / scale;
}

float zigzag(float x) {
    return 1. - abs(1. - fract(x) * 2.);
}

float spiral(vec2 uv, float t) {
    vec2 rt = vec2(log(0.2 + length(uv)), atan(uv.y, uv.x) / PI / 2.);
    return smoothstep(
        0.0, 1.0,
        zigzag(
            1.3 * rt.x
            - 3. * rt.y
            + 2. * t
        )
    );
}

#define LAYERS 4.

void main(void)
{
    float t = fract(time / 4.);

    // Normalized pixel coordinates (from 0 to 1)
    float scale = 16.00;
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / length(resolution.xy);
    uv *= 1. + 0.02 * sin(3. * t * PI * 2.);
    float z = 0.;
    
    for (float i = 0.; i < LAYERS; i++) {
        float ti = t + i;
        vec2 uv0 = rotEffect(uv * scale, ti);
        z += spiral(
            uv0 / scale, t
        ) * min(min(ti, LAYERS - ti), 1.) / (LAYERS - 1.);
    }
    vec3 col = mix(
       vec3(0.8, 0.2, 0.6),
       vec3(1.0, 0.5, 0.7),
       z * 2.
    );
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
