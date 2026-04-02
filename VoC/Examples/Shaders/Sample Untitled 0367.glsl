#version 420

/*
    @machine_shaman
*/

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 1

#define STEP t += .5 * (length(mod((vec3(1., 0., time * 1.) + vec3(uv, 1.) * t) + 1., 2.) - 1.) - .5)
#define STEP_8 STEP; STEP; STEP; STEP; STEP; STEP; STEP; STEP
#define STEP_32 STEP_8; STEP_8; STEP_8; STEP_8;
#define STEP_64 STEP_32; STEP_32
#define STEP_128 STEP_64; STEP_64
#define STEP_256 STEP_128; STEP_128

float render(vec2 uv) {
        
    float c = cos(time / 10.);
    float s = sin(time / 10.);
    mat2 rot = mat2(c, s, -s, c);
    uv *= rot;
    
    float _s = 0.01;
    for (int i = 0; i < 4; i++) {
        uv = abs(uv) - _s;
        uv *= rot;
        _s *= 0.95;
    }
    
    float t = 0.;
    STEP_64;
    //STEP_256;
    return 1. - 3. / t;

}

void main() {

    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    vec3 col = vec3(0.);

#if AA
    for (float i = -1.0; i <= 1.0; i++) {
        for (float j = -1.0; j <= 1.0; j++) {
            col += render(uv - vec2(i, j) / resolution);
        }
    }
    col /= 9.;
#else
    col = vec3(render(uv));    
#endif
    
        
    glFragColor = vec4(col, 1.);

}
