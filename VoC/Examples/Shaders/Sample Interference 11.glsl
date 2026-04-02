#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlXGDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 moire(in vec2 p) {
    float t = time;
    const int ringwidth = 4;
    const float a = 0.6, b = 0.5;
    vec2 focus1 = vec2(a*cos(t/2.)+b, a*sin(t/4.)+b);
    vec2 focus2 = vec2(a*cos(t/3.)+b, a*sin(t)+b);

    int interf = int(100.*distance(p,focus1)) ^ int(100.*distance(p,focus2));
    interf /= ringwidth;
    interf %= 2;
    
    if (interf == 0)
        return vec4(vec3(0.),1.);
    else
        return vec4(1.);
}

void main(void) {
    vec2 p = 2.*gl_FragCoord.xy/resolution.xy - 0.5;
    
    glFragColor = moire(p);
}
