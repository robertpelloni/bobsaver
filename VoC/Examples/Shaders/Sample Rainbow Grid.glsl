#version 420

// original https://www.shadertoy.com/view/wlSGDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float twoPi = 6.283;

vec3 hash3(vec2 p) {
    vec3 q = vec3(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)), dot(p, vec2(419.2, 371.9)));
    return fract(sin(q) * 43758.5453);
}

// extremely questionable implementation of iq’s Voronoise
float voronoise(vec2 x) {
    vec2 cell = floor(x);
    vec2 cellCoordinate = fract(x);
    
    float accum = 0.;
    float weight = 0.;
    for(int x = -2; x <= 2; x++) {
        for(int y = -2; y <= 2; y++) {
            vec2 cellOffset = vec2(y, x);
            vec3 noiseValue = hash3(cell + cellOffset); // for Perlin noise, ditch the first two components
            float cellDistance = length(cellOffset - cellCoordinate + noiseValue.xy);
            float smoothedDistance = (1.0 - smoothstep(0., 1.414 /* sqrt(2) */, cellDistance));
            accum += noiseValue.z * smoothedDistance;
            weight += smoothedDistance;
        }
    }
    return accum / weight;
}

// palette function also from an iq article
vec3 palette(float v) {
    return vec3(0.5) + 0.5 * vec3(cos(twoPi * (v + vec3(0.0, 0.333, 0.667))));
}

float stripe(float v, float w) {
    float halfW = w * 0.5;
    float normV = fract(v);
    float alias = fwidth(v);
    return min(smoothstep(0.5 - halfW - alias, 0.5 - halfW, normV), smoothstep(0.5 + halfW + alias, 0.5 + halfW, normV));
}

vec2 direction(float a) {
    return vec2(cos(a), sin(a));
}

vec2 rotate(vec2 p, float a) {
    float c = cos(a);
    float s = sin(a);

    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.x;
    
    // color

    vec2 noiseCoordinate1 = uv * 8. + direction(fract(time * 0.043) * twoPi) * sin(fract(time * 0.07) * twoPi);
    float noiseValue1 = voronoise(noiseCoordinate1);
    vec2 noiseCoordinate2 = uv * 9. + direction(fract(time * -0.01) * twoPi) * sin(fract(time * 0.023) * twoPi) * 2.;
    float noiseValue2 = voronoise(noiseCoordinate2);
    vec2 noiseCoordinate3 = uv * 11. + direction(fract(time * 0.0074) * twoPi) * sin(fract(time * 0.019) * twoPi) * 3.;
    float noiseValue3 = voronoise(noiseCoordinate3);

    float noiseValue = noiseValue1 * noiseValue2 * noiseValue3 * 3.; // is this normalization factor right? probably not
    vec3 color = palette(3. * noiseValue);

    uv = rotate(uv, cos(time * 0.001) * 0.04 * twoPi);
    // distort
    uv += 0.014 * (sin(uv * 8. + time * 0.4) + sin(uv * 11. + time * 0.31) * vec2(1., -1.));

    // grid

    vec2 diagonalDirection = vec2(sqrt(3.0) * 0.5, 0.5);
    const float lineScale = 10.;
    const float lineWidth = 0.02;
    
    float v = max(max(stripe(dot(uv, diagonalDirection) * lineScale, lineWidth), stripe(dot(uv, vec2(-diagonalDirection.x, diagonalDirection.y)) * lineScale, lineWidth)), stripe((uv.y + 0.15) * lineScale, lineWidth));
    
    glFragColor = vec4(v * color,1.0);
}
