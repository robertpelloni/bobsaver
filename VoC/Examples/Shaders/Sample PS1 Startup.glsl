#version 420

// original https://www.shadertoy.com/view/tlKGzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 bary(vec2 a, vec2 b, vec2 c, vec2 p) {
    vec2 v0 = b - a, v1 = c - a, v2 = p - a;
    float inv_denom = 1.0 / (v0.x * v1.y - v1.x * v0.y);
    float v = (v2.x * v1.y - v1.x * v2.y) * inv_denom;
    float w = (v0.x * v2.y - v2.x * v0.y) * inv_denom;
    float u = 1.0 - v - w;
    return abs(vec3(u,v,w));
}

vec4 thing(vec2 uv) {
    vec2 a = vec2( 0.0, 0.5);
    vec2 b = vec2(-0.5, 0.0);
    vec2 c = vec2( 0.0, -0.5);
    
    vec3 bcc = bary(a, b, c, uv);
    
    if(bcc.x + bcc.y + bcc.z <= 1.001) {
        vec3 colA = vec3(0.7, 0.12, 0.05);
        vec3 colB = vec3(0.74, 0.57, 0.07);
        vec3 col = mix(colB, colA, bcc.y+0.1);
        return vec4(col, 1.0);
    } else {
        return vec4(0.0);
    }
}

vec4 mix_alpha(vec4 a, vec4 b) {
    return mix(a, b, b.a);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    
    uv *= 1.3;
    
    vec4 col;
    
    if (time < 1.5) {
        col = vec4(mix(0.0, 0.76, clamp(time-0.5, 0.0, 1.0)));
    } else {
        col = thing(uv);

        col = mix_alpha(col, thing(-uv));

        float t = clamp(time - 1.9, 0.0, 1.0);
        float scale = mix(1.0, 2.2, t);
        vec2 off = vec2(-0.07, -0.43) * t;

        col = mix_alpha(col, thing(-uv * scale + off));

        col = mix_alpha(col, thing( uv * scale + off));

        col = mix_alpha(vec4(0.76, 0.76, 0.76, 1.0), col);

    }
    
    glFragColor = vec4(col.rgb, 1.0);
}
