#version 420

// original https://www.shadertoy.com/view/7tf3Ws

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 20./resolution.x
#define AA2 7./resolution
vec2 ASPECT;

const float PI = acos(-1.);

float easeInSine(float x) {
    return 1. - cos((x * PI) / 2.);
}

float easeOutSine(float x) {
    return sin((x * PI) / 2.);
}

float easeInOutSine(float x) {
    return -(cos(PI * x) - 1.) / 2.;
}

float easeInCubic(float x) {
    return x * x * x;
}

float easeOutCubic(float x) {
    return 1. - pow(1. - x, 3.);
}

float easeInOutCubic(float x) {
    return x < .5 ? 4. * x * x * x : 1. - pow(-2. * x + 2., 3.) / 2.;
}

float easeInQuint(float x) {
    return x * x * x * x * x;
}

float easeOutQuint(float x) {
    return 1. - pow(1. - x, 5.);
}

float easeInOutQuint(float x) {
    return x < .5 ? 16. * x * x * x * x * x : 1. - pow(-2. * x + 2., 5.) / 2.;
}

float easeInCirc(float x) {
    return 1. - sqrt(1. - pow(x, 2.));
}

float easeOutCirc(float x) {
    return sqrt(1. - pow(x - 1., 2.));
}

float easeInOutCirc(float x) {
    return x < .5
      ? (1. - sqrt(1. - pow(2. * x, 2.))) / 2.
      : (sqrt(1. - pow(-2. * x + 2., 2.)) + 1.) / 2.;
}

float easeInElastic(float x) {
    float c4 = (2. * PI) / 3.;

    return x == 0.
      ? 0.
      : x == 1.
      ? 1.
      : -pow(2., 10. * x - 10.) * sin((x * 10. - 10.75) * c4);
}

float easeOutElastic(float x) {
    float c4 = (2. * PI) / 3.;

    return x == 0.
      ? 0.
      : x == 1.
      ? 1.
      : pow(2., -10. * x) * sin((x * 10. - .75) * c4) + 1.;
}

float easeInOutElastic(float x) {
    float c5 = (2. * PI) / 4.5;

    return x == 0.
      ? 0.
      : x == 1.
      ? 1.
      : x < .5
      ? -(pow(2., 20. * x - 10.) * sin((20. * x - 11.125) * c5)) / 2.
      : (pow(2., -20. * x + 10.) * sin((20. * x - 11.125) * c5)) / 2. + 1.;
}

float easeInQuad(float x) {
    return x * x;
}

float easeOutQuad(float x) {
    return 1. - (1. - x) * (1. - x);
}

float easeInOutQuad(float x) {
    return x < .5 ? 2. * x * x : 1. - pow(-2. * x + 2., 2.) / 2.;
}

float easeInQuart(float x) {
    return x * x * x * x;
}

float easeOutQuart(float x) {
    return 1. - pow(1. - x, 4.);
}

float easeInOutQuart(float x) {
    return x < .5 ? 8. * x * x * x * x : 1. - pow(-2. * x + 2., 4.) / 2.;
}

float easeInExpo(float x) {
    return x == 0. ? 0. : pow(2., 10. * x - 10.);
}

float easeOutExpo(float x) {
    return x == 1. ? 1. : 1. - pow(2., -10. * x);
}

float easeInOutExpo(float x) {
    return x == 0.
      ? 0.
      : x == 1.
      ? 1.
      : x < .5 ? pow(2., 20. * x - 10.) / 2.
      : (2. - pow(2., -20. * x + 10.)) / 2.;
}

float easeInBack(float x) {
    float c1 = 1.70158;
    float c3 = c1 + 1.;

    return c3 * x * x * x - c1 * x * x;
}

float easeOutBack(float x) {
    float c1 = 1.70158;
    float c3 = c1 + 1.;

    return 1. + c3 * pow(x - 1., 3.) + c1 * pow(x - 1., 2.);
}

float easeInOutBack(float x) {
    float c1 = 1.70158;
    float c2 = c1 * 1.525;

    return x < .5
      ? (pow(2. * x, 2.) * ((c2 + 1.) * 2. * x - c2)) / 2.
      : (pow(2. * x - 2., 2.) * ((c2 + 1.) * (x * 2. - 2.) + c2) + 2.) / 2.;
}

