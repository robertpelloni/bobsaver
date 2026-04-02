#version 420

// original https://neort.io/art/br8ct0s3p9f04urh846g

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

// 2D rotate
mat2 rotate(in float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, s, -s, c);
}

void main(void){
    // Wide-angle lens is baced on Menger Sponge Variation
    // https://www.shadertoy.com/view/ldyGWm
    vec3 st = (vec3(2.0 * gl_FragCoord.xy - resolution.xy, resolution.y));
    st = normalize(vec3(st.xy, sqrt(max(st.z * st.z - dot(st.xy, st.xy) *2.,0.))));
    st.xy *= rotate(time*0.1);
   
    st *= 21.*abs(1.1 + sin(time*0.3));
    
    float len;
    for (int i = 0; i < 10; i++) {
        len = length(st);
        st.x +=  sin(st.y + time * 0.3)*1.;
        st.y +=  cos(st.x + time * 1.0 + cos(len * 1.0))*1.;
    }
    
    vec3 color = cos(len + vec3(0.2,0.1,-0.05));
    glFragColor = vec4(color, 1.0);
}
