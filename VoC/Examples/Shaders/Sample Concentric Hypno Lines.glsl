#version 420

// original https://www.shadertoy.com/view/MlySRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI     3.14159265358
#define TWO_PI 6.28318530718

// saw method ported from my Processing code to be a drop-in replacement for sin()
// there's probably a way better way to do this..
float saw(float rads) {
    rads += PI * 0.5; // sync oscillation up with sin()
    float percent = mod(rads, PI) / PI;                
    float dir = sign(sin(rads));
    percent *= 2. * dir;
    percent -= dir;
    return percent;
}

void main(void)
{
    float time = time * 0.5;
    // center coordinates
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y,
         center = vec2(0);
    // wobble
    float wobbleOscillations = 6. + 6. * sin(time);
    float wobble = 1. + 0.2 + 0.2 * sin(PI/2. + wobbleOscillations * atan(uv.x, uv.y));
    float dist = distance(uv, center) * wobble;
    // line params
    float expandTime = time * -20.;
    float spacing = 40. + 20. * sin(time);
    float baseColor = 0.6 + 0.2 * sin(time);
    float colorSpread = 0.4 + 0.2 * sin(PI + time);
    // concentric color oscillation
    vec3 color = vec3(baseColor + colorSpread * saw(expandTime + spacing * dist));
    glFragColor = vec4(color, 1.);
}
