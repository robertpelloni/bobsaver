#version 420

// original https://www.shadertoy.com/view/lsyfRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float border = 0.02;
float aa;

float hash(float p) {
    vec3 p3 = fract(p * vec3(5.3983, 5.4427, 6.9371));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash(vec2 p) {
    p = fract(p * vec2(5.3983, 5.4427));
    p += dot(p.yx, p.xy + vec2(21.5351, 14.3137));
    return fract(p.x * p.y);
}

vec2 hash2(vec2 p) {
    p = fract(p * vec2(5.3983, 5.4427));
    p += dot(p.yx, p.xy + vec2(21.5351, 14.3137));
    return fract(vec2(p.x * p.y * 95.4337, p.x * p.y * 97.597));
}

vec3 drawEye(vec3 background, vec2 pos, vec2 center, float radius, vec3 color) {
    float r = distance(pos, center);
    r = (radius - r) / aa + 0.5;
    return mix(background, color, clamp(r, 0.0, 1.0));
}

vec3 drawHead(vec3 background, vec2 pos, vec2 center, float radius, vec3 color) {
    float r = distance(pos, center);
    float a = clamp((radius - r) / aa + 0.5, 0.0, 1.0);
    float c = clamp((radius - r - border) / aa + 0.5, 0.0, 1.0);
    return mix(background, c * color, a);
}

vec3 drawMouth(vec3 background, vec2 pos, vec2 center1, float radius1, vec2 center2, float radius2, vec3 color) {
    float r1 = distance(pos, center1);
    float a1 = clamp((radius1 - r1) / aa + 0.5, 0.0, 1.0);
    float c1 = clamp((radius1 - r1 - border) / aa + 0.5, 0.0, 1.0);
    float r2 = distance(pos, center2);
    float a2 = clamp((radius2 - r2) / aa + 0.5, 0.0, 1.0);
    float c2 = clamp((radius2 - r2 - border) / aa + 0.5, 0.0, 1.0);
    return mix(background, c1 * c2 * color, a1 * a2);
}

vec3 drawPetal(vec3 background, vec2 pos, vec2 center, float radius, vec3 rotation, vec3 color1, vec3 color2) {
    pos -= center;
    float r = length(pos);
    float t = 1.9098593 * atan(pos.y, pos.x) + rotation.x * sin(rotation.y * time + 6.2831853 * rotation.z);
    t = mod(t, 2.0);
    vec3 color = mix(color1, color2, step(t, 1.0));
    t = 0.52359878 * (0.5 - abs(mod(t, 1.0) - 0.5));
    pos = r * vec2(cos(t), sin(t));
    
    r = distance(pos, radius * vec2(0.767327, 0.2056046));
    float a = clamp((0.2056046 * radius - r + 0.5 * border) / aa + 0.5, 0.0, 1.0);
    float c = clamp((0.2056046 * radius - r - 0.5 * border) / aa + 0.5, 0.0, 1.0);
    
    float stem = step(pos.x, 0.767327 * radius);
    a = mix(a, 1.0, stem);
    c = mix(c, clamp((pos.y - 0.5 * border) / aa + 0.5, 0.0, 1.0), stem);
    
    return mix(background, c * color, a);
}

#define range(min, max) mix(min, max, hash(id += 0.1))
#define hsv(hue, sat, val) (val) * (vec3(1.0 - (sat)) + (sat) * (0.5 + 0.5 * cos(6.2831853 * (vec3(hue) + vec3(0.0, 0.33, 0.67)))))

vec3 draw(vec3 color, vec2 pos, vec2 screen, vec2 block, vec2 offset, float level) {
    block += mod(offset - mod(block, 5.0), 5.0) - 2.0;
    
    float id = hash(block);
    vec2 center = block + vec2(0.1) + 0.8 * hash2(block) - 0.01 * level * screen;
    vec3 rotation = vec3(range(0.0, 2.0), range(0.0, 0.8), range(0.0, 1.0));
    float petalHue = range(0.0, 1.0);
    float petalSat1 = pow(hash(id += 0.1), 0.4);
    float petalSat2 = pow(hash(id += 0.1), 2.0) * petalSat1;
    vec3 petal1 = hsv(petalHue, petalSat1, 1.0);
    vec3 petal2 = hsv(petalHue, petalSat2, 1.0);
    vec3 mouth = hsv(range(0.0, 1.0), 0.8, 1.0);
    vec3 left = hsv(fract(2.0 * time + hash(id += 0.1)), 0.5, 0.8);
    vec3 right = hsv(fract(2.0 * time + hash(id += 0.1)), 0.5, 0.8);
    float radius = mix(0.4, 1.4, pow(hash(id += 0.1), 2.0));

    color = drawPetal(color, pos, center, radius, rotation, petal1, petal2);
    color = drawHead(color, pos, center, 0.4 * radius, vec3(1.0));
    color = drawEye(color, pos, center + radius * vec2(-0.14, 0.18), 0.05 * radius, left);
    color = drawEye(color, pos, center + radius * vec2(0.14, 0.18), 0.05 * radius, right);
    color = drawMouth(color, pos, center, 0.28 * radius, center + radius * vec2(0.0, -0.64), 0.72 * radius, mouth);
    
    return color;
}

void main(void) {
    vec2 screen = 3.0 * (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    float t = 0.1 * time;
    vec2 pos = screen + 3.0 * vec2(t + 0.4 * sin(2.0 * t), 2.0 * cos(t));
    aa = 6.0 / resolution.y;
    
    vec2 block = floor(pos);
    
    vec3 color = vec3(0.8, 0.7, 0.9);
    
    color = draw(color, pos, screen, block, vec2(0.0, 0.0), 24.0);
    color = draw(color, pos, screen, block, vec2(2.0, 1.0), 23.0);
    color = draw(color, pos, screen, block, vec2(4.0, 0.0), 22.0);
    color = draw(color, pos, screen, block, vec2(3.0, 2.0), 21.0);
    color = draw(color, pos, screen, block, vec2(4.0, 4.0), 20.0);
    color = draw(color, pos, screen, block, vec2(2.0, 3.0), 19.0);
    color = draw(color, pos, screen, block, vec2(0.0, 4.0), 18.0);
    color = draw(color, pos, screen, block, vec2(1.0, 2.0), 17.0);
    color = draw(color, pos, screen, block, vec2(2.0, 0.0), 16.0);
    color = draw(color, pos, screen, block, vec2(4.0, 1.0), 15.0);
    color = draw(color, pos, screen, block, vec2(3.0, 3.0), 14.0);
    color = draw(color, pos, screen, block, vec2(1.0, 4.0), 13.0);
    color = draw(color, pos, screen, block, vec2(0.0, 2.0), 12.0);
    color = draw(color, pos, screen, block, vec2(1.0, 0.0), 11.0);
    color = draw(color, pos, screen, block, vec2(3.0, 1.0), 10.0);
    color = draw(color, pos, screen, block, vec2(4.0, 3.0), 9.0);
    color = draw(color, pos, screen, block, vec2(2.0, 4.0), 8.0);
    color = draw(color, pos, screen, block, vec2(0.0, 3.0), 7.0);
    color = draw(color, pos, screen, block, vec2(1.0, 1.0), 6.0);
    color = draw(color, pos, screen, block, vec2(3.0, 0.0), 5.0);
    color = draw(color, pos, screen, block, vec2(4.0, 2.0), 4.0);
    color = draw(color, pos, screen, block, vec2(3.0, 4.0), 3.0);
    color = draw(color, pos, screen, block, vec2(1.0, 3.0), 2.0);
    color = draw(color, pos, screen, block, vec2(0.0, 1.0), 1.0);
    color = draw(color, pos, screen, block, vec2(2.0, 2.0), 0.0);
    
    glFragColor = vec4(color, 1.0);
}
