#version 420

// original https://www.shadertoy.com/view/4tXBzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define RAD (3.1415/180.0)

void rot(inout vec2 p, float rad) {
 p *= mat2(
     cos(rad),
     -sin(rad),
     sin(rad),
     cos(rad));
}

vec4 shapes(vec2 p) {
return vec4(
    smoothstep(0.0, 0.01, p),
    smoothstep(0.0, 0.01, p).y,
    1.0);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.y;
    vec2 mouse = mouse*resolution.xy.xy / resolution.y;
    float sc = 7.0 - abs(sin(time*3.14159/15.)*3.0);
    vec2 p = uv*sc - mouse * sc + 0.5;
    rot(p, sin(cos(time/ 20.0)));
    //if (p.x > 1.0 || p.x < 0.0 || p.y < 0.0 || p.y > 1.0) { glFragColor = vec4(0.3, 0.2, 1.0, 1.0); return; }
    vec2 reflect = vec2(1.0);
    if (mod(p.x, 2.0) > 1.0) {
        reflect.x = -1.0;
    } if (mod(p.y, 2.0) > 1.0) {
        reflect.y = -1.0;
    }
    p = fract(p) - 0.5;
    p *= reflect;
    rot(p, time);
    vec4 c = shapes(p); 
    for (int i = 0; i < 4; i++) {
    rot(p, radians(15.0));
    c = mix(c, shapes(p), 0.4);
    }
    glFragColor=c;
}
