#version 420

// original https://www.shadertoy.com/view/wtVyRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float TAU = 6.28318530718;

// Space decompression gets sketchy at the poles (where space approaches zero compression) but it is pretty decent
vec3 pModSpherical(inout vec3 p, in float uRep, in float vRep) {
    vec2 spherical = vec2(atan(p.z, p.x), atan(p.y, length(p.xz)));
    float decomp = cos(spherical.y);

    vec2 repInterv = TAU / vec2(uRep, vRep);
    spherical = mod(spherical, repInterv) - 0.5 * repInterv;
    float cu = cos(spherical.x), su = sin(spherical.x);
    float cv = cos(spherical.y), sv = sin(spherical.y);
    p = vec3(cu * cv, sv, su * cv * decomp) * length(p);

    return p;
}

float mapScene(in vec3 p) {
    float c = cos(time), s = sin(time);
    p.xz *= mat2(c, -s, s, c);
    p.yz *= mat2(c, -s, s, c);

    float hackySpikeClipper = abs(p.y) - 2.1; // x_x

    pModSpherical(p, 27.0 + 23.0 * sin(time), 27.0 + 23.0 * cos(time)); // Set uRep and vRep to 70.0 to get a meshy looking sphere!
    vec3 q = abs(p - vec3(2.0, 0.0, 0.0)) - 0.1;
    float boxes = max(q.x, max(q.y, q.z));

    return max(boxes, hackySpikeClipper);
}

vec3 getNormal(in vec3 p) {
    vec3 e = vec3(0.001, 0.0, 0.0);
    return normalize(vec3(mapScene(p + e.xyy) - mapScene(p - e.xyy),
                          mapScene(p + e.yxy) - mapScene(p - e.yxy),
                          mapScene(p + e.yyx) - mapScene(p - e.yyx)));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 ro = vec3(0.0, 0.0, 5.0);
    vec3 rd = normalize(vec3(uv, -1.0));

    float t = 0.0;
    for (float iters=0.0; iters < 150.0; iters++) {
        vec3 p = ro + rd * t;
        float d = mapScene(p);
        if (d < 0.001) {
            vec3 n = getNormal(p);
            vec3 l = vec3(-0.58, 0.58, 0.58);
            glFragColor.rgb += max(0.1, dot(n, l));
            break;
        }

        if (t > 100.0) {
            break;
        }

        t += d;
    }
}
