#version 420

// original https://www.shadertoy.com/view/WltyDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi2 = acos(-1.)*2.;

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float smoothFloor(float x, float s) {
    return floor(x-.5)+smoothstep(.5-s, .5+s, fract(x-.5));
}

float rand(float x) {
    float r = fract(sin(x)*43758.5453);
    float t = smoothFloor(time, .2);
    r = sin(r*pi2 + t)*.5+.5;
    return r;
}

float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.-2.*f);
    vec3 b = vec3(173, 61, 3);
    float n = dot(p, b);
    return mix(    mix(       mix(rand(n), rand(n+b.x), f.x),
                           mix(rand(n+b.y), rand(n+b.x+b.y), f.x),
                           f.y),
                   mix(    mix(rand(n+b.z), rand(n+b.x+b.z), f.x),
                           mix(rand(n+b.y+b.z), rand(n+b.x+b.y+b.z), f.x),
                           f.y),
                   f.z);
}

float dist(vec3 p) {
    float d = length(p.xy)-1.;
    return max(noise(p)-.2, -d);
}

vec3 hsv2rgb(float h, float s, float v) {
    vec3 res = fract(h+vec3(0,2,1)/3.);
    res = abs(res*6.-3.)-1.;
    res = clamp(res, 0., 1.);
    res = (res-1.)*s+1.;
    res *= v;
    return res;
}

float exp2Fog(float d, float density) {
    float s = d*density;
    return exp(-s*s);
}

void main(void) {
    vec2 p = (gl_FragCoord.xy*2.-resolution.xy) / min(resolution.x, resolution.y);
    vec3 col = vec3(0);
    
    vec3 cPos = vec3(0, 0, -time*3.);
    vec3 cDir = vec3(0.2, 0, -1);
    cDir.xy *= rotate(time*.1);
    
    vec3 cUp = vec3(0, 1, 0);
    cUp.xy *= rotate(time*-.1);
    
    vec3 cSide = cross(cDir, cUp);
    vec3 ray = normalize(p.x*cSide + p.y*cUp + cDir*2.5);
    
    float d = 0.;
    vec3 rPos = cPos;
    for(int i=0; i<150; i++) {
        d = dist(rPos);
        if(abs(d) < 0.01) {
            float r = noise(rPos+vec3(10));
            vec3 base = hsv2rgb(r*.3+floor(time)*pi2, .5, 1.);
            col = base/float(i)*20.;
            break;
        }
        rPos += ray*d;
    }
    float fog = exp2Fog(length(rPos-cPos), 0.03);
    col = mix(vec3(1), col, fog);
    
    glFragColor = vec4(col, 1.);
}
