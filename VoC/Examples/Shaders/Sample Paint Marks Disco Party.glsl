#version 420

// original https://www.shadertoy.com/view/tdcSWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

vec2 rotate2D(vec2 st, float angle){
    st =  mat2(cos(angle),-sin(angle),
                sin(angle),cos(angle)) * st;
    return st;
}
vec2 tile(vec2 st, float zoom){
    st *= zoom;
    if (mod(st.x, 2.) < 1.){
        st = vec2(st.y, -st.x);
    }
    return fract(st);
}

float proceduralSplatter(vec2 st, float radius, float numCircles){
    float pct = 0.;
    st.x -= .5;
    for (float i = 1.; i < numCircles; i++){
        st.y -=(.3/ (i+1.));
        pct +=smoothstep(radius * 1./i, radius * 1./i - .1, length(st));
    }
    return pct;
}

void main(void) {
    vec2 st = gl_FragCoord.xy/resolution.xy;
    float aspect = resolution.x/resolution.y;
    st.x *= aspect;
    st += rotate2D(st, PI * .1 * time);
    vec3 color = vec3(sin(time / 2.));
    st += rotate2D(st, PI * .25);
    float time = time;
    vec2 grid2 = tile(st,2.);
    grid2.y -= .003;// * mouse.y*resolution.xy.y;
    color = mix(color, vec3(0.2,0.52,0.502 *(mouse*resolution.xy.x * .003)), proceduralSplatter(grid2, .2 , 10.));
    vec2 grid3 = tile(st, 3.);
    grid3 -= .1;
    color = mix(color, vec3(0.6, 0.3, 0.3), proceduralSplatter(grid3, .2 * sin(time), 9.));
    glFragColor = vec4(color,1.0);
}
