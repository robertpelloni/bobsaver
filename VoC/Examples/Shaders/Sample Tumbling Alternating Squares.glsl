#version 420

// original https://www.shadertoy.com/view/3dVBDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

uniform vec2 u_resolution;
uniform float u_time;

#define PI 3.14159265358979323846

vec2 rotate2D(vec2 st, float angle){
    st -= 0.5;
    st =  mat2(cos(angle),-sin(angle),
                sin(angle),cos(angle)) * st;
    st += 0.5;
    return st;
}

vec2 tile(vec2 st, float zoom,float rotD){
    st *= zoom;
     if(rotD==1.) {
        st.x+=.5;
        st.y+=.5;
     }
    return fract(st);
}

float square(vec2 st, vec2 side){
    vec2 border = vec2(0.5)-side*0.5;
    vec2 pq = smoothstep(border,border+.01,st);
    pq *= smoothstep(border,border+.01,vec2(1.0)-st);
    return pq.x*pq.y;
}
void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.y;
    float color;
    float Nsquares=5.;
    float rotDirection=0.;
    float warpedTime = time * 0.5 + uv.x + uv.y * 0.5;
    rotDirection=step(0.,sin(warpedTime * 2.0));
    
    uv = tile(uv,Nsquares,rotDirection);
    uv = rotate2D(uv,PI/4.0-warpedTime);
    if (rotDirection==1.)
        color = 1.0-square(uv,vec2(0.71));
    else 
    color=square(uv,vec2(0.72));
    glFragColor = vec4(vec3(color),1.0);
} 
