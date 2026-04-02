#version 420

// original https://www.shadertoy.com/view/fdBGWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// SDFs
float sdBox(in vec3 p, in vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(0.0, max(q.x, max(q.y, q.z)));
}

// Distance operators
// Use continuous! It will look a lot nicer.
// Be sure to choose a span that that is a close multiple of the
// repeat size otherwise the edges will get really stretched due
// to the space distortions by the smooth mod.
float smoothModLim(in float x, in float span, in float size, in float smoothness, in bool continuous) {
    float m = 1.0 - smoothness;
    float ss = span / size;

    float sModX = asin(sin(x / size) * m) * size;

    float slope = 1.0;
    float offs = asin(sin(ss) * m) * size;

    if (continuous) {
        float s = sin(ss);
        slope = m * cos(ss) / sqrt(1.0 - m * m * s * s);
    }

    // The mixes are a (shorter) alternative for ifs and elses
    float sModLimX = mix(sModX, (x - span) * slope + offs, step(span, x));
    sModLimX = mix(sModLimX, (x + span) * slope - offs, step(span, -x));

    return sModLimX;
}

// Overloading for vec2
vec2 smoothModLim(in vec2 x, in vec2 span, in vec2 size, in float smoothness, in bool continuous) {
    x.x = smoothModLim(x.x, span.x, size.x, smoothness, continuous);
    x.y = smoothModLim(x.y, span.y, size.y, smoothness, continuous);
    return x;
}

// Overloading for vec3
vec3 smoothModLim(in vec3 x, in vec3 span, in vec3 size, in float smoothness, in bool continuous) {
    x.xy = smoothModLim(x.xy, span.xy, size.xy, smoothness, continuous);
    x.z = smoothModLim(x.z, span.z, size.z, smoothness, continuous);
    return x;
}

// Scene
float mapScene(in vec3 p) {
    p = smoothModLim(p, vec3(6.0), vec3(1.5), 0.3, true);

    float c = cos(time), s = sin(time);
    p.xz *= mat2(c, -s, s, c);
    p.yz *= mat2(c, -s, s, c);

    return sdBox(p, vec3(1.0, 0.25, 1.5)) - 0.2;
}

// Gradient
vec3 getNormal(in vec3 p) {
    vec3 e = vec3(0.001, 0.0, 0.0);
    return normalize(vec3(mapScene(p + e.xyy) - mapScene(p - e.xyy),
                          mapScene(p + e.yxy) - mapScene(p - e.yxy),
                          mapScene(p + e.yyx) - mapScene(p - e.yyx)));
}

void main(void) {
    vec2 center = 0.5 * resolution.xy;

    vec2 mouse = true ? (mouse*resolution.xy.xy - center) / resolution.y * 3.14 : vec2(0.0);
    vec2 uv = (gl_FragCoord.xy - center) / resolution.y;

    vec3 ro = vec3(0.0, 0.0, 25.0);
    vec3 rd = normalize(vec3(uv, -1.0));

    // Rotate with mouse
    float cy = cos(mouse.x), sy = sin(mouse.x);
    float cp = cos(mouse.y), sp = sin(mouse.y);

    ro.yz *= mat2(cp, -sp, sp, cp);
    ro.xz *= mat2(cy, -sy, sy, cy);
    rd.yz *= mat2(cp, -sp, sp, cp);
    rd.xz *= mat2(cy, -sy, sy, cy);

    // Sky
    glFragColor = vec4(mix(vec3(0.25, 0.25, 1.0), vec3(1.0), 0.5 + 0.5 * rd.y), 1.0);

    // Raymarch
    float t = 0.0, d;
    for (int i=0; i < 150; i++) {
        vec3 p = ro + rd * t;
        d = mapScene(p);
        if (d < 0.001) {
            vec3 n = getNormal(p);
            vec3 l = vec3(-0.58, 0.58, 0.58);

            vec3 color = abs(n) * 1.25;
            glFragColor.rgb = color * max(0.2, dot(n, l));

            break;
        }

        if (t > 50.0) {
            break;
        }

        t += d;
    }
    
}
