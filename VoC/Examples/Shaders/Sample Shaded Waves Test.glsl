#version 420

// original https://www.shadertoy.com/view/Xl3fR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Based on: http://glslsandbox.com/e#45318.16
*/
#define R resolution.xy
#define T time

// toggle to move light
#define ANIMATE_LIGHT 1 

const mat2 rot = mat2(.707, .707, -.707, .707);

// simple wave function
float wave(vec2 uv) {
    float t = sin(uv.x + cos(uv.y));
    return t * t;
}

float map(vec2 uv) {
    
    float t = 0.;
    float s = 1.;
           
    // layer waves -> rotate, translate and scale
    for (float i = 0.; i < 1.; i += .2) {
        
        uv *= rot;
        uv.y += T * .2;
        t += wave(uv * i * 1.5);
        
        uv *= vec2(2., 1.25);
    
    }
    
    return abs(2. - t);

}

void main(void) {

    vec2 I = gl_FragCoord.xy;
    vec4 O;

    vec2 uv = (2. * I - R) / R.y;    
    vec3 col = vec3(0.);
    
    uv *= 1.5;
    float m = map(uv);
    
    col += vec3(m * .25, 0., .1); // base color
    
    // normal calc via gradient 
    // only need to do for x and y components
    // z component will always point in one direction
    vec2 o = vec2(.01, 0.);
    vec3 n = normalize(vec3(m - map(uv + o.xy), 
                m - map(uv + o.yx), -o.x));
     
    // phong lighting
#if ANIMATE_LIGHT
    vec3 l = normalize(vec3(cos(T * .5), sin(T * .5), -1.5));
#else
    vec3 l = normalize(vec3(1., 0., -1.5));
#endif

    float diff = max(dot(n, l), 0.);
    float spec = pow(.5 * max(dot(n, l), 0.), 8.);
    
    col += diff + spec;

    O = vec4(col, 1.);

    glFragColor = O;

}
