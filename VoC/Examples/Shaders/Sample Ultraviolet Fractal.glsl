#version 420

// original https://www.shadertoy.com/view/3lGfzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    vec4 O = vec4(0.0);
    vec3 p, r = vec3(resolution.xy,1.0);
    vec3 d = normalize(vec3((gl_FragCoord.xy - 0.5 * r.xy) / r.y, 1.0));  
    for (float i=0.0, g=0.0, e, s; ++i < 100.0; e < 0.002 ? O += 5.0 * (cos(vec4(2.0, 4.0, 1.0, 0.0) - log(s * s) * 0.5) + 0.5) / dot(p, p) / i * 2.0 : O) {
        p = g * d;
        p -= vec3(0.0, -1.7, 2.0);
        s = time * 0.1;
        vec2 cs = sin(s + vec2(1.57, 0.0));
        p.xz *= mat2(cs.x, -cs.y, cs.yx);
        p = abs(p);
        p.xz = vec2(atan(p.z, p.x), length(p.xz));
        p.yz = vec2(atan(p.z, p.y), length(p.yz) - 3.0);
        s = 2.0;
        s *= e = 3.0 / min(dot(p, p), 1.5);
        p = abs(p) * e;
        for(int i=0; i < 8; i++) {
            p = vec3(2.0, 4.0, 2.0) - abs(p - vec3(4.25, 4.625, 2.0));
            s *= e = 7.25 / clamp(dot(p, p), 0.0, 5.2);
            p = abs(p) * e;
            p.y = abs(p.y) - 0.15;
        }

        g += e = min(length(p.xz) * 1.125 - 0.5, p.y) / s;
    }
    glFragColor=O;
}
