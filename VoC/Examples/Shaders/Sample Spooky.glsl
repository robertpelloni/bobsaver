#version 420

// original https://www.shadertoy.com/view/wdyGRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define debug false
#define eps 1.5 / resolution.y
#define pi4 .785
#define is2 .0707

#define ratio resolution.x/resolution.y

float seed = 195845.184613;

float rand(float max)
{
    seed = fract(100000.0*sin(seed));
    return seed * max;
}

mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

vec2 place(vec2 uv, vec2 pos, float size, float a)
{
     return (uv-pos)*size * rot(a);
}

float norm(float i) {
    return min(max(i, 0.), 1.);
}

float circle(vec2 uv, vec2 p, float r) {
    float d = length(uv - p);
    return smoothstep(r, r - eps, d);
}

float rect(vec2 uv, vec2 p, vec2 d, float a) {
    uv *= rot(a);
    p *= rot(a);
    return smoothstep(0., eps, uv.x - p.x) *
        smoothstep(0., -eps, uv.x - p.x - d.x) *
        smoothstep(0., eps, uv.y - p.y) *
        smoothstep(0., -eps, uv.y - p.y - d.y);
}

vec4 ghost(vec2 uv, float time) {
    float a = .4 * cos(time * 1.1 + rand(10.));
    float speed = 5. * cos(time + rand(10.));
    float radius = .3 * cos(time * .8 + rand(10.));
    float size = 1. + .1 * cos(time * 1.2 + rand(10.));
    float eye = cos(time * .75 + rand(10.));
    vec3 col = 0.5 + 0.5 * cos(time + vec3(0, 2, 4));
    if (debug)
    {
        radius = 0.;
        a = 0.;
        size = 1.;
        eye = 1.;
    }
    vec2 p = vec2(
        cos(time * .9 + speed + rand(10.)) * ratio, 
        sin(time * .9 + speed + rand(10.))
    ) * radius;
    uv = place(uv, p + vec2(0., .05), size, a);
    
    vec2 assp = vec2(is2, is2);

    float ass = rect(uv, vec2(.15, -.2), assp, pi4) +
        rect(uv, vec2(.05, -.2), assp, pi4) +
        rect(uv, vec2(-.05, -.2), assp, pi4) +
        rect(uv, vec2(-.15, -.2), assp, pi4) +
        rect(uv, vec2(-.25, -.2), assp, pi4);

    float body = circle(uv, vec2(0.), .2) +
        rect(uv, vec2(-.2, -.2), vec2(.4, .2), 0.) +
        rect(uv, vec2(-.2, -.25), vec2(.4, .06), 0.) * ass;

    float eyes =
        circle(uv, vec2(.08 + .05 * eye, 0.), .05) +
        circle(uv, vec2(-.08 + .05 * eye, 0.), .05) -
        circle(uv, vec2(.08 + .08 * eye, 0.), .02) -
        circle(uv, vec2(-.08 + .08 * eye, 0.), .02);

    float mask = norm(body) - eyes;

    return vec4(vec3(norm(mask)) * col, .5);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;

    glFragColor = ghost(uv, time) +
        ghost(uv, time + rand(1000.)) +
        ghost(uv, time + rand(1000.)) +
        ghost(uv, time + rand(1000.));
}
