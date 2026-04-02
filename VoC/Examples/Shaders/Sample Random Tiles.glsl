#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/lsXBD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float floor_dist = 2.;
const float speed = 4.;

const int nvdr[256] = int[256](
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,
    0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,
    0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,
    0,0,0,1,1,0,1,1,1,0,1,1,0,0,0,0,
    0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,
    0,0,1,0,1,1,1,1,1,1,1,0,1,0,0,0,
    0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,
    0,0,0,0,0,1,1,0,1,1,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
);

vec2 rot(vec2 v, float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a)) * v;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = 2.*uv - 1.; // Center coordinates
    uv.y *= resolution.y / resolution.x; // Fix display form factor
    uv.xy = rot(uv.xy, sin(time)/2.);
    
    vec3 dir = normalize(vec3(uv, -1.));
    float dst = abs(floor_dist/dir.y);
    vec3 pos = vec3(0., 0., -1.) + dir * dst;
    pos.z -= speed * time;
    vec3 posf = fract(pos);
    vec3 posi = floor(pos);
    
    float fcol;
    vec4 vcol;
    int tind = (int(-posi.z)%16)*16 + (int(posi.x)+8)%16;
    if (nvdr[tind] == 1) {
        vcol = vec4(0.7,1.,1.,0.);
    } else {
        fcol = fract((posi.x+123.)*.546 * (posi.z+789.)*.123);
        vcol = vec4(fcol/2.,0.2,0.2,0.);
    }
    vcol = vcol*1.7/exp(dst/15.); // Fog
    if (posf.x < .8 && posf.z < .8) {
        glFragColor = vcol;
    } else {
        glFragColor = vec4(0.0);
    }
}
