#version 420

// original https://www.shadertoy.com/view/tsycDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}

vec3 neon(in vec2 p, in float angle, in vec2 shift, in float size, in vec3 color) {
    p = rotate(angle)*(p-shift);
    float r = 6., // inner fill ratio
          r1 = 1./r,
          d = abs(p.y) / size, // base distance
          c = d * r, // core - fades r times faster
          b = d - r1; // border - starts +/- when core fades
    return color*smoothstep(1.,0.,b)+vec3(1)*smoothstep(1.,0.,c);
}

void main(void) {
    vec2 R = resolution.xy;
    float T = time;
    vec2 C = (gl_FragCoord.xy - .5 * R) / min(R.x, R.y);

    vec3 K1 = neon(C, -T, vec2(0.2*sin(T*2.), 0.3*sin(T*4.)), 0.2, vec3(1,0,0)),
         K2 = neon(C, T/2., vec2(0.2, 0.2), 0.2+0.04*sin(T*10.), vec3(0,1,0)),
         K3 = neon(C, T*2., vec2(-0.2, -0.2), 0.1, vec3(0,0,1)),
         K4 = neon(C, T, vec2(0, 0.5*sin(T*4.)), 0.2, vec3(1,1,0));
    glFragColor = vec4(K1+K2+K3+K4,1);
}
