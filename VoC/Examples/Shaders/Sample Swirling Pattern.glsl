#version 420

// original https://neort.io/art/bobrsnk3p9fd1q8obd6g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float PI = acos(-1.0);

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2( c, -s, s, c);
}

vec3 tex(vec2 st, vec2 id){
    st *= rotate(PI/3.55);
    st *= 2.5;

    float f = length(st.y) + length(st.x);
    float a = length(id.y) + length(id.x);;
    float at = atan(st.y, st.x);

    return vec3(sin(a + a + f + f + at - time * 5.0),sin(a + a + f + f + at - time),sin(a + f + at - time));
}

void main() {
    vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

    st *= rotate(PI/4.0);
    st *= 15.0;

    vec2 rst = mod(st,2.0);
    rst -= 1.0;

    vec2 id = rst - st;

    vec3 color = tex(rst,id);
    color *= vec3(0.7,0.4,0.8);
    glFragColor = vec4(color, 1.0);
}
