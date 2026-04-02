#version 420

/*~ iridule ~*/

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define T time

mat2 rotate(float a) {
    float c = cos(a),
        s = sin(a);
    return mat2(c, -s, s, c);
}

vec3 render(vec2 uv) {
    float m = 6.28 / 6.;
    uv = abs(uv) - sin(T * .005);
    uv *= rotate(T);
    uv = vec2(mod(atan(uv.x, uv.y) + m * .5, m) - m * .5, length(uv));
    //uv = vec2(uv.y * cos(uv.x), uv.y * sin(uv.x));
    uv = abs(uv) -  .5;
    uv *= rotate(T);
    uv *= (2. + sin(T));
    uv = fract(uv) - .5;
    uv = abs(uv) - (.2 * sin(T));
    uv *= rotate(-T);
    vec3 color = vec3(0.);
    vec2 p = vec2(atan(uv.x, uv.y), length(uv));
    m = 6.28 / 5.;
    p.x = mod(p.x + m * .5, m) - m * .5;
    float d = p.y * cos(p.x);
    color += d;
    color = mix(color, vec3(1., 0., 0.), smoothstep(.5, .0, d));
    color = mix(color, vec3(1., .5, 0.), smoothstep(.2, .9, d));
    color = mix(color, vec3(1., .0, .2), smoothstep(.2, .0, d));
    return color;
}

void main() {
    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    glFragColor = vec4(render(uv), 1.);
}
