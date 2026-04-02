#version 420

// original https://www.shadertoy.com/view/wsGfD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float noise(in float x) {
    return fract(sin(x * 12.5673) * 573.123);
}

float continuousNoise(in float x) {
    const float r = 2.735;

    float x1 = floor(x * r) / r;
    float y1 = noise(x1);

    float x2 = ceil(x * r) / r;
    float y2 = noise(x2);

    return y1 + (0.5 + 0.5 * sin((2.0 * (x - x1) / (x2 - x1) - 1.0) * 1.57)) * (y2 - y1);
}

vec2 getSlopeVector(in float x) {
    return normalize(vec2(0.002, continuousNoise(x + 0.001) - continuousNoise(x - 0.001)));
}

// SDF of equilateral triangle from Inigo Quilez's 2D distance functions article (https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm):
float sdEquilateralTriangle(in vec2 p, in float s) {
    p /= s;

    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0 / k;
    if (p.x + k * p.y > 0.0) {
        p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    }

    p.x -= clamp(p.x, -2.0, 0.0);
    return -length(p) * sign(p.y) * s;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y * 4.0;
    float unit = 3.0 / resolution.y * 4.0;
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);

    glFragColor.b += smoothstep(unit, 0.0, abs(uv.y - continuousNoise(uv.x + time)) - 0.01) * float(uv.x < 0.0);

    vec2 slopeVector = getSlopeVector(time);
    vec2 gradientVector = slopeVector.yx * vec2(1.0, -1.0);

    uv.y -= continuousNoise(time);
    vec2 tUV = vec2(dot(uv, gradientVector), dot(uv, slopeVector));

    glFragColor.rb += smoothstep(unit, 0.0, sdEquilateralTriangle(tUV, 0.1));
}
