#version 420

// original https://www.shadertoy.com/view/MlSGRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(in vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 39.1215, 78.233))) * 43758.5453);
}

float noise(in vec3 p) {
    // procedural noise originally by Dave Hoskins
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(mix(hash(i + vec3(0.0, 0.0, 0.0)), hash(i + vec3(1.0, 0.0, 0.0)), f.x),
            mix(hash(i + vec3(0.0, 1.0, 0.0)), hash(i + vec3(1.0, 1.0, 0.0)), f.x),
            f.y),
        mix(mix(hash(i + vec3(0.0, 0.0, 1.0)), hash(i + vec3(1.0, 0.0, 1.0)), f.x),
            mix(hash(i + vec3(0.0, 1.0, 1.0)), hash(i + vec3(1.0, 1.0, 1.0)), f.x),
            f.y),
        f.z);
}

float fBm(in vec3 p) {
    float sum = 0.0;
    float amp = 1.0;
    for(int i = 0; i < 4; i++) {
        sum += amp * noise(p);
        amp *= 0.5;
        p *= 2.0;
    }
    return sum;
}

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
    vec3 rd = normalize(vec3(p.xy, 1.0));
    vec3 pos = vec3(0.0, 0.0, 1.0) * time * 0.05 + rd;

    float scale = 16.0; // noise scale
    float freq = 0.5;   // marble pattern frequency
    float amp = 16.0;   // marble amplitude
    float xPeriod = 2.0;
    float yPeriod = 1.0;
    float zPeriod = 0.5;

    if (p.x > 0.005) { // right part of the screen
        amp *= 0.85;
        freq *= 0.5;
        xPeriod *= 4.0;
        yPeriod *= 4.0;
        zPeriod *= 4.0;
    }

    pos *= scale;
    vec3 col = vec3(abs(sin(freq *(pos.x * xPeriod 
                                 + pos.y * yPeriod
                                 + pos.z * zPeriod
                                 + amp * fBm(pos)
                           ))));

    // the black line
    if (p.x > -0.005 && p.x < 0.005 ) {
        col = vec3(0.0);
    }

    glFragColor = vec4(col, 1.0);
}
