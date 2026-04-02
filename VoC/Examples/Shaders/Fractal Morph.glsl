#version 420

// original https://www.shadertoy.com/view/flfGR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Morph by soma_arc 

const vec3 BLACK = vec3(0, 0, 0.01);
const vec3 WHITE = vec3(1);
const vec3 RED = vec3(0.8, 0, 0);
const vec3 GREEN = vec3(0, 0.8, 0);
const vec3 BLUE = vec3(0, 0, 0.8);
const vec3 YELLOW = vec3(1, 1, 0);
const vec3 PINK = vec3(.78, 0, .78);
const vec3 LIGHT_BLUE = vec3(0, 1, 1);

const float PI = 3.141592;

vec2 rand2n(vec2 co, float sampleIndex) {
    vec2 seed = co * (sampleIndex + 1.0);
    seed+=vec2(-1,1);
    // implementation based on: lumina.sourceforge.net/Tutorials/Noise.html
    return vec2(fract(sin(dot(seed.xy ,vec2(12.9898,78.233))) * 43758.5453),
                fract(cos(dot(seed.xy ,vec2(4.898,7.23))) * 23421.631));
}

vec2 circleInvert(const vec2 pos, const vec4 circle){
    vec2 p = pos - circle.xy;
    float d = length(p);
    return (p * circle.w)/(d * d) + circle.xy;
}

const float GAMMA_COEFF = 2.2;
const float DISPLAY_GAMMA_COEFF = 1. / GAMMA_COEFF;
vec3 gammaCorrect(vec3 rgb) {
  return vec3((min(pow(rgb.r, DISPLAY_GAMMA_COEFF), 1.)),
              (min(pow(rgb.g, DISPLAY_GAMMA_COEFF), 1.)),
              (min(pow(rgb.b, DISPLAY_GAMMA_COEFF), 1.)));
}

vec3 degamma(vec3 rgb) {
  return vec3((min(pow(rgb.r, GAMMA_COEFF), 1.)),
              (min(pow(rgb.g, GAMMA_COEFF), 1.)),
              (min(pow(rgb.b, GAMMA_COEFF), 1.)));
}

float lineY(vec2 pos, vec2 uv){
    return uv.x * .5 + sign(uv.y * .5) * (2.*uv.x-1.95)/4. * sign(pos.x + uv.y * 0.5)* (1. - exp(-(7.2-(1.95-uv.x)*15.)* abs(pos.x + uv.y * 0.5)));
}

vec2 TransA(vec2 z, vec2 uv){
    float iR = 1. / dot(z, z);
    z *= -iR;
    z.x = -uv.y - z.x; z.y = uv.x + z.y;
    return z;
}

