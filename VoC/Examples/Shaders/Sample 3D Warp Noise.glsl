#version 420

// original https://www.shadertoy.com/view/llB3Rz

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
    vec3 pos = p;
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
    vec3 col = vec3(0.0);
    
    // Domain warping:
    // http://www.iquilezles.org/www/articles/warp/warp.htm
    if (p.x < -0.005) {
        pos *= 8.0;
        float q = fBm(pos + vec3(8.5, 2.7, 5.3));
        float r = fBm(pos + vec3(4.6, 6.9, 2.1));
        float w = fBm(pos + 4.0 * q + 8.0 * r);
        col = vec3(0.5 * w);
    } else {
        pos *= 2.5;
        vec3 q, r;
        q.x = fBm(pos);
        q.y = fBm(pos + vec3(5.2,1.3,8.4));
        q.z = fBm(pos + vec3(2.2,5.4,7.9));
        r.x = fBm(pos + 2.0 * q + vec3(1.7,9.2,5.2));
        r.y = fBm(pos + 2.0 * q + vec3(8.3,2.8,4.8));
        r.z = fBm(pos + 2.0 * q + vec3(5.7,4.3,2.4));
        float w = fBm(pos + 4.0 * r);
        col = vec3(0.5 * w);
    }

    // the black line
    if (p.x > -0.005 && p.x < 0.005 ) {
        col = vec3(0.0);
    }

    glFragColor = vec4(col, 1.0);
}
