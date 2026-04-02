#version 420

// original https://www.shadertoy.com/view/WtGXWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
@lsdlive
CC-BY-NC-SA

Motion Loop #004

Checkout the ISF port: https://github.com/theotime/isf_shaders/blob/master/shaders/motiongraphics_004.fs

With the help of https://thebookofshaders.com/examples/?chapter=motionToolKit

*/

#define bpm 120.
#define speed .5
/*
#define samples_dx .1
#define position_x .1
#define position_y .5
*/
#define samples_dx .05
#define position_x .4
#define position_y 1.

#define AA 5.

#define pi 3.141592
#define pi_half 1.570796
#define time (speed*(bpm/60.)*time)

// https://lospec.com/palette-list/1bit-monitor-glow
vec3 col1 = vec3(.133, .137, .137);
vec3 col2 = vec3(.941, .965, .941);

// inspired by Pixel Spirit Deck: https://patriciogonzalezvivo.github.io/PixelSpiritDeck/
// + https://www.shadertoy.com/view/tsSXRz
float stroke(float d, float width) {
    return 1. - smoothstep(0., AA / resolution.x, abs(d) - width * .5);
}

float circle(vec2 p, float radius) {
  return length(p) - radius;
}

// https://thebookofshaders.com/edit.php?log=160909064320
float easeInOutQuad(float t) {
    if ((t *= 2.) < 1.) {
        return .5 * t * t;
    } else {
        return -.5 * ((t - 1.) * (t - 3.) - 1.);
    }
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    
    float t = fract(time * .25);
    float t_pi = t * 2. * pi;
    float t_pi_ease =  2. * pi * easeInOutQuad(t);
        
    // Construct a sphere with ellipses:
    // ellipse pos.y = sin(a) * sphere_radius
    // ellipse radius = cos(a) * sphere_radius
    // then, animate some values
    float sphere_radius = .3;
    vec2 ellipse_scale = vec2(1., 2.);
    float mask;
    for (float a = -pi_half; a < pi_half; a += samples_dx) {
        vec2 pos = vec2(
            cos(pi * .25 + 2. * a + t_pi) * position_x,
            sphere_radius * sin(a) * cos(position_y * a * a + t_pi_ease));// y

        pos.y *= 1.2; // y scaling adjustement
        float radius = sphere_radius * cos(a) + .1 * cos(t_pi) * sin(t_pi);// x
        float sdf = circle((uv - pos) * ellipse_scale, radius);

        mask += stroke(sdf, .005);
    }
    
    mask = clamp(mask, 0., 1.);
    vec3 col = mix(col1, col2, mask);
    
    glFragColor = vec4(col, 1.);
}
