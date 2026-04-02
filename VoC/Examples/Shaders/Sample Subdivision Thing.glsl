#version 420

// original https://www.shadertoy.com/view/NtByRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define ths(a,b) tanh(a*sin(b))/tanh(a)
#define sabs(x) sqrt(x*x)
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

float bum(float sc, vec2 ipos) {
    return 0.5 * mod(pi * (ipos.y * cos(sc * ipos.x) 
                         + ipos.x * cos(sc * ipos.y)), 2.);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;   
    uv += vec2(30., 10.);

    float sc = pi;
    
    float si = 0.1 * uv.x;
    vec2 ipos;
    
    float b = 1.;
    float n = 10.;
    for (float i = 0.; i < n; i++) {
        float io = 2. * pi * i / n;
        uv *= 1. + 0.009 * cos(io + 0.1 * time + 4. * pi * b);
       // uv *= Rot(1. * b * pi);
        ipos = floor(si * uv);
        b = mix(b, bum(sc, ipos), 0.5);
    }
             
    vec3 e = vec3(0.5);
    vec3 col = vec3(b);
    col = (0.5 + 0.5 * cos(200. * pi * b)) - pal(5. * pow(4. * b * (1.-b),2.), e, e, e, 0.5 * vec3(0,1,2)/3.); 
    col = sqrt(0.4 - col) + 0.1;
    col = mix(col, abs(b-col), h21(ipos));
    glFragColor = vec4(col,1.0);
}
