#version 420

// original https://www.shadertoy.com/view/ssc3zf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Constants
//============================================
#define TOTAL_OCTS 4
#define RAY_MARCH_TOTAL_STEPS 100
#define CAM_POS vec3(0., 1.0, 0.)
//============================================

// Global functions
//============================================
// randomizer with range [0, 1]
//float rand(vec3 p) {
//    return abs(fract((12346.*cos((87654.*sin(-1034560.*(dot(p, vec3(12345, 234567, 2345678) - 1100495.)))) - 1.))));
//}
float rand(vec3 p) {
    return fract(sin(dot(p, vec3(12.345, 67.89, 412.12))) * 42123.45) * 2.0 - 1.0;
}

// perlin noise in 0-0-0 -> 1-1-1 cube
float perlin(vec3 p) {
    vec3 u = floor(p);
    vec3 v = fract(p);
    vec3 s = smoothstep(0.0, 1.0, v);
    
    float a = rand(u);
    float b = rand(u + vec3(1.0, 0.0, 0.0));
    float c = rand(u + vec3(0.0, 1.0, 0.0));
    float d = rand(u + vec3(1.0, 1.0, 0.0));
    float e = rand(u + vec3(0.0, 0.0, 1.0));
    float f = rand(u + vec3(1.0, 0.0, 1.0));
    float g = rand(u + vec3(0.0, 1.0, 1.0));
    float h = rand(u + vec3(1.0, 1.0, 1.0));
    
    return mix(mix(mix(a, b, s.x), mix(c, d, s.x), s.y),
               mix(mix(e, f, s.x), mix(g, h, s.x), s.y),
               s.z);
}

// sums perlin noises by octs

// sums perlin noises by octs
float octs(vec3 p) {
    vec3 arg = p - time * vec3(0, 0.1, 1.);
    
    float res = 0.;
    float A = 0.5;
    for (int i = 0; i < TOTAL_OCTS; i++) {
        res += A*perlin(arg);
        A /= 2.;
        arg *= 2.;
    }
    
    return clamp(res - p.y, 0.0, 1.0);
}

// ray marching
vec3 rayMarch(vec3 s, vec3 d) {
    vec4 res = vec4(0);
    float depth = 0.;
    for (int i = 0; i < RAY_MARCH_TOTAL_STEPS; i++) {
        vec3 p = s + d * depth;
        float density = octs(p);
        if (density > 1e-3) {
            vec4 color = vec4(mix(vec3(0.0), vec3(1.0), density), density);
            color.w *= 0.4;
            color.rgb *= color.w;
            res += color * (1.0 - res.a);
        }
        depth += max(0.05, 0.02 * depth);
    }
    return res.rgb;
}

//============================================

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.y;
 
    vec3 start = CAM_POS;
    vec3 dir = normalize(vec3(uv.xy, 1.0));
    
    glFragColor = vec4(rayMarch(start, dir).rgb, 1.);// + vec4(0., 0., 0.8, 1.0);
}
