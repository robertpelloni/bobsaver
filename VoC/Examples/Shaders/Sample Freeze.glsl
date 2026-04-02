#version 420

// original https://www.shadertoy.com/view/3sVGR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PERIOD 5.
#define COLOR vec3(.7, .9, .9)
#define ROUNDNESS .06
#define DROP_SIZE .06
#define EDGE .05
#define GRAVITY 50.

float opU(float a, float b) {
    return min(a, b);
}

float opS(float a, float b) {
    return max(a, -b);
}

float opSU(float a, float b, float k) {
    float h = clamp(.5 + .5 * (b - a) / k, 0., 1.);
    return mix(b, a, h) - k * h * (1. - h);
}

float sdIcicle(vec2 p, vec2 size) {
    p = vec2(abs(p.x), p.y + size.y);
    float s = dot(p, normalize(vec2(size.y, -size.x)));
    return (dot(p, size) > 0.) ? s : length(p);
}

float sdFullCicle(vec2 p, vec2 q, inout float w, float offset, vec2 size, float t) {
    p.x -= offset;
    q.x -= offset;
    q = mix(q, p, smoothstep(-.2, -.05, -size.y - p.y));
    t = fract(t);
    float d = sdIcicle(q, size) - ROUNDNESS;
    float drop1 = - size.y - GRAVITY * t * t;
    float drop2 = - size.y + 1. - t;
    d = opSU(d, distance(p, vec2(0, drop1)) - DROP_SIZE, ROUNDNESS);
    d = opSU(d, distance(p, vec2(0, drop2)) - DROP_SIZE, ROUNDNESS);
    float arrival = t - sqrt((2. - size.y) / GRAVITY);
    p.x = abs(p.x);
    w += smoothstep(.1, .0, abs(arrival - .1)) *
         cos(p.x * 20. - (arrival) * 100.) *
         smoothstep(-.1, .0, p.x - arrival) *
         smoothstep(.4, .0, p.x) * .02;
    return d;
}

void main(void) {
    float color = 0.;
    
    float res = min(resolution.y, resolution.x);
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.) / res;
    
    if (abs(uv.x) < .45 && uv.y < .45) {
        float t = fract(time / PERIOD);
        vec2 p = uv / .45;
        p.y -= 1.;
        
        float melt =  1.;
        
        vec2 q = p;
        q+= sin(q.yx * 5.) * .01;
        q.x-= sin(q.y * 20.) * .005;
        q.y-= sin(q.y * 50.) * .002;
        
        float d = - p.y - .1;
        float wave = 0.;
        
        d = opSU(d, sdFullCicle(p, q, wave, -.75, vec2(.1, 1.2 * melt), t + .1), ROUNDNESS * 2.);
        d = opSU(d, sdFullCicle(p, q, wave, -.4, vec2(.1, .7 * melt), t + .7), ROUNDNESS * 2.);
        d = opSU(d, sdFullCicle(p, q, wave, -.1, vec2(.2, .2 * melt), t + .2), ROUNDNESS * 2.);
        d = opSU(d, sdFullCicle(p, q, wave, .15, vec2(.1, .5 * melt), t + .5), ROUNDNESS * 2.);
        d = opSU(d, sdFullCicle(p, q, wave, .5, vec2(.1, .8 * melt), t + .9), ROUNDNESS * 2.);
        d = opSU(d, sdFullCicle(p, q, wave, .8, vec2(.1, .3 * melt), t + .4), ROUNDNESS * 2.);
        
        d = opS(d, d + EDGE - sin(q.y * 50.) * .004 * smoothstep(-1.2, -.2, p.y));
        d = opSU(d, p.y + 2. - .02 + wave, ROUNDNESS);

        float w = fwidth(d);
        color = min(1.,1. + d / w);
    }

    glFragColor = vec4(mix(vec3(0), COLOR, color), 1);
}
