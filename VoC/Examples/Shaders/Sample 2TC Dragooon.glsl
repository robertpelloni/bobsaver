#version 420

// original https://www.shadertoy.com/view/XtX3D7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 2TC 15
// 280 chars or less (as counted by Shadertoy)

void main () {
    vec3 r = vec3 (gl_FragCoord.xy / resolution.y - .9, 2), p = vec3 (0, 14, 0), q;
    float d, c = 0., l = c;
    for (int i = 0; i < 99; ++i) {
        q = p + sin (p.z * .2 + time);
        d = (length (q.xy) - 4. + sin (abs (q.x * q.y) + p.z * 4.) * sin (p.z)) * .1;
        if (d < .1 || l > 99.) break;
        l += d;
        p += r * d;
        c += .01;
    }
    glFragColor = c * vec4 (2, 1, 0, 1);
}
