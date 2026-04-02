#version 420

// original https://www.shadertoy.com/view/3sdGzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.1415926535897932384626433832795

float hash21(vec2 p) {
    p = fract(p*vec2(1.34, 435.345));
    p += dot(p, p+34.23);
    return fract(p.x*p.y);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy)/resolution.y;
    uv += vec2(time * .1, time * .06789);
    uv *= vec2(8, 16);
    // Build a 3D rotation matrix.
    float yTheta = M_PI / 4.;
    mat3 yRot = mat3(cos(yTheta), 0, sin(yTheta),
                     0, 1, 0,
                     -sin(yTheta), 0, cos(yTheta));
    // Rotate the uv.
    uv = (vec3(uv.x, 0, uv.y) * yRot).xz;

    vec2 id = floor(uv);
    vec2 lv = fract(uv);
    
    float border = hash21(id * 5.) < .6 ? .1 : .2;
    float theta = time + hash21(id * 5.) * 2. * M_PI;
    float period = 1. + hash21(id * 4.);
    period *= .2;
    float thetaOffset = hash21(id * 3.) * 2. * M_PI;
    float amplitude = .5 + hash21(id * 2.);
    float ampOffset = hash21(id);
    float depth = min(1. - border, 2. + sin(theta * period + thetaOffset) * amplitude - ampOffset);
    vec3 col;
    if (lv.x < border || lv.x > 1. - border || lv.y < border || lv.y > 1. - border) {
        // borders
        col = vec3(.7);
    } else if(lv.x < depth && lv.y < depth) {
        // floor
        float mult = mix(.4, 1., depth + border);
        col = vec3(.7) * mult;
        // wall shadow
        if (lv.x > (depth - .5 + border / 2.) * 2. || lv.y < 1. - depth) {
            col *= .8;
        }
    } else {
        // walls
        col = vec3(mix(.3, .6, length(lv)));
        if (lv.x > lv.y) {
            col *= .8;
        }
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
