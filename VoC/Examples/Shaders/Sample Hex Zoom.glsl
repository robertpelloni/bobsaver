#version 420

// original https://www.shadertoy.com/view/lsdXDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define TWO_PI 6.283185

// Matrix Transforms
// rotate matrix
mat2 rotate2d(float angle) {
    return mat2(cos(angle), -sin(angle),
                sin(angle),  cos(angle) );
}

// scale matrix
mat2 scale(vec2 scale) {
    return mat2(scale.x, 0,
                0, scale.y);
}

// Drawers
float polygonDistanceField(in vec2 st, in int vertices) {
    float a = atan(st.y, st.x) + PI/2.;
    float r = TWO_PI/float(vertices);
    // return shaping function that modulates the distances - distance field
    return cos(floor(0.5 + a/r) * r - a) * length(st);
}

// Mapping Function
float map(in float value, in float istart, in float istop, in float ostart, in float ostop) {
    return ostart + (ostop - ostart) * ((value - istart) / (istop - istart));
}

void main(void)
{
  float u_time = time;
  vec2 u_mouse = mouse*resolution.xy.xy;
  vec2 u_resolution = resolution.xy;
    
    vec3 color = vec3(0.2);
    
    float t = u_time;
    vec2 mouse_n = u_mouse.xy / u_resolution;

    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    st.x *= u_resolution.x / u_resolution.y; // quick aspect ratio fix

    // remap space to [-1.,1.]
    st = st * 2. - 1.;

    float r = .9;
    float polys = 0.;
    float tt = t*2.;
    for (float i=0.; i<1.0; i+=0.02) {
        // r = i;
        // MATRIX TRANSFORM
        float ms = map(mod(i+tt*0.05, 1.), 0., 1., 10., 0.);
        float z = map(i, 0., 1., 0., 5.);
        float mr_speed = map(ms, 10., 0., 0., 10.*sin(tt*0.05));
        float mr = i*mr_speed - tt*0.05;
        vec2 mst = st;
        mst = scale(vec2(ms)) * mst;
        mst = rotate2d(mr) * mst;
        // polygon
        float d = polygonDistanceField(mst, 6);
        float innerGlow = 0.; //map(ms, 10., 0., r-0.3, r-0.001);
        float polygon = smoothstep(r+0.001, r, d) - smoothstep(r, innerGlow, d);
        // add
        polys += polygon*0.1;
        // polys = max(polys, polygon*.8);
    }

    float d = polygonDistanceField(st, 3);
    r = 0.01;
    float poly = smoothstep(0.03, 0., d);// - smoothstep(r, , d);
    polys += poly;
    
    color = vec3(0.9,0.6,0.4) * polys;
    // color = vec3(polys);

    // Render Color
    glFragColor =  vec4(color, 1.0);
}
