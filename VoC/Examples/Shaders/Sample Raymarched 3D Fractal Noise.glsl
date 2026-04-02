#version 420

// original https://www.shadertoy.com/view/WdyfDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Hue to RGB function from Fabrice's shadertoyunofficial blog:
#define hue2rgb(hue) 0.6 + 0.6 * cos(6.3 * hue + vec3(0.0, 23.0, 21.0))

#define SIN_15 0.2588190451
#define COS_15 0.96592582628

// Hash from "Hash without Sine" by Dave_Hoskins (https://www.shadertoy.com/view/4djSRW):
float Noise3D(in vec3 p3) {
    p3  = fract(p3 * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float SmoothNoise3D(in vec3 p) {
    vec3 cell = floor(p);
    vec3 local = fract(p);
    local *= local * (3.0 - 2.0 * local);

    float ldb = Noise3D(cell);                       // Left, Down, Back
    float rdb = Noise3D(cell + vec3(1.0, 0.0, 0.0)); // Right, Down, Back
    float ldf = Noise3D(cell + vec3(0.0, 0.0, 1.0)); // Left, Down, Front
    float rdf = Noise3D(cell + vec3(1.0, 0.0, 1.0)); // Right, Down, Front
    float lub = Noise3D(cell + vec3(0.0, 1.0, 0.0)); // Left, Up, Back
    float rub = Noise3D(cell + vec3(1.0, 1.0, 0.0)); // Right, Up, Back
    float luf = Noise3D(cell + vec3(0.0, 1.0, 1.0)); // Left, Up, Front
    float ruf = Noise3D(cell + vec3(1.0, 1.0, 1.0)); // Right, Up, Front

    return mix(mix(mix(ldb, rdb, local.x),
                   mix(ldf, rdf, local.x),
                   local.z),

               mix(mix(lub, rub, local.x),
                   mix(luf, ruf, local.x),
                   local.z),

               local.y);
}

float FractalNoise3D(in vec3 p, in float scale, in float octaves) {
    float value = 0.0;
    float nscale = 1.0;
    float tscale = 0.0;

    for (float octave=0.0; octave < octaves; octave++) {
        value += SmoothNoise3D(p * pow(2.0, octave) * scale) * nscale;
        tscale += nscale;
        nscale *= 0.5;
    }

    return value / tscale;
}

float mapScene(in vec3 p) {
    vec3 q = abs(p) -1.5;
    float bbox = max(q.x, max(q.y, q.z));
    return max(FractalNoise3D(p, 2.0, 4.0) - 0.4, bbox);
}

vec3 getNormal(in vec3 p) {
    return normalize(vec3(mapScene(p + vec3(0.001, 0.0, 0.0)) - mapScene(p - vec3(0.001, 0.0, 0.0)),
                          mapScene(p + vec3(0.0, 0.001, 0.0)) - mapScene(p - vec3(0.0, 0.001, 0.0)),
                          mapScene(p + vec3(0.0, 0.0, 0.001)) - mapScene(p - vec3(0.0, 0.0, 0.001))));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 ro = vec3(0.0, 0.0, 5.0), rd = normalize(vec3(uv, -1.0)), p;
    float dt = 0.0, d;
    bool hit = false;

    for (int iter=0; iter < 100; iter++) {
        p = ro + rd * dt;

        p.y -= 0.3;
        p.yz *= mat2(COS_15, SIN_15, -SIN_15, COS_15);
        float c = cos(time), s = sin(time);
        p.xz *= mat2(c, s, -s, c);

        vec3 q = abs(p) - 1.5;
        d = max(q.x, max(q.y, q.z));
        if (d < 0.001) {
            d = mapScene(p);
            if (d < 0.001) {
                hit = true;
                break;
            }
        }

        if (dt > 10.0) {
            break;
        }

        dt += d;
    }

    if (hit) {
        vec3 n = getNormal(p);
        glFragColor.rgb += 0.5 + 0.5 * n;
    }
}
