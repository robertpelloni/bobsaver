#version 420

// original https://www.shadertoy.com/view/ssc3Wr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI (3.14159265358979)

// gives pure saturated color from input [0, 6) for phase
vec3 hue(float x) {
    x = mod(x, 6.);
    return clamp(vec3(
        abs(x - 3.) - 1.,
        -abs(x - 2.) + 2.,
        -abs(x - 4.) + 2.
    ), 0., 1.);
}

// does pseudo overexposure filter
vec3 deepfry(vec3 rgb, float x) {
    rgb *= x;
    return rgb + vec3(
      max(0., rgb.g - 1.) + max(0., rgb.b - 1.),
      max(0., rgb.b - 1.) + max(0., rgb.r - 1.),
      max(0., rgb.r - 1.) + max(0., rgb.g - 1.)
    );
}

void main(void)
{
    float time = mod(time, 6.);
    // Scales coords so that the diagonals are all dist 1 from center
    float scale = length(resolution.xy);
    vec2 uv = (gl_FragCoord.xy / scale
    - (resolution.xy / scale / 2.)) * 2.;
    
    // for wormhole or perspective effect
    float r = (log(uv.x*uv.x+uv.y*uv.y) + length(uv) * -1.6) * (1.0 + 0.4 * sin(time));
    float theta = atan(uv.y, uv.x);
    
    
    // if you want the angle in range [0, 1) and not (-π, π]
    // divide angle by 2pi and mod1 it
    // float theta = fract(atan(uv.y, uv.x) / 6.2831853071795);

    // Time varying pixel color
    vec3 col = deepfry(
        hue(r * -3. + theta * 6. / PI + time * 3.),
        1. + 0.5 * sin(r * 1.8 + theta * 1.0 + time * -PI)
    );

    // Output to screen
    glFragColor = vec4(col,1.0);
}
