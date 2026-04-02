#version 420

/**
 * Wheels
 *         by AnnPin
 */

#define PI 3.1415926535
#define TWO_PI 2.0 * PI

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float getCircle(vec2 p, vec2 pos, float radius) {
    return 1.0 - smoothstep(radius - 0.005, radius + 0.005, length(pos - p));
}

vec2 getBlockId(vec2 p, float block) {
    int x, y;
    if (p.x > 0.0) {
        x = int(p.x / block) + 1;
    } else {
        x = int(p.x / block) - 1;
    }
    if (p.y > 0.0) {
        y = int(p.y / block) + 1;
    } else {
        y = int(p.y / block) - 1;
    }
    return vec2(x, y);
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0  - resolution.xy) / min(resolution.x, resolution.y);
    vec2 q = gl_FragCoord.xy / min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);
    
    float block = 0.45;    
    vec2 bIds = getBlockId(p, block);
        
    float rotTime = 2.0 * time;
    float duration = 2.0;
    if (int(mod(rotTime, duration)) == 0) {
        if (int(bIds.x) == 2) {
            p.y += block * rotTime;
        } else if (int(bIds.x) == -2) {
            p.y -= block * rotTime;
        }
    }
    if (int(mod(rotTime + (duration / 2.0), duration)) == 0) {
        if (int(bIds.y) == 2) {
            p.x -= block * (rotTime + (duration / 2.0));
        } else if (int(bIds.y) == -2) {
            p.x += block * (rotTime + (duration / 2.0));
        }
    }
    
    p = mod(p, block) - (block / 2.0);
    p *= (1.0 / block) * 2.25;
    
    
    for (int i=0; i < 5; i++) {
        float size = (sin((float(i) + 1.0) *time) + 1.0) / (25.0 * (float(i) + 1.0)) + 0.01;
        float x_pos = (1.0 / 5.0) * (float(i) + 1.0);
        int count = 5 * (i + 1);
        for (int j=0; j<255; j++) {
            if (j == count) { break; }
            float speed = time * 2.0 * (float(i) + 1.0);
            float angleBase = TWO_PI / float(count);
            float theta = angleBase * (float(j) + 1.0) + speed / 5.0;
            float c = cos(theta);
            float s = sin(theta);
            vec2 r = mat2(c, s, -s, c) * vec2(x_pos, 0);
            color = mix(color, vec3(1.0), getCircle(p, r, size));
        }
    }
    color *= vec3(q.x, q.y, (sin(time / 2.0) + 1.0) / 2.0);
    
    glFragColor = vec4(color, 1.0);
}
