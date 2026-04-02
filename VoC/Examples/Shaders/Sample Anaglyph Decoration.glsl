#version 420

// original https://www.shadertoy.com/view/td3SDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Anaglyph Decoration
// Framed for https://fanzine.cookie.paris/
// Licensed under hippie love conspiracy
// Leon Denise (ponk) 2019.10.24
// Using code from Inigo Quilez

#define time 0.0

mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }
float random (in vec2 st) { return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123); }

vec3 look (vec3 eye, vec3 target, vec2 anchor) {
    vec3 forward = normalize(target-eye);
    vec3 right = normalize(cross(forward, vec3(0,1,0)));
    vec3 up = normalize(cross(right, forward));
    return normalize(forward * .75 + right * anchor.x + up * anchor.y);
}

float map (vec3 pos) {
    vec3 p = pos;
    float scene = 10.0;
    float r = 1.0;
    const float count = 9.0;
    for (float index = count; index > 0.0; --index) {
        pos.xz = abs(pos.xz)-1.4*r;
        pos.yx *= rot(3.9/r + time * 0.3);
        pos.yz *= rot(0.5/r + time * 0.2);
        pos.xz *= rot(0.2/r + time * 0.1);
        scene = min(scene, abs(max(pos.x, max(pos.y, pos.z))));
        r /= 1.8;
    }
    scene = max(abs(p.z)-1., scene);
    scene = max(-length(p.xy)-p.z*.5, scene);
    return scene;
}

vec4 raymarch (vec3 eye, vec3 ray) {
    float dither = random(ray.xy+fract(time));
    vec4 result = vec4(eye, 0);
    float total = 0.1 * dither;
    float maxt = 20.0;
    const float count = 30.;
    for (float index = count; index > 0.0; --index) {
        result.xyz = eye + ray * total;
        float dist = map(result.xyz);
        if (dist < 0.001 + total * .001 || total > maxt) {
            result.w = index / count;
            break;
        }
        dist *= 0.7 + 0.1 * dither;
        total += dist;
    }
    result.w *= step(total, maxt);
    return result;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 eye = vec3(.2,.1,-2.);
    vec3 at = vec3(0);
    vec3 ray = look(eye, at, uv);
    vec3 eyeoffset = 0.02*normalize(cross(normalize(at-eye), vec3(0,1,0)));
    vec4 resultLeft = raymarch(eye-eyeoffset, ray);
    vec4 resultRight = raymarch(eye+eyeoffset, ray);
    glFragColor = vec4(resultLeft.w,vec2(resultRight.w),1);
}
