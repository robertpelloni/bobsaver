#version 420

// original https://www.shadertoy.com/view/4dyfW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rotate(a) mat2(cos(a), sin(a), -sin(a), cos(a))
#define spiral(u, a, r, t, d) abs(sin(t + r * length(u) + a * (d * atan(u.y, u.x))))
#define sinp(a) .5 + sin(a) * .5

void main(void) {
    
    vec2 st = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
     st = rotate(-time / 10.) * st;
    
    vec3 col;
    float t = time;
    vec2 o = vec2(cos(time / 10.), sin(time / 2.));
    for (int i = 0; i < 3; i++) {
        t += 0.3 * spiral(vec2(o + st), 16., 16. + 64. * o.x - o.y, -time / 100., 1.)
            * spiral(vec2(o - st), 16., 16. + 64. * o.x - o.y, time / 100., -1.);
        col[i] = sin(5. * t - length(st) * 10. * sinp(t));
    }
    
    glFragColor = vec4(col, 1.0);
    
}
