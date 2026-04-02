#version 420

// original https://www.shadertoy.com/view/7ljcRR

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

/////// Messy color stuff ///////

#define val 1.

vec3 midCol(float t) {
    float colTime = fract(val * t);
    vec3 col;
    if (colTime < 1./3.)
        col = vec3(0., 220., 244.) / 255.;
    else if (colTime < 2./3.)
        col = vec3(245., 208., 0.) / 255.;
    else
        col = vec3(219., 0., 255.) / 255.;
    return col;
}

vec3 darkCol(float t) {
    float colTime = fract(val * t);
    vec3 col;
    if (colTime < 1./3.)
        col = vec3(0., 172., 246.) / 255.;
    else if (colTime < 2./3.)
        col = vec3(236., 182., 0.) / 255.;
    else
        col = vec3(172., 0., 255.) / 255.;
    return col;

}

vec3 lightCol(float t) {
    float colTime = fract(val * t);
    vec3 col;
    if (colTime < 1./3.)
        col = vec3(0., 255., 195.) / 255.;
    else if (colTime < 2./3.)
        col = vec3(238., 243., 0.) / 255.;
    else
        col = vec3(255., 58., 235.) / 255.;
    return col;
}

vec3 lerpCol(float t, float l) {
    vec3 col;
    // assuming 0 <= l <= 1
    if (l < 1./3.) 
        col = mix(vec3(28, 28, 51) / 255., darkCol(t), vec3(3. * l));
    else if (l < 2./3.)
        col = mix(darkCol(t), midCol(t), vec3(3. * l - 1.));
    else
        col = mix(midCol(t), lightCol(t), vec3(3. * l - 2.));
    
    return col;
}

vec3 whiteCol(float t) {
    float colTime = fract(val * t);
    vec3 col;
    if (colTime < 1./3.)
        col = vec3(215,255,241);
    else if (colTime < 2./3.)
        col = vec3(255,254,249);
    else
        col = vec3(255,221,239);
    return col / 255.;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    uv *= 4.5;
    uv.x += 0.5 * time;
    float sc = 4.;
    
    float ix = floor(sc * uv.x) + 0.;
    float fx = fract(sc * uv.x) - 0.5;
    
    float h = 3. * cos((0.2 * uv.x + 0.8 * ix/sc) - 2. * time);
    //h += 3. * (h21(vec2(-7. * ix, 3. * ix + 101.)) - 0.);
    
    float m = mod(ix, 2.) - 0.5;
    
    float r = (sc + 1. * h) * m;
    
    float k = 4. * sc /  resolution.y;
    float s = smoothstep(-1.4, 1.4, -sc * uv.y + r);
    
    vec2 uv2 = vec2(fx, sc * uv.y - r);
    
    s += 2. * m * smoothstep(-k, k, -length(uv2) + 0.5);
   
    
    vec3 col = vec3(s);
    vec3 e = vec3(0.5);
    col += pal(1.1 * ix/sc,e,e,e,vec3(0,1,2)/3.) * exp(-2. * (-0.14 * h + uv.y + 1.));
    
    glFragColor = vec4(col,1.0);
}