float easeOutBounce(float x) {
    float n1 = 7.5625;
    float d1 = 2.75;

    if (x < 1. / d1) {
        return n1 * x * x;
    } else if (x < 2. / d1) {
        return n1 * (x -= 1.5 / d1) * x + 0.75;
    } else if (x < 2.5 / d1) {
        return n1 * (x -= 2.25 / d1) * x + 0.9375;
    } else {
        return n1 * (x -= 2.625 / d1) * x + 0.984375;
    }
}

float easeInBounce(float x) {
    return 1. - easeOutBounce(1. - x);
}

float easeInOutBounce(float x) {
    return x < .5
      ? (1. - easeOutBounce(1. - 2. * x)) / 2.
      : (1. + easeOutBounce(2. * x - 1.)) / 2.;
}

float clr(float phase, int id){
    switch(id){
        case 0:  return easeInSine(phase);
        case 1:  return easeOutSine(phase);
        case 2:  return easeInOutSine(phase);
        case 3:  return easeInQuad(phase);
        case 4:  return easeOutQuad(phase);
        case 5:  return easeInOutQuad(phase);
        case 6:  return easeInCubic(phase);
        case 7:  return easeOutCubic(phase);
        case 8:  return easeInOutCubic(phase);
        case 9:  return easeInQuart(phase);
        case 10: return easeOutQuart(phase);
        case 11: return easeInOutQuart(phase);
        case 12: return easeInQuint(phase);
        case 13: return easeOutQuint(phase);
        case 14: return easeInOutQuint(phase);
        case 15: return easeInExpo(phase);
        case 16: return easeOutExpo(phase);
        case 17: return easeInOutExpo(phase);
        case 18: return easeInCirc(phase);
        case 19: return easeOutCirc(phase);
        case 20: return easeInOutCirc(phase);
        case 21: return easeInBack(phase);
        case 22: return easeOutBack(phase);
        case 23: return easeInOutBack(phase);
        case 24: return easeInElastic(phase);
        case 25: return easeOutElastic(phase);
        case 26: return easeInOutElastic(phase);
        case 27: return easeInBounce(phase);
        case 28: return easeOutBounce(phase);
        case 29: return easeInOutBounce(phase);
        default: return 0.;
    }
}

const float BG = .2;
const float WIDTH = .05;
vec3 cell(vec2 uv, int id, float time){
    vec3 res = vec3(BG);
    float p = max(smoothstep(AA2.y, 0., distance(uv.y, 0.)) * smoothstep(.5 + AA2.x, .5, distance(uv.x, .5)),
                  smoothstep(AA2.x, 0., distance(uv.x, 0.)) * smoothstep(.5 + AA2.y, .5, distance(uv.y, .5)));
    res = mix(res, vec3(.8), p);
    res = mix(res, vec3(.8), smoothstep(AA2.y, 0., distance(uv.y, -.5)) * smoothstep(.5 + AA2.x, .5, distance(uv.x, .5)));
    res = mix(res, vec3(1.000,0.361,0.361), smoothstep(AA, 0., distance(uv.x, uv.y)) * smoothstep(.5 + AA2.x, .5, distance(uv.x, .5)));
    float t = clr(time, id);
    res = mix(res, mix(vec3(1., 0., 0.), vec3(.8), smoothstep(uv.x, uv.x + AA2.x, time)),
            smoothstep(WIDTH + AA, WIDTH, distance(clr(uv.x, id), uv.y)) * smoothstep(.6 + AA2.x, .6, distance(uv.x, .5)));

    float l = length((uv - vec2(t, -.5)) * ASPECT);
    res = mix(res, vec3(.8), smoothstep(.25 + AA2.y, .25, l));
    res = mix(res, vec3(.4 + .4 * l), smoothstep(.2 + AA2.y, .2, l));
    return res;
}

const vec2 ITEMS_COUNT = vec2(6., 5.);
const vec2 GRID_SIZE = vec2(1.)/ITEMS_COUNT;
void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 gs = GRID_SIZE;
    
    
    vec2 c = floor(uv/gs);
    int id = int(ITEMS_COUNT.x) * int(c.y) + int(c.x);
    
    ASPECT = resolution.xy/min(resolution.x, resolution.y) * GRID_SIZE/GRID_SIZE.y;
    vec2 muv = mod(uv, gs)/gs;
    
    float time = clamp(mod(time, 2.)/1.5, 0., 1.);
    vec2 offset = vec2(1.);
    glFragColor = vec4(cell(muv * (1. + offset) - offset * .5 - vec2(0., offset.y * .25), id, time), 1.);
}
