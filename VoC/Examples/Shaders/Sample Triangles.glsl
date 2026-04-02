#version 420

// original https://neort.io/art/bpicv7k3p9fbkbq82png

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

const float PI2 = 6.28318530718;

vec2 rotate(vec2 st, float angle){
    mat2 mat = mat2(cos(angle), -sin(angle),
                    sin(angle),  cos(angle));
    return mat*st;
}

// https://thebookofshaders.com/07/?lan=jp
float tri(vec2 st, int n){
    float a = atan(st.x, st.y)+PI2/2.0;
    float r = PI2/float(n);
    return cos(floor(0.5+a/r)*r-a)*length(st);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec3 col = vec3(0.0);

    vec2 offs = vec2(-sin(time), cos(time))*0.05;
    uv += offs;

    float depth = fract(time*0.125);
    float scale = mix(0.95, 0.0001, depth);

    uv *= scale;
    
    float s = mod(floor(time*5.)*0.05, 2.0)+0.01;
    for(float i=0.0; i<=2.0; i+=0.1){
        vec2 uvroll = rotate(uv, (PI2-i + time*0.2));
        float t = tri(uvroll,3);
        float tI = smoothstep(0.40, t, 0.41);
        col += s>i ? vec3(tI) : vec3(0.0);
        uv *= 1.0+i*0.5;
    }

    glFragColor = vec4(col, 1.0);
}
