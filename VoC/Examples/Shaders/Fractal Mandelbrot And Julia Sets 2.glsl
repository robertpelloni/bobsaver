#version 420

#define MAX 64.0
#define ZOOM 4.0
#define POS vec2(0.0, 0.0)

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/************************

INTERACTIVE VISUALIZATION OF RELATIONSHIP BETWEEN MANDELBROT SET AND JULIA SET ( OF Z=Z^2+C ).
MOVE YOUR MOUSE CURSOR ON THE MANDELBROT SET LOCATED LEFT SIDE OF YOUR SCREEN.

************************/

// Thanks to https://github.com/hughsk/glsl-hsv2rgb
vec3 hsv2rgb(vec3 c) {
     vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// real power of complex number
vec2 cpow (vec2 z, float m) {
    float r = pow(length(z), m);
    float t = atan(z.y, z.x) * m;
    return r * vec2(cos(t), sin(t));
}

void main( void ) {

    vec3 col = vec3(0.0);
    
    // Follow Mouse coord
    vec2 c = vec2(mouse.x * 2.0 - 0.5, mouse.y - 0.5) * ZOOM + POS;
    
    // Animate around the main cardioid
    //vec2 c = vec2((2.0 * cos(time) - cos(2.0 * time)) / 4.0, (2.0 * sin(time) - sin(2.0 * time)) / 4.0);
    
    if (gl_FragCoord.x == resolution.x / 2.0) {
        return;
    }
    
    if (gl_FragCoord.x > resolution.x / 2.0) {
        vec2 z = (gl_FragCoord.xy - vec2(resolution.x / 4.0 * 3.0, resolution.y / 2.0)) / min(resolution.x / 2.0, resolution.y) * 3.0;
        for (float i = 0.0; i < MAX; i++) {
            z = cpow(z, 2.0) + c;
            if (length(z) > 4.0) {
                col = hsv2rgb(vec3(i / MAX, 1.0, 1.0));
            }
        }
    } else {
        vec2 d = (gl_FragCoord.xy - vec2(resolution.x / 4.0, resolution.y / 2.0)) / min(resolution.x / 2.0, resolution.y) * ZOOM + POS;
        vec2 z = vec2(0.0, 0.0);
        for (float i = 0.0; i < MAX; i++) {
            z = cpow(z, 2.0) + d;
            if (length(z) > 4.0) {
                col = hsv2rgb(vec3(i / MAX, 1.0, 1.0));
            }
        }
        if (length(d - c) < ZOOM / 150.0) {
            col = vec3(1.0);
        }
    }
    
    glFragColor = vec4(col, 1.0);

}
