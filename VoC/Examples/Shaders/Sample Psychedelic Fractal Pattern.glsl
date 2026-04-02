#version 420

// original https://www.shadertoy.com/view/XtGcWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Psychedelic Fractal test
    
    Derived from a shader by Kali -
        https://www.shadertoy.com/view/ltB3DG

*/

#define R resolution.xy
#define T time

mat2 rotate(float a) {
    float c = cos(a),
        s = sin(a);
    return mat2(c, -s, s, c);
}

vec3 render(vec2 uv) {

    vec3 color = vec3(0.);
    vec2 p = uv;
    
    // per channel iters
    float t = T;
    for (int c = 0; c < 3; c++) {
    
        t += .1; // time offset per channel
        
        float l = 0.;
        float s = 1.;
        for (int i = 0; i < 8; i++) {
            // from Kali's fractal iteration
            p = abs(p) / dot(p, p);
            p -= s;
            p *= rotate(t * .5);
            s *= .8;
            l += (s  * .08) / length(p);
        }
        color[c] += l;
    
    }

    return color;

}

void main(void) {
    vec2 I = gl_FragCoord.xy;
    vec2 uv = (2. * I - R) / R.y;
    vec3 color = render(uv);
    glFragColor = vec4(color, 1.);
}
