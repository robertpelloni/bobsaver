#version 420

// original https://www.shadertoy.com/view/wl3BRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Cube(in vec3 p) {
    vec3 q = abs(p) - 0.75;
    return max(q.x, max(q.y, q.z));
}

float mapScene(in vec3 p) {
    float c = cos(time), s = sin(time);
    p.xz *= mat2(c, -s, s, c);
    p.yz *= mat2(c, -s, s, c);

    return (Cube(p + vec3(-0.5,  0.0,  0.0)) +
            Cube(p + vec3( 0.5,  0.0,  0.0)) +
            Cube(p + vec3( 0.0, -0.5,  0.0)) +
            Cube(p + vec3( 0.0,  0.5,  0.0)) +
            Cube(p + vec3( 0.0,  0.0, -0.5)) +
            Cube(p + vec3( 0.0,  0.0,  0.5))) / 6.0 + 0.08;
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
    for (int i=0; i < 100; i++) {
        vec3 p = ro + rd * t;
        float d = mapScene(p / 2.0) * 2.0;
        if (d < 0.001) {
            vec3 n = getNormal(p / 2.0);
            vec3 l = vec3(-0.58, 0.58, 0.58);
            glFragColor.rgb += n * max(0.2, dot(n, l));
            break;
        }

        if (t > 100.0) {
            break;
        }

        t += d;
    }
}
