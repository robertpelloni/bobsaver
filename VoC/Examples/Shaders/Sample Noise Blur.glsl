#version 420

// original https://www.shadertoy.com/view/NtGGWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

float thc(float a, float b) {
    return tanh(a * cos(b)) / tanh(a);
}

float ths(float a, float b) {
    return tanh(a * sin(b)) / tanh(a);
}

vec2 thc(float a, vec2 b) {
    return tanh(a * cos(b)) / tanh(a);
}

vec2 ths(float a, vec2 b) {
    return tanh(a * sin(b)) / tanh(a);
}

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

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    
    float sc = 32.;
    
    uv *= 1.5;
    uv.x += cos(0.01 * uv.y + 0.5 * time) * thc(12., -0.3 * time + 0.1 * h21(uv));// + thc(1., 6. * length(uv) - time);
    uv.y += sin(0.01 * uv.x + 0.5 * time) * ths(12., -0.3 * time + 0.1 * h21(uv));
    
    vec2 ipos = floor(sc * uv)/sc + 0.;
    
    float a = atan(ipos.y, ipos.x);
    float r = length(ipos);
    r = log(r) + 0.4 * thc(3.,4. * r + time);

    float sc2 = 3. + 2. * cos(3. * a + time);
    
    
    float val = 5. * r + a + time;
    vec2 fpos = fract(vec2(thc(1., val), ths(1.,val)) + sc2 * ipos) - 0.5;
    
    float d = length(fract(thc(4.,a + time) * fpos) - 0.5);
    float rd = 1. + thc(1., a + 4. * r - time);
    float k = 0.4;
    float s = 1.-smoothstep(-k,k,rd-d);  
    //s -= step(d, 0.2 * rd);
    s = clamp(4. * s * s, 0., 1.);
    
    fpos = fract(sc * uv) - 0.5;
    
    d = mlength(fpos);
    rd = min(0.45, 0.1 * thc(40., r + 1.5 * h21(ipos) + time) + 0.4 * s);
    rd *= step(0.11, rd);
    float s2 = step(d, rd) - smoothstep(-0.5,0.5, rd -d);
    s2 = clamp(5. * s2 * s2, 0., 1.);
    s *= 2. * pow(1.-length(uv),4.);
    vec3 col = s2 * pal(s +10.* h21(ipos) + time, vec3(1.), vec3(1.), vec3(1.), vec3(0.,0.33,0.66));
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
