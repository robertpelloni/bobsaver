#version 420

// original https://www.shadertoy.com/view/3t3yzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Hue to RGB conversion from Fabrice's shadertoyunofficial blog:
#define hue2rgb(h) 0.6 + 0.6 * cos(6.3 * h + vec3(0.0, 23.0, 21.0))

float mapVolume(in vec3 p) {
    float volume = dot(sin(0.5 * p), vec3(1.0));
    float layers = sin(3.0 * volume - 2.0 * time);
    return max(layers, volume);
}

float mapScene(in vec3 p) {
    p /= 0.75;
    vec3 cell = floor(p) * 0.75;
    vec3 local = fract(p) * 0.75;
    return (length(local - 0.325) + 0.3 * min(0.0, mapVolume(cell + 0.325))) * 0.6;
}

vec3 getNormal(in vec3 p) {
    return normalize(vec3(mapScene(p + vec3(0.001, 0.0, 0.0)) - mapScene(p - vec3(0.001, 0.0, 0.0)),
                          mapScene(p + vec3(0.0, 0.001, 0.0)) - mapScene(p - vec3(0.0, 0.001, 0.0)),
                          mapScene(p + vec3(0.0, 0.0, 0.001)) - mapScene(p - vec3(0.0, 0.0, 0.001))));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);

    float time = 0.25 * time;
    float c = cos(time), s = sin(time);

    vec3 ro = vec3(0.0, 0.0, 10.0);
    vec3 rd = normalize(vec3(uv, -1.0));

    float dt = 0.0;
    for (int iter=0; iter < 150; iter++) {
        vec3 p = ro + rd * dt;

        p.yz *= mat2(c, s, -s, c);
        p.xz *= mat2(c, s, -s, c);

        float d = mapScene(p);
        if (d < 0.001) {
            vec3 n = getNormal(p);
            vec3 l = vec3(-0.58, 0.58, 0.58);

            n.xz *= mat2(c, -s, s, c);
            n.yz *= mat2(c, -s, s, c);

            glFragColor.rgb += hue2rgb(0.2 * length(p) + time);
            glFragColor.rgb *= max(0.3, dot(n, l));
            break;
        }

        if (dt > 20.0) {
            break;
        }

        dt += d;
    }
}