vec2 TransAInv(vec2 z, vec2 uv){
    float iR = 1. / dot(z + vec2(uv.y,-uv.x), z + vec2(uv.y, -uv.x));
    z.x += uv.y; z.y = uv.x - z.y;
    z *= iR;
    return z;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 computeColor(float n){
    return hsv2rgb(vec3(.3 +0.06 * n, 1., .7));
}

vec3 computeColor2(float n, float numTransA) {
    if(n == 0.) {
        return vec3(0, 0, 0.05);
    }
    return hsv2rgb(vec3(0. + 0.05 * (n -1.), 1.0, 1.0));
}

//w: start time
//s: duration
float scene(in float t, in float w, in float s){
    return clamp(t - w, 0.0, s) / s;
}

float expEasingIn(float t){
    return pow( 2., 13. * (t - 1.) );
}
float expEasingOut(float t) {
    return -pow( 2., -10. * t) + 1.;
}

float circEasingInOut(float t){
    t /= .5;
    if (t < 1.) return -.5 * (sqrt(1. - t*t) - 1.);
    t -= 2.;
    return .5 * (sqrt(1. - t*t) + 1.);
}

float circEasingIn(float t){
    return -  (sqrt(1. - t*t) - 1.);
}

const int LOOP_NUM = 500;
vec3 josKleinianIIS(vec2 pos, vec2 uv, float translation){
    float loopNum = 0.;
    vec2 lz = pos + vec2(1.);
    vec2 llz = pos + vec2(-1.);

    float numTransA = 0.;
    for(int i = 0 ; i < LOOP_NUM ; i++){
        // translate
        pos.x += translation/2. + (uv.y * pos.y) / uv.x;
        pos.x = mod(pos.x, translation);
        pos.x -= translation/2. + (uv.y * pos.y) / uv.x;

        // rotate 180
        if (pos.y >= lineY(pos, uv.xy)){
            // pos -= vec2(-uv.y, uv.x) * .5;
            // pos = - pos;
            // pos += vec2(-uv.y, uv.x) * .5;
            // |
            pos = vec2(-uv.y, uv.x) - pos;
            //loopNum++;
        }

        pos = TransA(pos, uv);
        numTransA++;
        if(uv.x < pos.y) {
            pos.y -= uv.x;
            pos.y *= -1.;
            pos.y += uv.x;
            loopNum++;
        }
        if(pos.y <= 0.){
            pos.y *= -1.;
            loopNum++;
        }

        // 2-cycle
        if(dot(pos-llz,pos-llz) < 1e-6) return computeColor2(loopNum, numTransA);

        llz=lz; lz=pos;
    }
    return computeColor2(loopNum, numTransA);
}

void main(void)
{
    const int SAMPLE_NUM = 10;
    vec3 sum = vec3(0);
    float ratio = resolution.x / resolution.y / 2.0;

    float p_scale = 4.;
    vec2 p_translate = vec2(-1, 1);
    vec4 p_inversionCircle = vec4(0, 1, 1, 1);

    vec2 p_symmetricalPoint = vec2(0., 1.);

    float n = 1.;
    float p_maskitK = 2. * cos(PI / n); // default value is k = 2

    float t = mod(time, 16.);
    float start = 0.0;
    float duration = 1.5;

    p_inversionCircle.x += mix(0., 0.5, circEasingInOut(scene(t, start, duration)));
    start += duration + 0.1;
    p_inversionCircle.x += mix(0., -1.5, circEasingInOut(scene(t, start, duration)));
    start += duration + 0.1;

    // arms start
    duration = 0.8;
    p_scale += mix(0., .9, circEasingInOut(scene(t, start, duration)));
    p_symmetricalPoint += mix(vec2(0), vec2(0.1, -0.1), circEasingInOut(scene(t, start, duration)));
    start += duration + 0.2;
    p_symmetricalPoint -= mix(vec2(0), vec2(0.1, -0.1), circEasingInOut(scene(t, start, duration)));
    start += duration + 0.1;

    p_symmetricalPoint += mix(vec2(0), vec2(-0.1, -0.1), circEasingInOut(scene(t, start, duration)));
    start += duration + 0.2;
    p_symmetricalPoint -= mix(vec2(0), vec2(-0.1, -0.1), circEasingInOut(scene(t, start, duration)));
    p_scale += mix(0., -.9, circEasingInOut(scene(t, start, duration)));
    start += duration + 0.1;

    // arms end

    duration = 1.0;
    p_inversionCircle.y += mix(0., -1., circEasingInOut(scene(t, start, duration)));
    start += duration + 0.1;
    p_inversionCircle.x += mix(0., 1., circEasingInOut(scene(t, start, duration)));
    start += duration + 0.1;
    p_inversionCircle.x += mix(0., -0.5, circEasingInOut(scene(t, start, duration)));
    start += duration + 0.1;

    p_scale += mix(0., 15.5, circEasingInOut(scene(t, start, duration)));
    start += duration + 0.1;

    p_translate.x += mix(0., 1.5, circEasingInOut(scene(t, start, duration)));
    p_translate.y += mix(0., -.5, circEasingInOut(scene(t, start, duration)));
    p_inversionCircle.y += mix(0., -0.5, circEasingInOut(scene(t, start, duration)));
    start += duration + 0.1;
    p_scale -= mix(0., 15.5, circEasingInOut(scene(t, start, duration)));
    start += duration + 0.25;

    // ending
    p_inversionCircle.y += mix(0., 1.5, circEasingInOut(scene(t, start, duration)));
    start += duration + 0.1;
    p_inversionCircle.x += mix(0., 0.5, circEasingInOut(scene(t, start, duration)));
    p_translate.x += mix(0., -1.5, circEasingInOut(scene(t, start, duration)));
    p_translate.y += mix(0., .5, circEasingInOut(scene(t, start, duration)));

    vec2 p_maskitUV = vec2(p_symmetricalPoint.y * 2., -p_symmetricalPoint.x * 2.);
    for(int i = 0 ; i < SAMPLE_NUM ; i++){
        vec2 position = ( (gl_FragCoord.xy + (rand2n(gl_FragCoord.xy, float(i)))) / resolution.yy ) - vec2(ratio, 0.5);
        position *= p_scale;
        position += p_translate;

        position = circleInvert(position, p_inversionCircle);

        if(true) {
            sum += josKleinianIIS(position,
                                  p_maskitUV, p_maskitK);
        } else {
            //sum += josKleinian(position,
            //                  p_maskitUV, p_maskitK);
        }
    }

    glFragColor = vec4(gammaCorrect(sum / float(SAMPLE_NUM)), 1);
}

