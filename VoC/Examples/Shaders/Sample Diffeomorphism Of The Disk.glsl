#version 420

// original https://www.shadertoy.com/view/4sjfDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of Fabrice's https://www.shadertoy.com/view/ltdXR8

// I'm pretty sure this is a diffeomorphism of the disk,
// which reminds me a lot of Wikipedia's diffeomorphism of the square:
// https://en.wikipedia.org/wiki/Diffeomorphism
// https://en.wikipedia.org/wiki/File:Diffeomorphism_of_a_square.svg

#define TWIST 4.
#define STRIPES 70.
#define STRIPE_THINNESS .7

void main(void) {
    vec2 uv=gl_FragCoord.xy;
    uv = (2.*uv - resolution.xy) / resolution.y;

    float radius = distance(uv, vec2(0));
    float angle = atan(uv.y, uv.x);

    float radius_complement = clamp(1. - radius, .0, 1.);  // This seems to have all the magic...
    float twisting = sin(angle + TWIST * pow(radius_complement, 2.) * sin(time));  // This adds all the twisting!
    float rgb = radius * twisting;
    rgb = STRIPE_THINNESS + sin(rgb * STRIPES);  // Try to comment this out!
    rgb /= fwidth(rgb);  // Some AA!

    glFragColor.rgb = vec3(rgb);
}
