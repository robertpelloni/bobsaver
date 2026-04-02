#version 420

// original https://www.shadertoy.com/view/WtlfW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define DEFAULT_SMOOTH 0.004
#define PI 3.14159265358979323846

float circle(vec2 c, vec2 p, float r, float s){
    return 1.0 - smoothstep(0.0, s, distance(c, p) - r);
}
float noise(vec2 n){
    return fract(dot(sin(n*1147.8976), vec2(9192.28, 1918.71))); 
}
float trueNoise(vec2 n){
    return noise(n * noise(n));
}
float angle(vec2 a, vec2 b){
    return dot(a, b)/(length(a) * length(b)) * (a.y > b.y ? 1.0 : -1.0);
}
float smoothNoisePane(vec2 n, float q){
    vec2 f = smoothstep(0.0, 1.0, fract(q * n));
    vec2 z = floor(q * n);
    float r1 = trueNoise(z + vec2(0.0, 0.0));
    float r2 = trueNoise(z + vec2(1.0, 0.0));
    float r3 = trueNoise(z + vec2(0.0, 1.0));
    float r4 = trueNoise(z + vec2(1.0, 1.0));
    float x = mix(mix(r1, r2, f.x), mix(r3, r4, f.x), f.y);
    return x;
}
float cloudNoise(vec2 ns){
    float col = 0.0;
    float q = 10.;
    col += smoothNoisePane(ns + vec2(7.32, 1.12), q) * 0.5;
    col += smoothNoisePane(ns + vec2(8.67, 2.03), q * 2.0) * 0.25;
    col += smoothNoisePane(ns + vec2(9.83, 3.56), q * 4.0) * 0.125;
    col += smoothNoisePane(ns + vec2(10.61, 4.83), q * 8.0) * 0.0625;
    return clamp(col, 0.0, 1.0);
}

vec3 gear(vec2 c, vec2 p, float ic, float rad, float d, float s, float off){
    float r = rad + 0.02 * pow(clamp(sin(off + time * s + d * PI * acos(angle(c - p,vec2(1.0, 0.0) ))), 0.0, 1.0), 0.2);
    float innerCircle = 1.0 - circle(c, p, ic , DEFAULT_SMOOTH);
    float dd = clamp(distance(c, p) * 2.5, 0.0, 1.0);
    float z = circle(c, p, r, DEFAULT_SMOOTH) * innerCircle;
    vec3 eng = vec3(1.0 - dd, 0.0, dd) * z * innerCircle;
    vec3 light = (0.25 + 0.05 * sin(time )) * circle(c, p, rad, 0.07) * vec3(0.8, 0.1, 0.7);
    return mix(vec3(1.0), vec3(dd, 0.0, 1.0 - dd) * z, cloudNoise(p)) * z + light;
}

void main(void)
{
    vec2 ns = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.x;
    ns *= 1.0;
    vec3 col = vec3(0.0);
    
    vec2 offset = vec2(sin(time * 10.), cos(time * 10.)) * 0.003;
  
    col += gear(vec2(0.225, 0.0) + offset, ns, 0.075, 0.1, 3.19, -20.0, 0.0);
    col += gear(vec2(-0.225, 0.0) + offset, ns, 0.075, 0.1, 3.19, -20.0, 0.0);
    col += gear(vec2(0.0, 0.0) + offset, ns, 0.075, 0.1, 3.19, 20.0, 0.0);
    
    col += gear(vec2(0.225, 0.225) + offset, ns, 0.075, 0.1, 3.19, 20.0, 0.0);
    col += gear(vec2(-0.225, 0.225) + offset, ns, 0.075, 0.1, 3.19, 20.0, 0.0);
    col += gear(vec2(0.0, 0.225) + offset, ns, 0.075, 0.1, 3.19, -20.0, 0.0);
    
    col += gear(vec2(0.225, -0.225) + offset, ns, 0.075, 0.1, 3.19, 20.0, 0.0);
    col += gear(vec2(-0.225, -0.225) + offset, ns, 0.075, 0.1, 3.19, 20.0, 0.0);
    col += gear(vec2(0.0, -0.225) + offset, ns, 0.075, 0.1, 3.19, -20.0, 0.0);
    
    col += gear(vec2(0.45, 0.225) + offset, ns, 0.075, 0.1, 3.19, -20.0, 0.0);
    col += gear(vec2(0.45, 0.0) + offset, ns, 0.075, 0.1, 3.19, 20.0, 0.0);
    col += gear(vec2(0.45, -0.225) + offset, ns, 0.075, 0.1, 3.19, -20.0, 0.0);
    
    col += gear(vec2(-0.45, 0.225) + offset, ns, 0.075, 0.1, 3.19, -20.0, 0.0);
    col += gear(vec2(-0.45, 0.0) + offset, ns, 0.075, 0.1, 3.19, 20.0, 0.0);
    col += gear(vec2(-0.45, -0.225) + offset, ns, 0.075, 0.1, 3.19, -20.0, 0.0);
    
    glFragColor = vec4(col, 1.0);
}
