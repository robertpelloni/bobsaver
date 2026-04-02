#version 420

// original https://www.shadertoy.com/view/7tlcz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define ths(a,b) tanh(a*sin(b))/tanh(a)
#define sabs(x) sqrt(x*x+1e-2)
//#define sabs(x, k) sqrt(x*x+k)-0.1

#define Rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

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

float smin(float a, float b) {
    float k = 0.12;
    float h = clamp(0.5 + 0.5 * (b-a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    vec2 ouv = uv;
    uv = vec2(3.5 * atan(uv.x,uv.y), length(uv));
    uv.y = pow(uv.y+0.5, 0.125);
    uv.y *= 50.;
    uv.y += -time - 12.5 * uv.x / uv.y;
    
    
    vec2 ipos = floor(uv) + 0.;
    vec2 fpos = fract(uv) - 0.5;
    
    float n = 11.;
    float s = mod(0.25 * n * time + (n-3.) * ipos.x + (n-1.) * ipos.y, n) / n;
    
    vec3 col = vec3(s);
    col *= 0.92 + 0.08 * h21(floor(10. * uv));
    col *= pal(0.125 * n, col, col, col, 0.6 * vec3(0,1,2)/3.);
    col = sqrt(col + 0.02);
    float k = 8. / resolution.y;
    col *= smoothstep(-k, k, -mlength(fpos) + 0.47);
    
    col *= 1.-exp(-10. * length(ouv));
    glFragColor = vec4(col,1.0);
}
