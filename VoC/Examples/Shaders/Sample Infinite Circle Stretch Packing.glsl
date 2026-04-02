#version 420

// original https://www.shadertoy.com/view/XtVfWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.28318530718
#define PI TAU/2
    
// biases x to be closer to 0 or 1
// can act like a parameterized smoothstep
// https://www.desmos.com/calculator/c4w7ktzhhk
// if b is near 1.0 then numbers a little closer to 1.0 are returned
// if b is near 0.0 then numbers a little closer to 0.0 are returned
// if b is near 0.5 then values near x are returned
float bias(float x, float b) {
    x = clamp(x, 0., 1.);
    b = -log2(1.0 - b);
    return 1.0 - pow(1.0 - pow(x, 1./b), b);
}

vec3 orange = vec3(1.,.5,0.);

vec2 domsMouse;

vec2 project(vec2 pixel) {
    vec2 uv = pixel/resolution.xy - vec2(0.5);
    uv.x *= resolution.x / resolution.y;
    return uv;
}

float circle(vec2 uv) {
    //uv *= 2.;
    if (length(uv)< 0.9) {
        return 0.3;
    }
    if (length(uv)< 1.) {
        return 1.;
    }
    return 0.;
    return clamp(length(uv)-8., 0., 1.);
    return bias(1.-(abs(length(uv) - 1. +.018) / .02), .8);
}
float row_of_circles(vec2 uv, float width) {
    uv.x = mod(uv.x+width, 2.*width) - width;
    return circle(uv);
}
// Returns a unit-length vector at a given rotation.
// Analogous to e^(-i*theta)
// i.e. rotate (1,0) anticlockwise for theta radians. (+y means facing up)
vec2 e(float theta) {
    return vec2(cos(theta), sin(theta));
}
float monochrome(vec2 uv) {
    float height = 4.;
    float acc = 0.;
    float animation_fraction = mod(.5*time, 1.);// (.5+ .5*cos(mod(2.*time, TAU*.5)));
    animation_fraction = mix(animation_fraction, smoothstep(0., 1., animation_fraction), .5);
    float theta = TAU/6. * animation_fraction;
    vec2 c0 = vec2(0., 0.);
    vec2 c1 = c0 - 2.*e(theta);
    vec2 c2 = c1 - 2.*e(TAU/3.);
    vec2 c3 = c2 - 2.*e(TAU/2.-theta);
    vec2 c4 = c3 - 2.*e(TAU/3.);
    float separation = 2.* cos(theta);
    uv.y = mod(uv.y, -c4.y);
    //if (uv.y > -c4.y*.99) { return 1. ; }
    
    acc += row_of_circles(uv + c0, separation);
    acc += row_of_circles(uv + c1, separation);
    acc += row_of_circles(uv + c2, separation);
    acc += row_of_circles(uv + c3, separation);
    
    
    
    // Extra circles to not get artifacts when wrapping vertically.
    vec2 offset_bot = vec2(0.0, c4.y);
    acc += row_of_circles(uv + c0 + offset_bot, separation);
    acc += row_of_circles(uv + c1 + offset_bot, separation);
    //acc += row_of_circles(uv + c2 + offset_bot, separation);
    //acc += row_of_circles(uv + c3 + offset_bot, separation);
    
    return clamp(acc, 0., 1.);
}

float f(vec2 pv) {
    vec2 uv = project(pv.xy);
    uv /= project(domsMouse.xy).xx;
    return monochrome(uv);
}
// antialiasing
float sampleSubpixel(vec2 pixels) {
    const int size = 1; 
    float disp = 1.0 / (float(size) + 2.0);
    float contrb = 0.0;
    float maxContrb = 0.0;
    for (int j = -size; j <= size; j++) {
        for (int i = -size; i <= size; i++) {
            contrb += f(pixels + vec2(float(i) * (disp / 3.0), float(j) * disp));
            maxContrb += 1.0;
        }
    }
    return contrb / maxContrb;
}

void main(void) {
    domsMouse=0.575*resolution.xy.xy;
    //domsMouse=mouse*resolution.xy.xy;
    //if (mouse*resolution.xy.x == 0.) { domsMouse.x = resolution.x * .5 + 30.; }
    glFragColor = vec4(orange * sampleSubpixel(gl_FragCoord.xy), 1.0);
}
