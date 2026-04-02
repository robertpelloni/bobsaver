#version 420

// original https://www.shadertoy.com/view/ltSGDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float duration = 5.0;
const float KenBurnsEffect = 1.0;

float hash1(float p) {
    vec3 p3 = fract(p * vec3(5.3983, 5.4427, 6.9371));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash1(vec2 p2, float p) {
    vec3 p3 = fract(vec3(5.3983 * p2.x, 5.4427 * p2.y, 6.9371 * p));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash2(float p) {
    vec3 p3 = fract(p * vec3(5.3983, 5.4427, 6.9371));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float noise1(vec2 p2, float p) {
    vec2 i = floor(p2);
    vec2 f = fract(p2);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return 1.0 - 2.0 * mix(mix(hash1(i + vec2(0.0, 0.0), p), 
                               hash1(i + vec2(1.0, 0.0), p), u.x),
                           mix(hash1(i + vec2(0.0, 1.0), p), 
                               hash1(i + vec2(1.0, 1.0), p), u.x), u.y);
}

const mat2 m = mat2(1.616, 1.212, -1.212, 1.616);

float fbm1(vec2 p2, float p) {
    float f = noise1(p2, p); p2 = m * p2;
    f += 0.5 * noise1(p2, p); p2 = m * p2;
    f += 0.25 * noise1(p2, p); p2 = m * p2;
    f += 0.125 * noise1(p2, p); p2 = m * p2;
    f += 0.0625 * noise1(p2, p); p2 = m * p2;
    f += 0.03125  * noise1(p2, p);
    return f / 1.96875 ;
}

#define range(min, max) mix(min, max, hash1(imageID + (hash += 0.1)))
#define hsv(hue, sat, val) (val) * (vec3(1.0 - (sat)) + (sat) * cos(6.2831853 * (vec3(hue) + vec3(0.0, 0.33, 0.67))))

void main(void) {
    float imageID = floor(time / duration);
    float t = mod(time / duration, 1.0);
    
    float hash = 0.0;
    int iter = int(range(5.0, 15.0));
    float scale = range(2.5, 5.0);
    float hueBase = range(0.0, 1.0);
    float huePitch = range(0.1, 0.4);
    float sat = range(0.2, 0.7);
    float val = range(0.4, 0.9);
    float backgroundSat = range(0.0, 0.2);
    float backgroundVal = range(0.4, 0.8);
    
    vec3 a = hsv(hueBase, sat, val);
    vec3 b = hsv(hueBase + huePitch, sat, val);
    vec3 c = hsv(hueBase - huePitch, sat, val);
    
    vec2 pos = gl_FragCoord.xy / resolution.y;
    pos += 0.2 * KenBurnsEffect * t * (hash2(imageID) - vec2(0.5));
    pos *= 1.0 + KenBurnsEffect * (t - 0.5) * range(-0.2, 0.2);
    
    pos *= scale;
    vec3 color = hsv(hueBase, backgroundSat, backgroundVal);
    for (int i = 0; i < iter; ++i) {
        float id = imageID + 0.05 * float(i);
        color = mix(color, a, smoothstep(0.02, 0.01, abs(fbm1(pos, id + 0.00))));
        color = mix(color, b, smoothstep(0.02, 0.01, abs(fbm1(pos, id + 0.01))));
        color = mix(color, c, smoothstep(0.02, 0.01, abs(fbm1(pos, id + 0.02))));
        color = mix(color, vec3(1.0), smoothstep(0.02, 0.01, abs(fbm1(pos, id + 0.03))));
        color = mix(color, vec3(0.0), smoothstep(0.02, 0.01, abs(fbm1(pos, id + 0.04))));
    }
   
    color *= smoothstep(0.0, 0.05, t) * smoothstep(1.0, 0.95, t);
    glFragColor = vec4(color, 1.0);
}
