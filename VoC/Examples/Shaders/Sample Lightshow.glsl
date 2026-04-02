#version 420

// original https://www.shadertoy.com/view/llKyzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int BALLS = 25;

// noise and rand functions stolen from stack overflow :)
float rand(float n){return fract(sin(n) * 43758.5453123);}

vec2 hash(vec2 co) {
    float m = dot(co, vec2(12.9898, 78.233));
    return fract(vec2(sin(m),cos(m))* 43758.5453) * 2. - 1.;
}

float fade(float t) { return t * t * t * (t * (t * 6. - 15.) + 10.); }

vec2 ssmooth(vec2 x) { return vec2(fade(x.x), fade(x.y)); }

float perlinNoise(vec2 uv) {
    vec2 PT  = floor(uv);
    vec2 pt  = fract(uv);
    vec2 mmpt= ssmooth(pt);

    vec4 grads = vec4(
        dot(hash(PT + vec2(.0, 1.)), pt-vec2(.0, 1.)),   dot(hash(PT + vec2(1., 1.)), pt-vec2(1., 1.)),
        dot(hash(PT + vec2(.0, .0)), pt-vec2(.0, .0)),   dot(hash(PT + vec2(1., .0)), pt-vec2(1., 0.))
    );

    return 5.*mix (mix (grads.z, grads.w, mmpt.x), mix (grads.x, grads.y, mmpt.x), mmpt.y);
}

// https://github.com/hughsk/glsl-hsv2rgb/blob/master/index.glsl
vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 position = gl_FragCoord.xy/resolution.xy;
    position.x *= resolution.x / resolution.y;

    
    vec3 dist = vec3(0.0);
    for (int i = 0 ; i < BALLS ; i++) {
        vec2 bpos = vec2(perlinNoise(vec2(float(i*3218) + cos(time*0.1), time*0.1)), perlinNoise(vec2(float(i*1357) + sin(time*0.1), -time*0.1))) / 5.0;
        bpos += vec2(0.5 * resolution.x/resolution.y,0.5);
        dist += hsv2rgb(vec3(float(i) / float(BALLS), 1.0, 1.0)) * 1.0 / (pow(position.x - bpos.x, 2.0) + pow(position.y - bpos.y, 2.0));
    }
    
    glFragColor = vec4(dist/1000., 1.0);
}
