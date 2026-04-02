#version 420

// original https://neort.io/art/bt95ffc3p9f8mi6u8otg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float pi = acos(-1.0);

// atan2
// https://qiita.com/7CIT/items/ad76cfa6771641951d31
float atan2(in float y, in float x){
    return x == 0.0 ? sign(y)*pi/2. : atan(y, x);
}

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 pmod(vec2 p, float n) {
    float a = 2.0 * pi / n;
    float theta = atan2(p.y, p.x) + a * 0.5;
    theta = floor(theta / a) * a;
    return p * rotate(-theta);
}

float rand(float x) {
    return fract(sin(x) * 43758.5453);
}

vec3 hsv2rgb(vec3 hsv) {
    return ((clamp(abs(fract(hsv.x+vec3(0,2,1)/3.)*6.-3.)-1.,0.,1.)-1.)*hsv.y+1.)*hsv.z;
}

void main( void ) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0);
    
    vec2 z;
    
    float t = time * 1.0;
    z = p;
    
    z = pmod(z, 6.0);
    z.x -= abs(sin(t)) * 0.5;
    z = pmod(z, 6.0);
    z.x -= abs(sin(t)) * 0.5;
    
    for(float i=0.; i<20.; i++) {
        z *= rotate(2.0 * pi * i / 10.0 + t);
        z = pmod(z, 6.0);
        z.x -= sqrt(i) / 6.0 * abs(sin(t));
        z = pmod(z, 6.0);
        color += hsv2rgb(vec3(sin((z.x + t * 0.1) * 20.0) * 0.1 + 0.2 + rand(i + floor(t * 10.0)), 1.0, smoothstep(0.1, 0.05, z.x)));
    }
    
    glFragColor = vec4(color, 1.0);
}
