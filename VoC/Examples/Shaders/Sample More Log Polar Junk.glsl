#version 420

// original https://www.shadertoy.com/view/NlKGRG

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
    float pe = 100.;
    //uv = floor(pe * uv)/pe + 0.;
    uv.y += 0.02 * cos(10. * uv.x + time);

    float a = atan(uv.y, uv.x);
    float r = length(uv);

    uv = vec2(2. * a, log(r));
    uv = uv.y * vec2(thc(2., uv.x), ths(2., uv.x));
    
    
    float sc = 1.;
     vec2 ipos = vec2(floor(0. * time + sc * uv.x) + 0.5,
                      floor( 0.25 * time + 2. * sc * uv.y) + 0.5);
    
    
    
    vec2 fpos = vec2(fract(0. * time + sc * uv.x) - 0.5,
                     fract( 0.3 * time + 2. * sc * uv.y) - 0.5);
    
    //fpos.y += 0.2 * cos(8.* fpos.x + 10. * h21(ipos) + time);
    float k = 0.6 + 0.4 * thc(0.1, cos(0. * h21(ipos) + 8. * r -5.* a- time) + 2. * a - 1.2 * time);
   
    float d = (2. + thc(4., k + r * 10. - time)) * length(fpos) * length(fpos);// + (0.5 + thc(2., 101. * h21(ipos) + time));
    float s = 1.2 * (1.-mlength(fpos)) * smoothstep(-0.5,0.5, 0.45-d);// - step(0.46, mlength(fpos));
    s = smoothstep(-k, k, 
        -d + 0.32 + 0.1 * thc(4., -time + log(r) + 2. * a));
    vec3 col = vec3(s);
    vec3 col2 =  pal(k +  - 0.8 * time + s * 0.002 * time, vec3(1.), vec3(1.), vec3(0.4), log(r) * vec3(0.,0.33,0.66));
    float s2 = 0.5 + 0.5 * thc(1., 1.5 * thc(2., 8. * s - time));
    col = mix(col, col2, vec3(s2));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
