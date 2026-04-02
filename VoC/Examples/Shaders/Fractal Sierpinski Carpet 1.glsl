#version 420

// original https://www.shadertoy.com/view/Xl2SRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 p = gl_FragCoord.xy;
    p.x -= 0.5 * (resolution.x-resolution.y);
    p *= 3.0 / resolution.y;
    
    float t = 0.5 * time + 4.0;
    float ti = floor(t);
    vec2 ct = mod(vec2(ti, ti + 1.0), 9.0);
    
    vec2 c = vec2(p.x >= 0.0 && p.x < 3.0);
    for (int i = 0; i < 5; ++i) {
        vec2 m = floor(p);
        float j = m.y*3.0 + m.x;
           c *= 0.2 + 0.8 * vec2(j != ct[0], j != ct[1]);
        p = 3.0 * (p-m);
    }

    float x = smoothstep(0.0, 1.0, t - ti);
    glFragColor = vec4(vec3(0.1 + 0.9*mix(c[0], c[1], x)), 1.0);
}
