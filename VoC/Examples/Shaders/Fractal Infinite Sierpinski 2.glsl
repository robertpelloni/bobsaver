#version 420

// original https://www.shadertoy.com/view/3syBDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SQRT3_2 0.86602540378443864676
#define PI2_3 2.09439510239319549
#define LN2 0.6931471805599453
#define HFLIP(uv) vec2(uv.x, -uv.y)

// Source: https://stackoverflow.com/a/17897228
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float triangle(vec2 uv, float w) {
    //    x
    // 3 / \ 2
    //  x---x
    //    1
    // sin(120°) = sqrt(3) / 2 = 0.8660254037844386467
    // cos(120°) = -0.5
    // sin(30°) = 0.5
    float side1 = smoothstep(-0.25 - w, -0.25 + w, uv.y);
    float side2 = smoothstep(-0.25 - w, -0.25 + w, -uv.x * SQRT3_2 - uv.y * 0.5);
    float side3 = smoothstep(-0.25 - w, -0.25 + w,  uv.x * SQRT3_2 - uv.y * 0.5);
    return side1 * side2 * side3;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    uv += vec2(SQRT3_2, .5) * .5;

    vec3 col = vec3(0);
    //col.y = float(abs(uv.y) < 0.002);
    
    float zoomTime = fract(time * .8);
    float scale = 3. * exp(zoomTime * LN2);
    
    uv /= scale;
    uv.y -= .25;

    // Time varying pixel color
    float w = 1. / resolution.y / scale;
    
    float i = triangle(uv, w);
    uv = HFLIP(uv);
    w *= 2.;
    uv *= 2.;
    i *= (1. - triangle(uv, w));
    
    for (int step = 6; step >= 0; step -= 1) {
        w *= 2.;
        uv *= 2.;
        vec2 uvNext = uv;
        float minL = 100.;
        for (float j = 0.; j < 6.; j += PI2_3) {
            vec2 uvC = uv + vec2(sin(j), cos(j));
            float l = length(uvC);
            if (l < minL) {
                minL = l;
                uvNext = uvC;
            }
        }
        uv = uvNext;
        float fade = 1.;
        if (step == 0) {
            fade = smoothstep(0., 1.0, zoomTime);
        }
        i *= (1. - fade * triangle(uv, w));
    }
    
    col.xyz = i * hsv2rgb(vec3(time * .1, .2, 1.));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
