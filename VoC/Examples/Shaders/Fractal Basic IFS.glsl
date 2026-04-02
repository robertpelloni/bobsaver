#version 420

// original https://www.shadertoy.com/view/3l3cz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://darkeclipz.blogspot.com/2020/12/iterated-function-systems-ifs.html 

#define PI 3.14159265358979323846264
#define MOUSE_DOWN (mouse*resolution.xy.z > 0.)
#define SS 4.
#define R resolution.xy

float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12454.1,78345.2))) * 43758.5);
}

vec2 random2(in vec2 st) {
    return vec2(random(st), random(st));    
}

vec2 ifs(vec2 p, float s, float r, int n) {
    float co = cos(r), si = sin(r);
    mat2 rot = mat2(co, si, -si, co);
    for(int i=0; i < n; i++) {
        p.x = abs(p.x);
        p -= vec2(1.0, 0);
        p *= rot;
        p *= s;
    }
    return p;
}

void main(void)
{
    vec3 col = vec3(0);
    float px = 1. / resolution.y;
    for(float i=0.; i < SS; i++) {
        vec2 uv = 5.5 * (2.*(gl_FragCoord.xy + random2(R+i)) - R) / R.y;
        float s = 1.11; //MOUSE_DOWN ? 1.11 + (mouse*resolution.xy.y / resolution.y - 0.5) * 0.1 : 1.11;
        float r = 2.*PI*fract((time + 20.2*2.)/100.); //MOUSE_DOWN ? PI / 2. + mouse*resolution.xy.x / resolution.x * 2. * PI : 2.*PI*fract((time + 20.2*2.)/100.);
        uv = ifs(uv, s, r, 24);
        uv = ifs(uv, 1.17, PI/2., 8);
        float ds = 0.5;
        col += vec3(1) * smoothstep(ds, ds-16.*px, length(uv));
    }
    glFragColor = vec4(col / SS, 1.0);
}
