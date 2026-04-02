#version 420

// original https://www.shadertoy.com/view/ms2XWR

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define cell(pos) noise(floor((pos) / scale), colors)

const float scale = 32.0;
const float lineWidth = 3.0;

// Posterized noise
float noise(vec2 p, float levels) {
    return floor(fract(sin(dot(p, vec2(1.989, 2.233))) * 43758.54) * levels) / levels;
}

// From https://www.shadertoy.com/view/3tdSDj
float line(vec2 p, vec2 a, vec2 b) {
    vec2 ba = b - a;
    vec2 pa = p - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - h * ba);
}

// From https://www.shadertoy.com/view/lsS3Wc
vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void main(void) {
    
    //vec2 pos = mouse*resolution.xy.z > 0.0 ? gl_FragCoord.xy - mouse*resolution.xy.xy : gl_FragCoord.xy + float(frames);
    vec2 pos = gl_FragCoord.xy + float(frames);
    
    // Number of color subdivisions, ideally a whole number
    float colors = 3.0 + cos(time * 0.2);
    
    // Add nice rainbow colors
    float self = cell(pos);
    vec3 bg = hsv2rgb(vec3(self, 1.0, 1.0));
    float bgMix = 1.0;
    
    // 3 x 3 kernel, checks all 8 neighbors
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
        
            // Ignore self
            if (x == 0 && y == 0) continue;
            vec2 offset = vec2(x, y) * scale;
            
            // Check neighbor has matching color
            if (self == cell(pos + offset)) {
                // Draw a line from the center to the neighbor
                const vec2 center = vec2(scale * 0.5);
                float dist = line(mod(pos, scale), center, center + offset);
                bgMix = min(bgMix, dist / lineWidth);
            }
        }
    }
    
    // Combine background and lines, clip a little
    glFragColor = vec4(mix(0.8 + bg, bg * 0.25, bgMix), 1.0);
}
