#version 420

// original https://www.shadertoy.com/view/MdVBzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// rotate
mat3 rotate(float a) {
    return mat3(
         cos(a), sin(a), 0,
          -sin(a), cos(a), 0,
         0, 0, 1
    );
}

// translate
mat3 translate(float x, float y) {
    return mat3(
         1, 0, x,
         0, 1, y,
         0, 0, 1
    );
}

// recalc coord space
vec2 resizeViewportFractTransform(float size, vec2 coord, vec2 resolution, mat3 matrix) {
    vec2 st = coord / resolution;
    st *= size;
       st = (matrix * vec3(st, 1.)).xy;
    st = fract(st);
    st *= 2.0;
    st -= 1.0;
    st.x *= resolution.x / resolution.y;
    return st;
}

// recalc coord space
vec2 resizeViewportFract(float size, vec2 coord, vec2 resolution) {
    vec2 st = coord / resolution;
    st *= size;
       st = fract(st);
    st *= 2.0;
    st -= 1.0;
    st.x *= resolution.x / resolution.y;
    return st;
}

// recalc coord space
vec2 resizeViewport(vec2 coord, vec2 resolution) {
    vec2 st = coord / resolution;
    st *= 2.0;
    st -= 1.0;
    st.x *= resolution.x / resolution.y;
    return st;
}

// spiral function 
float spiral(vec2 st, float a, float r, float t, float d) {
    float arms = atan(st.x, st.y) * a;
    float rings = length(st) * r;
    return sin(arms + (d * (rings + t)));
}

// flower function
float flower(vec2 st, float a, float r, float t) {
    return 
        spiral(st, a, r, t,  1.0) *
        spiral(st, a, r, t, -1.0);
}

// main image
void main(void) {

    // rename for easier input
    vec2 resolution = resolution.xy;
    vec2 mouse = mouse*resolution.xy.xy;
       float time = time;
    
    // init parameters
    vec3 color;

    // create the shape
    // transforms
    mat3 transforms = translate(mouse.x, mouse.y);

    
    // resize the uv coord
    vec2 st = resizeViewportFractTransform(4., gl_FragCoord.xy, resolution, transforms);
    
    // create the piral
    float t = time;
    for (int i = 0; i < 3; i++) {
        t += flower(
            st,
            6., 
            6.,
            t
        );
        color[i] = flower(
            st, 
            6.0,
            6.0 * flower(st, 3., 3., t), 
            t
        );         
    } 
    
    // output color
    vec3 final = color;
    glFragColor = vec4(final, 1.0);
    
    
}
