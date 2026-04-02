#version 420

// original https://www.shadertoy.com/view/WlSXWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
    p.x = sin(p.x);
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
}

float n(vec2 p, float s) {
    float o = s / resolution.x;
    return (noise(p + vec2(o, 0.)) + noise(p + vec2(0., o)) + noise(p + vec2(-o, 0.)) + noise(p + vec2(0., -o))) / 4.;
}

void main(void)
{
    vec2 c = (gl_FragCoord.xy / resolution.xy - vec2(0.5)) * 0.25;
    float l = length(c);
    float s = pow(0.5, 1. / time) * 0.5;
    float t = atan(c.y, c.x);
    vec2 p = vec2(t, pow(2., l * 10.) / s + time);
    float e = 1. - smoothstep(s - .01, s, l);
    
    glFragColor = vec4(n(p * 8., l * 100000.) * e);
}
