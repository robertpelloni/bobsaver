#version 420

// original https://www.shadertoy.com/view/Ntsczn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Creds to Iniqo Quilez to learn about domain warping: https://iquilezles.org/articles/warp/

int NUM_NOISE_OCTAVES = 8;

float hash(float p) { p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p); }
float hash(vec2 p) {vec3 p3 = fract(vec3(p.xyx) * 0.13); p3 += dot(p3, p3.yzx + 3.333); return fract((p3.x + p3.y) * p3.z); }

float noise(float x) {
    float i = floor(x);
    float f = fract(x);
    float u = f * f * (3.0 - 2.0 * f);
    return mix(hash(i), hash(i + 1.0), u);
}

vec2 N22(vec2 p){

    vec3 a = fract(p.xyx * vec3(123.34, 234.34, 345.65));
    a += dot(a,a+34.35);
    return fract(vec2(a.x*a.y,a.y*a.z));

}

float noise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float noise(vec3 x) {
    const vec3 step = vec3(110, 241, 171);

    vec3 i = floor(x);
    vec3 f = fract(x);
 
    float n = dot(i, step);

    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

float fbm(float x) {
    float v = 0.0;
    float a = 0.5;
    float shift = float(100);
    for (int i = 0; i < NUM_NOISE_OCTAVES; ++i) {
        v += a * noise(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

float fbm(vec2 x) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100);
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_NOISE_OCTAVES; ++i) {
        v += a * noise(x);
        x = rot * x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

float fbm(vec3 x) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100);
    for (int i = 0; i < NUM_NOISE_OCTAVES; ++i) {
        v += a * noise(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

float pattern(vec2 p, out vec2 qo, out vec2 ro){
    
    float t = time+500.;
    
    vec2 q = vec2(fbm(p+ vec2(0.0,0.0)*t*0.0001), 
                  fbm(p+vec2(5.2,1.3)*t*0.005));
                  
    qo.x = q.x;
    qo.y = q.y;
    
    vec2 r = vec2(fbm(p + 4.0*q + vec2(1.7,9.2)), 
            fbm(p + 4.0*q + vec2(8.3,2.8)));
            
    ro.x = r.x;
    ro.y = r.y;

    return fbm(p + 10.*r);

}

vec3 col1 = vec3(212., 241., 249.)/255.;
vec3 col2 = vec3(113., 75., 81.)/255.;
vec3 col3 = vec3(199., 164., 169.)/255.;
vec3 col4 = vec3(229., 126., 60.)/25.5;

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec2 q = vec2(0.0);
    vec2 r = vec2(0.0);
    float x = pattern(uv*2.,q,r);
    
    vec3 col = vec3(0.0);
    
    col = mix( col1, col2, q.x*30.);
    col = mix(col, col3, r.y*2.);
    col = mix(col, col4, r.x*0.3);
    col = col *x*.5;
    

    glFragColor = vec4(col,1.0);
}
