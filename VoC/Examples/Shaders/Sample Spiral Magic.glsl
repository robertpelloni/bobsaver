#version 420

// original https://www.shadertoy.com/view/tsBSWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle (vec2 uv, vec2 a, vec2 b) {
    vec2 auv = normalize(uv - a);
    vec2 buv = normalize(uv - b);
    vec2 sub = (auv - buv);
    return pow (max (dot (auv, sub), dot (buv, sub)), 1.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = -1.0 + 2.0 * uv;
    uv.x *= resolution.x / resolution.y;
       uv *= 2.0;
    const float pi = 3.14159265359;
    vec2 point = vec2(0.0);
    float theta = pi * time * 0.15;
    float radius = 0.1;
    float color = 0.0;
    
    for(int i = 1; i < 30; ++i) {
        float sx = sin(pi * theta + time) * radius;
        float cy = cos(pi * theta + time * 0.2) * radius;
           theta += log(pi) * pi / 2.0;
        vec2 next = vec2(sx, cy);
        color = max(color, circle(uv, point, vec2(sx,cy)));
        point = next;
        radius += 0.1;
    }
    glFragColor = vec4(color / radius);
}
