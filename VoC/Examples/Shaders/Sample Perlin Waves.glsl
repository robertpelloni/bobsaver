#version 420

// original https://www.shadertoy.com/view/DlVcRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

uniform vec2 u_resolution;
uniform float u_time;

const float temperature = 5.0;
const float noiseScale = 0.2;
const float effectWidth = 1.0;
const float lineThickness = 0.008;
const float speed = 0.4;

vec2 fade(vec2 t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

vec4 permute(vec4 x) {
    return mod(((x * 34.0) + 1.0) * x, 289.0);
}

float cnoise(vec2 P) {
    vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
    vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
    Pi = mod(Pi, 289.0); // To avoid truncation effects in permutation

    vec4 ix = Pi.xzxz;
    vec4 iy = Pi.yyww;
    vec4 fx = Pf.xzxz;
    vec4 fy = Pf.yyww;
    vec4 i = permute(permute(ix) + iy);
    vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
    vec4 gy = abs(gx) - 0.5;
    vec4 tx = floor(gx + 0.5);
    gx = gx - tx;
    vec2 g00 = vec2(gx.x, gy.x);
    vec2 g10 = vec2(gx.y, gy.y);
    vec2 g01 = vec2(gx.z, gy.z);
    vec2 g11 = vec2(gx.w, gy.w);
    vec4 norm = 1.79284291400159 - 0.85373472095314 *
        vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
    g00 *= norm.x;
    g01 *= norm.y;
    g10 *= norm.z;
    g11 *= norm.w;
    float n00 = dot(g00, vec2(fx.x, fy.x));
    float n10 = dot(g10, vec2(fx.y, fy.y));
    float n01 = dot(g01, vec2(fx.z, fy.z));
    float n11 = dot(g11, vec2(fx.w, fy.w));
    vec2 fade_xy = fade(Pf.xy);
    vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
    float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
    return 2.3 * n_xy;
}

float perline(vec2 p, float noiseY, float lineThickness, float noiseScale) {
    float x = p.x / 2.0;
    float s = cnoise(vec2(x, noiseY) * temperature) * noiseScale;
    float distanceToLine = abs(p.y - s);
    return 0.009 / distanceToLine;
}

vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);
    return a + b * cos(6.28318 * (c * t + d));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    uv *= 1.0;

    float sampleY = 0.0;
    sampleY += time * speed;

    vec3 finalColor = vec3(0.0);
    float deltaY = 0.003;

    for(float i = -10.0; i <= 10.0; i += 1.0) {
        vec2 p = uv + vec2(0.06 * i, 0.05 * i);

        sampleY += i * deltaY;

        if(p.x < -effectWidth || p.x > effectWidth) {
            continue;
        }

        float line = perline(p, sampleY, lineThickness, noiseScale);
        float opacity = exp(-abs(i * 0.2));
        vec3 col = palette(i * .04 + 0.3) * 2.0 * line * opacity;

        finalColor = max(finalColor, col);
    }

    glFragColor = vec4(finalColor, 1.0);
}
