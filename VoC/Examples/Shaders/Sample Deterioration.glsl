#version 420

// original https://www.shadertoy.com/view/3dBSW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Deterioration by @blokatt
// 11/04/19
// Mesmerising...

int bayer[64] = int[64](0,  32, 8,  40,  2, 34, 10, 42,
                        48, 16, 56, 24, 50, 18, 58, 26,
                        12, 44, 4,    36, 14, 46, 6,  38, 
                        60, 28, 52, 20, 62, 30, 54, 22, 
                         3, 35, 11, 43,  1, 33,  9, 41,
                        51, 19, 59, 27, 49, 17, 57, 25, 
                        15, 47, 7,  39, 13, 45, 5,  37, 
                        63, 31, 55, 23, 61, 29, 53, 21);

vec3 dither(vec3 col, vec2 coord){        
    int X = int(mod(coord.x, 8.));
    int Y = int(mod(coord.y, 8.));
       
    float val = float(bayer[Y * 8 + X]) / 64.;
    return (floor((col + val * (1. / 64.)) * 64.) / 64.);
}

mat2 rot(float a){
    return mat2 (
        cos(a), -sin(a),
        sin(a), cos(a)
    );
}

float rand(vec2 uv){
    return fract(sin(dot(vec2(12.9898,78.233), uv)) * 43758.5453123);
}

float valueNoise(vec2 uv){
    vec2 i = fract(uv);
    vec2 f = floor(uv);
    float a = rand(f);
    float b = rand(f + vec2(1.0, 0.0));
    float c = rand(f + vec2(0.0, 1.0));
    float d = rand(f + vec2(1.0, 1.0));    
    return mix(mix(a, b, i.x), mix(c, d, i.x), i.y);
}

float fbm(vec2 uv) {
    float v = 0.0;
    float freq = 9.5;
    float amp = .75;
    float z = 30. + 20. * sin(time * .2);
   
    for (int i = 0; i < 10; ++i) {
        v += valueNoise(uv + z * uv * .05 + time * .1) * amp;
        uv *= 3.25;
        
        amp *= .5;
    }
    return v;    
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy - .5;
    vec2 oldUV = uv;
    uv.x *= resolution.x / resolution.y;
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    uv *= rot(time * .02);
    glFragColor = vec4(dither(
                        vec3(
                            fbm(uv + vec2(5.456, -2.8112) * rot(fbm(uv))),
                            fbm(uv + vec2(5.476, -2.8122) * rot(fbm(uv))),
                            fbm(uv + vec2(5.486, -2.8132) * rot(fbm(uv)))      
                        ) - (smoothstep(.1, 1., length(oldUV)))
                    , gl_FragCoord.xy), 1.0);
}
