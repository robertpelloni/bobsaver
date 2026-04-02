#version 420

// original https://www.shadertoy.com/view/fsK3zW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.283185307
#define sint(x) (sin((x) * TAU))

float stairs(float x, float max_) {
    return min(1.0, fract(x) / max_);
}

float stripes(float x, float thres) {
    return step(fract(x), thres);
}

void main(void)
{
    float t = fract(time / 5.);
    
    // normalizes coords so that center is (0,0) and diagonals are length 1
    vec2 uv = (gl_FragCoord.xy / length(resolution.xy)
    - (resolution.xy / length(resolution.xy) / 2.)) * 2.;
    float dist = 0.8 * log(uv.x * uv.x + uv.y * uv.y);
    float angle = atan(uv.y, uv.x) / TAU;
    
    float dist_ = stairs(t + 2. * sint(t) + dist, 0.6) - dist;
    float spiral = stripes(2. * t + 1.3 * dist_ + angle * 3., 0.4 + 0.3 * sint(t + 0.25));
    float circle = stripes(3. * t + 0.3 * (dist + sint(dist)), 0.4);
    
    vec3 col_base = vec3(79, 71, 137) / 255.;
    vec3 col_stripe = vec3(32, 19, 53) / 255.;
    vec3 col_bolt = vec3(252, 231, 98) / 255.;

    vec3 col = mix(
        mix(
            col_base,
            col_stripe,
            circle
        ),
        col_bolt,
        spiral
    );
    // Output to screen
    glFragColor = vec4(col,1.0);
}
