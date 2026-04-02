#version 420

// original https://www.shadertoy.com/view/NdsBWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define ths(a,b) tanh(a*sin(b))/tanh(a)
#define sabs(x) sqrt(x*x+1e-2)

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float h21 (vec2 a) {
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
    float k = 0.12;
    float h = clamp(0.5 + 0.5 * (b-a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float smin(float a, float b, float k) {
    float res = exp(-k*a) + exp(-k*b);
    return -log(res)/k;
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    
    float px = 128.;
    // uv = floor(px * uv) / px;
       
    /*
    float r = length(uv);
    float a = atan(uv.x, uv.y) - 4. * r;
    //r = log(r);
    uv = r * vec2(cos(a), sin(a));
    */
    
    float h = h21(uv);
    
    // change me
    float a1 = 10.; // any number is good here
    float a2 = a1 + 1.;
    float sc = .5; // higher -> more square (use 0.001 instead of 0)
    
    float th = .01;//mix(0.03, 0.005, 1.-m); //0.0025;
    
    float t = .2 * time;
    float n = 100.;
    
    float d = 10.;
    float s = 0.;
    
    float myi = 0.;
    
    for(float i = 0.; i < n; i++) {
        float o = 1. * pi * i / n;
        
        float r = 0.42 * (0.5 + 0.5 * thc(50., 2. * t + 1. * o));
        
        vec2 p = r * vec2(thc(sc, t + a1 * o), ths(sc, t + a1 * o));
        vec2 q = -r * vec2(thc(sc, t + a2 * o), ths(sc, t + a2 * o));
        float d2 = sdSegment(uv, p, q);
        if (d2 < d) {
            d = d2;
            myi = i;
        }
    }
    
    float k = 1./resolution.y;
    s = smoothstep(-k, k, -d + th);
    
    vec3 col = vec3(s);
    
    vec3 e = vec3(1.);
    col *= pal(myi / n, e, e, e, 0.4 * vec3(0,1,2)/3.);
    col = sqrt(col + 0.02);
    glFragColor = vec4(col,1.0);
}
