#version 420

// original https://www.shadertoy.com/view/Xl3yRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float K = 7.0;
const float L = 1.4;
const float M = 1.5;

float egg(vec2 pos) {
    vec2 p = pos * vec2(pow(pos.y/(L*K)+1.0,M), 1.0/L);
    return length(2.0 * p) - 1.0;
}
float transformedEgg(vec2 pos, vec3 t) {
    return egg(pos / t.z - t.xy) * t.z;
}
vec2 eggOffset(float t) {
    float s = sin(t);
    float c = cos(t);
    return vec2(c * pow(K / (s + K), M), s * L);
}

float fill(float x, float f) {
    return clamp(x/f, 0.0, 1.0);
}
float stroke(float x, float f, float p) {
    return fill(x + f * p, p) - fill(x - f * p, p);
}

// TODO: Egg distance function without axis bias
// TODO: Precision offsets to take into account line width
// TODO: Create the number of eggs in a loop.

void main(void)
{
    vec2 uv = 2.0 * gl_FragCoord.xy/resolution.xy - 1.0;
    vec2 sc = max(vec2(resolution.x / resolution.y,
                       resolution.y / resolution.x),1.0);
    uv *= sc;
    vec2 df = 2.0 * sc / resolution.xy;
    float pw = length(df);
    
    float t = time * 4.0;
    
    vec3 a = vec3(0.0, 0.0, 1.0);
    vec3 d = vec3(a.xy + eggOffset(t) * (0.240 * a.z), 0.65);
    vec3 g = vec3(0.0, 0.0, 0.30);

    vec3 b = mix(a, d, 0.33333);
    vec3 c = mix(a, d, 0.66666);
    vec3 e = mix(d, g, 0.33333);
    vec3 f = mix(d, g, 0.66666);;

    
    float intensity = 0.0;
    
    intensity = max(intensity, stroke(transformedEgg(uv, a), 2.0, pw));
    intensity = max(intensity, stroke(transformedEgg(uv, b), 2.0, pw));
    intensity = max(intensity, stroke(transformedEgg(uv, c), 2.0, pw));
    intensity = max(intensity, stroke(transformedEgg(uv, d), 2.0, pw));
    intensity = max(intensity, stroke(transformedEgg(uv, e), 2.0, pw));
    intensity = max(intensity, stroke(transformedEgg(uv, f), 2.0, pw));
    intensity = max(intensity, stroke(transformedEgg(uv, g), 2.0, pw));

    // Output to screen
    glFragColor = vec4(vec3(1) * (1.0 - intensity),1.0);
}
