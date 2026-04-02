#version 420

// original https://www.shadertoy.com/view/wlBfD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592653546264338327

const float VIGNETTE_START = 0.2;

const vec4 orange = vec4(235., 133., 47., 255.0) / 255.;
const vec4 red = vec4(120, 0., 16., 255.0) / 255.;
const vec4 green = vec4(0.05098, 0.6725, 0.0784, 0.05);
const vec4 blue = vec4(0.0784, 0.05098, 0.6725, 0.1);
const vec4 BG_COLOR = vec4((orange * 0.08).rgb, 0.0);

vec4 lighten(vec4 a, vec4 b) {
    return vec4(max(a, b));
}

// https://gist.github.com/DancingPhoenix88/b16af3a46dcf54f8dd5ea94088edb4cd
float rand(float n){return fract(sin(n) * 43758.5453123);}

float noise(float p){
    float fl = floor(p);
     float fc = fract(p);
    return mix(rand(fl), rand(fl + 1.0), fc);
}

// Based on https://www.shadertoy.com/view/4sX3Rs
float sun(vec2 uv, vec2 speed)
{
    vec2 main = uv;
    vec2 uvd = uv * (length(uv));

    float ang = clamp(-PI, PI, atan(main.x, main.y));
    float f0 = 0.5 / (length(uv) * 16.0);

    return smoothstep(.0, 1., f0 + f0 * abs((noise(sin(ang*3. - speed.x)*4.0 - cos(ang*2. + speed.y) * 3.0)*16.))*.1);
}

// They've gone to plaid

float createBandMask(float x, float blurRadius, float width, float base) {
    width -= 2. * blurRadius;
    return smoothstep(0.0, blurRadius, abs(x - base - width / 2. - blurRadius) - width / 2.);
}

vec4 plaidVecritcalRed(vec2 uv, float tunnelParam) {
    vec4 col = vec4(0.0);

    if (tunnelParam <= 0.) {
        tunnelParam = 0.0;
    }

    float blur = 0.04;
    float baseSize = 0.15;
    float size = baseSize + (0.33 - baseSize) * tunnelParam;
    float baseOffset = 0.;
    float offset = baseOffset + (0.3 - baseOffset) * tunnelParam;
    float redMaskV = 1. - createBandMask(uv.x, blur, size, 0.);
    col = mix(col, red, redMaskV * 0.8);

    return col;
}

vec4 plaidVecritcalOrange(vec2 uv, float tunnelParam) {
    vec4 col = vec4(0.0);

    float baseOffset1 = 0.13;
    float baseOffset2 = 0.26;

    if (tunnelParam <= 0.) {
        tunnelParam = 0.0;
        baseOffset2 = baseOffset1;
    }

    float blur = 0.02;
    float baseSize = 0.1;
    float size = baseSize + (0.3 - baseSize) * tunnelParam;

    float offset1 = baseOffset1 + (0.3 - baseOffset1) * tunnelParam;
    float offset2 = baseOffset2 + (0.3 - baseOffset2) * tunnelParam;
    float orangeMaskV = 1. - createBandMask(uv.x, blur, size, offset1)
                           * createBandMask(uv.x, blur, size, offset2);
    col = mix(col, orange, orangeMaskV * .7);

    return col;
}

vec4 plaidFirst(vec2 uv, float tunnelParam) {

    vec4 col = vec4(0.0);

    float width = 1./12.;
    float off = 1. / 8.;
    float blur = width * 0.3;

    float baseBlue = 1. * off;
    float blueMask = 1. - createBandMask(uv.y, blur, width, baseBlue)
                        * createBandMask(uv.y, blur, width, baseBlue + 2. * off);

    float baseGreen = 2. * off;
    float greenMask = 1. - createBandMask(uv.y, blur, width, baseGreen)
                         * createBandMask(uv.y, blur, width, baseGreen + 2. * off);

    tunnelParam = 1. - tunnelParam;

    greenMask *= 0.12 * tunnelParam;
    blueMask *= 0.6 * tunnelParam * tunnelParam;

    col = mix(col, green, greenMask);
    col = mix(col, blue, blueMask);

    vec4 redV = plaidVecritcalRed(uv, tunnelParam);
    vec4 orangeV = plaidVecritcalOrange(uv, tunnelParam);

    col = mix(col, redV + orangeV, (redV + orangeV).a);

    tunnelParam = .8 * tunnelParam + 0.2;
    col = mix(col, vec4(1.0), 2. * orangeV.a * blueMask * tunnelParam);

    return col;
}

