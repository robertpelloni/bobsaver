#version 420

// original https://www.shadertoy.com/view/7lsyzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Original by beesandbombs: https://twitter.com/beesandbombs/status/989288221514362881
// re-implemented by m1el

// SDF for rounded rect by Inigo Quilez
// https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdRoundedBox( in vec2 p, in vec2 b, in float r ) {
    vec2 q = abs(p)-b+r;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r;
}

// Credit to FabriceNeyret2 for the suggestions
float tRoundedBox(vec2 p, vec2 b) {
    float db = b.x - b.y, v;
    if (abs(p.x) - db > abs(p.y)) {
        p.x -= sign(p.x) * db;
        v = p.y / p.x * 0.5 + sign(p.x);
    } else {
        p.y += sign(p.y) * db;
        v = -p.x / p.y * 0.5 + sign(p.y) + 1.0;
    }
    return (v + 1.5) / 4.0;
}

vec4 overlay(vec4 over, vec4 under) { 
    return mix(under.w * under, over, over.w) / over.w;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy - resolution.xy*0.5;
    uv *= mat2(0.5, -0.5, 0.5, 0.5);
    vec4 col = vec4(1.0);
    float cell = 40.0;
    float line_width = 8.0;
    float stripe_width = 5.0 / 8.0;
    float offset = mod(ceil(uv.x / cell) + ceil(uv.y / cell), 2.0) - 0.5;
    float mz = 100.0;
    //col.z = offset;
    float speed = 1.0 / 10.0;
    for (float i = 0.0; i < 5.0; i += 1.0) {
        float w = (i + 0.5) * cell;
        vec2 wh = vec2(w, cell * 5.0 - w);
        float dist = sdRoundedBox(uv, wh, 8.0);
        float freq = (i + 1.0) * 2.0;
        float tangent = 1.0 - fract(tRoundedBox(uv, wh) + 0.375 + time * freq * speed);
        float width = (tangent - 0.15) * line_width;
        float alpha = smoothstep(0.0, 1.0, width - abs(dist));
        float stripe = smoothstep(1.0, 0.0, width * stripe_width - abs(dist));
        if (alpha <= 0.0) { continue; }
        float horizontal = sign(abs(uv.y) - abs(wh.y - cell * 0.5));
        float z = offset * horizontal;
        vec4 cc = vec4(vec3(stripe), alpha);
        if (z < mz) {
            col = overlay(cc, col);
            mz = z;
        } else {
            col = overlay(col, cc);
        }
    }

    // Output to screen
    glFragColor = vec4(col);
}
