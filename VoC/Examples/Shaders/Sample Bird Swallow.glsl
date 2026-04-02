#version 420

// original https://www.shadertoy.com/view/NsVGWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415

vec2 rotate(vec2 p, float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c, s, -s, c) * p;
}

float smoothMin(float a, float b, float k) {
    return -log2(exp2(-k * a) + exp2(-k * b)) / k;
}

float sdf(float d) {
    return smoothstep(0., fwidth(d) * 1.5, d);
}

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdLine(vec2 p, vec2 a, vec2 b){
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
    return length(pa - ba * h);
}

void sdWing(vec2 q, inout float d) {
    float f1 = 5. * smoothstep(-0.9, 1.1, sin(time * 1.5));
    float f2 = (sin(time * 18.) + 1.) * 1.5;

    q = rotate(q, ((f1 * f2) / 19.) + PI / 2.02);
    q.x -= sin(q.y * 22. + 1.5) * 0.01;
    float d1 = sdLine(q, vec2(0., -0.45), vec2(0)) - 0.05 * smoothstep(-0.23, 0., q.y);
    d = min(d, d1);
}

void sdTail(vec2 q, inout float d) {
    float f = 5. * smoothstep(0.8, -1.9, sin(time*1.5));

    q = rotate(q, f / 30. + PI / 2.25);
    q.x -= sin(q.y * 7. + 1.) * 0.005 + sin(q.y * 15.) * 0.003;
    float d1 = sdLine(q, vec2(0., -0.35), vec2(0)) - 0.035 * smoothstep(-0.23, 0., q.y);
    d = min(d, d1);
}

float sdHead(vec2 p) {
    float d, d1;
    
    // head
    vec2 q = p - vec2(0.17, -0.045);
    d = sdCircle(q, 0.045);
    
    q = p - vec2(0.205, -0.0415);
    d1 = sdCircle(q, 0.03);
    d = smoothMin(d, d1, 180.);
    
    // nose
    q = p - vec2(0.2125, -0.055);
    q = rotate(q, -PI / 3.5);
    q.x -= sin(q.y * 0.01 + 1.) * 0.005 + sin(q.y * 0.01) * 0.005;
    d1 = sdLine(q, vec2(0., -0.03), vec2(0)) - 0.0175 * smoothstep(-0.03, 0., q.y);
    d = min(d, d1);
    
    // eye
    q = p - vec2(0.21, -0.05);
    d1 = sdCircle(q, 0.0075);
    d = max(d, -d1);
    
    return d;
}
    
float sdBird(vec2 p) {
    float d, d1;
    
    // head
    vec2 q = p - vec2(0.17, -0.045);
    d = sdCircle(q, 0.045);
    
    q = p - vec2(0.205, -0.0415);
    d1 = sdCircle(q, 0.03);
    d = smoothMin(d, d1, 180.);
    
    // nose
    q = p - vec2(0.2125, -0.055);
    q = rotate(q, -PI / 3.5);
    q.x -= sin(q.y * 0.01 + 1.) * 0.005 + sin(q.y * 0.01) * 0.005;
    d1 = sdLine(q, vec2(0., -0.03), vec2(0)) - 0.0175 * smoothstep(-0.03, 0., q.y);
    d = min(d, d1);
    
    // eye
    q = p - vec2(0.21, -0.05);
    d1 = sdCircle(q, 0.0075);
    d = max(d, -d1);
    
    // tail
    q = p - vec2(0.08, -0.045);
    sdTail(q, d);
    
    q = p - vec2(0.08, -0.05);
    q.y *= -1.;
    sdTail(q, d);
    
    // wings
    q = p - vec2(0.105, -0.015);
    sdWing(q, d);
    
    q = p - vec2(0.105, -0.075);
    q.y *= -1.;
    sdWing(q, d);

    return d;
}

vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x * 6. + vec3(0., 4., 2.), 6.) - 3.) - 1., 0., 1.);
    return c.z * mix(vec3(1.), rgb, c.y);
}

void main(void) {
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy)/ max(resolution.x, resolution.y);
    uv.y += sin(time * 1.55) / 5.;
    
    float signF = (step(fract(time / 5.) * 2. - 1., 0.) * 2. - 1.);
    float bla = signF * (uv.x / 3. + fract(time / 2.5) * 2. - 1.);
   
    uv = rotate(uv, sin(time * 1.55 + PI / 3.5) / 5.);       
    float k = 20.;
    float birdD = smoothMin(sdBird(uv), 1., 8.);
    
    float fd = mix(1. - sdf(smoothMin(birdD, -bla, k)), 
                   sdf(smoothMin(birdD, bla, k)), 
                   sdf(bla));
    
    vec3 c = vec3(sin(time / 5.) * 0.5 + 0.5, 0.8, 0.2);
    glFragColor = vec4((fd + 0.2) * (hsv2rgb(c) + 0.6), 1.);
}