vec4 plaidSecond(vec2 uv, float tunnelParam) {

    vec4 col = vec4(0.0);

    float width = 1./12.;
    float off = 1. / 8.;
    float blur = width * 0.3;

    float baseOrange = 0. * off;
    float orangeMask = 1. - createBandMask(uv.y, blur, width, baseOrange)
                          * createBandMask(uv.y, blur, width, baseOrange + 7. * off);

    float baseRed = 5. * off;
    float redMask = 1. - createBandMask(uv.y, blur, width, baseRed)
                       * createBandMask(uv.y, blur, width, baseRed + 1. * off);

    col = mix(col, orange, orangeMask);
    col = mix(col, red, redMask);

    return col;
}

// Main code

void _main(vec2 uv, out vec4 glFragColor, const float time, const float aspect) {

    float progress = time / 4.; //smoothstep(0.0, 0.5, fract(time / 12.));

    vec4 col;
    float ludicrousProgress = progress;

    const float window = 80./340.;

    float vignette = abs(uv.x + uv.y) + abs(uv.x - uv.y);

    if(ludicrousProgress > VIGNETTE_START) {
        float vignetteProgress = 1.5 * aspect * smoothstep(0.0, 1.0 - VIGNETTE_START, (ludicrousProgress - VIGNETTE_START));

        float wallId = ceil((uv.x + uv.y) * (uv.x - uv.y));

        vec2 nuv;

        if (wallId > 0.5) {
            nuv = vec2(1. / uv.x * sign(uv.x), uv.y / uv.x);
        } else {
            nuv = vec2(1. / uv.y * sign(uv.y), -uv.x / uv.y);
        }

        float tunnelParam = smoothstep(window, aspect, vignette);

        if (vignette < window) {
            if (wallId > 0.5) {
                nuv = vec2(-8. * uv.x * sign(uv.x), uv.y / uv.x);
            } else {
                nuv = vec2(-8. * uv.y * sign(uv.y), -uv.x / uv.y);
            }
            //Evil state change
            tunnelParam = 1.1;
        }

        nuv.x -= 0.6;
        nuv.x += 2. * fract(0.35 * time);
        nuv.y -= 0.4;

        nuv = 0.5 * nuv + 0.5;
        nuv.x *= 4.;
        nuv.y *= 2.5;

        vec2 partialUv = fract(nuv);
        col += plaidFirst(partialUv, tunnelParam);
        col = mix(col, BG_COLOR, smoothstep(window, window * 0.5, vignette));
        col += plaidSecond(partialUv, tunnelParam);
        col = lighten(col, BG_COLOR);
        col.a = 1.0;
        col *= 1. - smoothstep(0.0, 0.05, vignette - vignetteProgress);
    }

    float sunProgress = smoothstep(0.0, 1.0, ludicrousProgress * 10.);
    vec2 wUv = uv / window;

    float oldAlpha = col.a;
    col += (orange * sun(wUv * 0.3, vec2(2.*time, 2.*time))+ 1.0 * (sun(wUv * 0.5, vec2(time, time)))) * (1. - length(2. * uv) * aspect) * sunProgress;
    col.a = clamp(0.0, 1.0, max(col.a, oldAlpha));

    glFragColor = col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;

    float ASPECT = resolution.x / resolution.y;
    
    _main(uv, glFragColor, time, ASPECT);
}

