#version 420

// original https://www.shadertoy.com/view/fdS3DG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI     3.14159265358
#define TWO_PI 6.28318530718;
const float timeScale = 4.;

float saw(float rads) {
    rads += PI * 0.5; // sync oscillation up with sin()
    float percent = mod(rads, PI) / PI;                
    float dir = sign(sin(rads));
    return dir * (2. * percent  - 1.);
}

void main(void)
{
    // set time & centered position
    float time = 10. + time * timeScale;
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    uv *= .8;
    uv.y = -0.1 - uv.y*1.2 + abs(uv.x)*(1.0-abs(uv.x));
    // calc additive distance from control points
    float dist = 0.;
    for(int ii = 1; ii < 5; ii++) {
          dist += (10. + 7. * sin(time/timeScale)) * distance(uv, vec2(0.));
    }
    // oscillate color components by distance factor. smoothstep for contrast boost
    vec3 col = vec3(
        smoothstep(0.1, 0.9, abs(sin(time + dist * 0.11)) * 0.5 + 0.6),
        smoothstep(0.1, 0.8, abs(cos(time + dist * 0.22)) * 0.37 + 0.01),
        smoothstep(0.1, 0.8, abs(sin(time + dist * 0.33)) * 0.15 + 0.4)
    );
    // vignette outside of center
    float vignetteInner = 0.75;
    float vignetteDarkness = 0.4;
    col -= smoothstep(0., 0.7, max(0., length(uv) - vignetteInner) * vignetteDarkness);

    glFragColor = vec4(col, 1.0);
}
