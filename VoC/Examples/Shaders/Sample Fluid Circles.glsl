#version 420

// original https://www.shadertoy.com/view/NtfyDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define ths(a,b) tanh(a*sin(b))/tanh(a)
#define sabs(x) sqrt(x*x+0.0001)
//#define sabs(x, k) sqrt(x*x+k)-0.1

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))

float cc(float a, float b) {
    float f = thc(a, b);
    return sign(f) * pow(abs(f), 0.25);
}

float cs(float a, float b) {
    float f = ths(a, b);
    return sign(f) * pow(abs(f), 0.25);
}

vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b*cos( 6.28318*(c*t+d) );
}

float h21(vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float mlength(vec2 uv) {
    return max(abs(uv.x), abs(uv.y));
}

float mlength(vec3 uv) {
    return max(max(abs(uv.x), abs(uv.y)), abs(uv.z));
}

float smin(float a, float b)
{
    float k = 0.03;
    float h = clamp(0.5 + 0.5 * (b-a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float cc(float a, float b, float c) {
    float f = thc(a,b);
    return sign(f) * pow(abs(f), c);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    uv.y += 0.03 * cos(time);
    float d = 1e5;
    
    vec2 p = vec2(0);
    for (float i = -1.; i < 20.; i++) {
        float t = 4.5 * pi * i / 20. - 0.6 * time;
        float pw = (32. + 16. * cos(pi * i + time)) / length(uv);
        vec2 q = 0.35 * vec2(cc(4., t, pw), cc(4., pi/2. - t, pw));
        
        vec2 m = 0.5 * (p + q);
        float ci = abs(length(uv - m) - 0.5 * length(p-q));
        
        if (i > -1.) d = min(d, ci);
        p = q;
    }
    
    float k = 0.75 / resolution.y;
    float s = smoothstep(-k, k, -d + 0.01);
    
    vec3 col = vec3(s);
    
    glFragColor = vec4(col,1.0);
}
