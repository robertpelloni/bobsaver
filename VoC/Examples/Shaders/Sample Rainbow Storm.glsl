#version 420

// original https://www.shadertoy.com/view/ftd3zH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159
#define rot(t) mat2(cos(t), -sin(t), sin(t), cos(t))

// color hue based on IQ's palettes
vec3 col(float t) {
    return 0.5+0.5*cos(2.0*pi*(t+vec3(0, 0.33, 0.67)));
}

// random number between 0 and 1
float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.543,514.123)))*4732.12);
}

// value noise
float noise(vec2 p) {
    vec2 f = smoothstep(0.0, 1.0, fract(p));
    vec2 i = floor(p);
    float a = rand(i);
    float b = rand(i+vec2(1.0,0.0));
    float c = rand(i+vec2(0.0,1.0));
    float d = rand(i+vec2(1.0,1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
    
}

// fractal noise
float fbm(vec2 p) {
    float a = 0.5;
    float r = 0.0;
    for (int i = 0; i < 8; i++) {
        r += a*noise(p);
        a *= 0.5;
        p *= 2.0;
    }
    return r;
}

// main effect
vec4 eff(vec2 uv) {
    uv *= 10.0;
    uv *= rot(length(0.1*uv)*1.25);
    uv.y -= time*0.75;
    return vec4(col(3.0*fbm(uv/4.0+time*0.1+fbm(2.5*uv-time*0.1+fbm(uv/10.0)))), 1.0);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.y;
    uv -= resolution.xy/resolution.y/2.0;
    vec4 col = eff(uv);
    float aberration = 1.015 + 0.2*smoothstep(-1.0, 1.0, sin(0.25*time));
    col.r = eff(uv/aberration).r;
    col.b = eff(uv*aberration).b;
    glFragColor = col;
}
