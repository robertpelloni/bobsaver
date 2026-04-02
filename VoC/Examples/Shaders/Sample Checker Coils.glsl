#version 420

// original https://www.shadertoy.com/view/4tdcD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.141592654;

mat2 rotate(float angle) {
    return mat2(cos(angle), -sin(angle),
                   sin(angle), cos(angle));
}

// Thanks FabriceNeyret2

void main(void) {
    vec2 st = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;

    float size =10.;
    float f;

    
        st *= size;

 
    st *= cos(time) / 2. + .5 + 1.;
    
   float t1 = sin(time) * ceil(10.*sin(length(st)) / 2. + .5);
    
    st = rotate(t1/5.) * st;
    float p = sin(size*fract(atan(st.x, st.y)))/2. + .5;

    
    float l = length(st);
    float t = sin(time);
    
    
    l += smoothstep(.45, 0.5, p)*PI * t;
    f = smoothstep(0.476, -0.096, sin(l)/2. + .5);
        

    glFragColor = vec4(vec3(f),1.0);
}
