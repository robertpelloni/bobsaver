#version 420

// original https://www.shadertoy.com/view/ftfGW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float bicubic4x4(in vec2 p, in mat4 v) {
    ivec2 id = ivec2(floor(p));                                         // Cell index
    vec2 uv = smoothstep(0.0, 1.0, fract(p));                           // Smoothed local cell coordinates
    return mix(mix(v[id.x    ][id.y    ], v[id.x + 1][id.y    ], uv.x), // Lower horizontal pass
               mix(v[id.x    ][id.y + 1], v[id.x + 1][id.y + 1], uv.x), // Upper horizontal pass
               uv.y);                                                   // Vertical pass
}

float Hash11(in float x) {
    x = fract(x * 0.1031);
    x *= x + 33.33;
    x *= x + x;
    return fract(x);
}

float anim(in float seed) {
    float a = Hash11(seed * 393.84 + 673.48);
    float b = Hash11(seed * 348.46 + 183.37);
    float c = Hash11(seed * 275.35 + 741.69);
    return 0.5 + 0.5 * sin(time * a + b) * c;
}

float mapScene(in vec3 p) {
    float height = bicubic4x4(p.xz + 1.5, mat4(anim( 1.0), anim( 2.0), anim( 3.0), anim( 4.0),
                                               anim( 5.0), anim( 6.0), anim( 7.0), anim( 8.0),
                                               anim( 9.0), anim(10.0), anim(11.0), anim(12.0),
                                               anim(13.0), anim(14.0), anim(15.0), anim(16.0)));

    return max(p.y - height, max(max(abs(p.x), abs(p.z)) - 1.5, -p.y));
}

vec3 getNormal(in vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(mapScene(p + e.xyy) - mapScene(p - e.xyy),
                          mapScene(p + e.yxy) - mapScene(p - e.yxy),
                          mapScene(p + e.yyx) - mapScene(p - e.yyx)));
}

void main(void) {
    // Boilerplate
    vec2 center = 0.5 * resolution.xy;
    vec2 mouse = (mouse*resolution.xy.xy - center) / resolution.y * 3.14;
    vec2 uv = (gl_FragCoord.xy - center) / resolution.y;
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 ro = vec3(0.0, 0.0, 4.0);
    vec3 rd = normalize(vec3(uv, -1.0));

    // Rotate with mouse
    float cy = cos(mouse.x), sy = sin(mouse.x);
    float cp = cos(mouse.y), sp = sin(mouse.y);

    ro.yz *= mat2(cp, -sp, sp, cp);
    ro.xz *= mat2(cy, -sy, sy, cy);
    rd.yz *= mat2(cp, -sp, sp, cp);
    rd.xz *= mat2(cy, -sy, sy, cy);

    float t = 0.0;
    for (int i=0; i < 100; i++) {
        vec3 p = ro + rd * t;
        float d = mapScene(p) * 0.75;
        if (d < 0.001) {
            vec3 n = getNormal(p);

            glFragColor.rgb += smoothstep(0.0, 0.05, abs(fract(p.x + 2.0) - 0.5));
            glFragColor.rgb += smoothstep(0.0, 0.05, abs(fract(p.z + 2.0) - 0.5));
            glFragColor.rgb *= 0.5 * max(0.0, dot(n, -rd));

            break;
        }

        if (t > 100.0) {
            break;
        }

        t += d;
    }
}
