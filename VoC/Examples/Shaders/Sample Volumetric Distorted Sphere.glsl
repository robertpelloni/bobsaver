#version 420

// original https://www.shadertoy.com/view/WtXcWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = acos(-1.0);

// _ _ _
//  _ _ 
//
float square(float x) { return sign(sin(x * PI)) * 0.5 + 0.5; }
//
// /_/_/
//
//float ramps(float x) { return mod(x,1.0)*square(x); }
// 
// S_S_S
//
float ramps(float x) { return smoothstep(0.0,1.0,mod(x,1.0)*square(x)); }
//
//    _/
//  _/
// /
//
float linear_steps(float x) { return floor(x / 2.0 + 0.5) + ramps(x); }

float sphere(vec3 o, float r) { return length(o) - r; }

float cylinder(vec3 o, float r) { return length(o.xz) - r; }

mat2 rotate(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

vec3 fetch(vec3 o) {
//    float deform = linear_steps(time + 1.5) * 2.0;
    float deform = time / 0.35;
    o.yz *= rotate(linear_steps(time + 1.0) * PI / 4.0);
    o.xy *= rotate(linear_steps(time + 0.5) * PI / 4.0);
    o.zx *= rotate(linear_steps(time) * PI / 4.0);
    o.z += 0.1 * sin(o.y * 10.0 + deform);
    o.x += 0.1 * sin(o.z * 10.0 + deform);
    o.y += 0.1 * sin(o.x * 10.0 + deform);
    
    float object = sphere(o, 0.5);
    if (object < 0.0) {
        vec3 color = vec3((sin(o.x * 10.0 + time) + 1.0) * 0.02 + 0.01,(sin(o.y * 10.0 + time) + 1.0) * 0.01 + 0.02,(sin(o.z * 10.0 + time) + 1.0) * 0.01 + 0.01);
        color /= 4.0;
        return color;
    } else {
         return vec3(0.0);
    }
}

void main(void) {
    vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 light = vec3(0.0);

    vec3 o = vec3(0.0,0.0,-1.0);
    vec3 d = normalize(vec3(p.xy, 2.0));
    
    float t = 0.0;
    for (int i = 0; i < 200; i++) {
        t += 0.01;
        light += fetch(d * t + o);
    }
//    light = vec3(linear_steps(p.x * 10.0)/10.0);
    glFragColor = vec4(light,1.0);
}
