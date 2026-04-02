#version 420

// original https://www.shadertoy.com/view/llXyzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash13(vec3 p) {
    p  = fract(p * vec3(443.8975, 397.2973, 491.1871));
    p += dot(p.xyz, p.yzx + 19.19);
    return fract(p.x * p.y * p.z);
}

float noise13(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);
    return 1.0 - 2.0 * mix(mix(mix(hash13(i + vec3(0.0, 0.0, 0.0)), 
                                   hash13(i + vec3(1.0, 0.0, 0.0)), u.x),
                               mix(hash13(i + vec3(0.0, 1.0, 0.0)), 
                                   hash13(i + vec3(1.0, 1.0, 0.0)), u.x), u.y),
                           mix(mix(hash13(i + vec3(0.0, 0.0, 1.0)), 
                                   hash13(i + vec3(1.0, 0.0, 1.0)), u.x),
                               mix(hash13(i + vec3(0.0, 1.0, 1.0)), 
                                   hash13(i + vec3(1.0, 1.0, 1.0)), u.x), u.y), u.z);
}

const mat3 m = mat3( 0.51162, -1.54702,  1.15972,
                    -1.70666, -0.92510, -0.48114,
                     0.90858, -0.86654, -1.55678);

float fbm13(vec3 p) {
    float f = noise13(p); p = m * p;
    f += 0.4 * noise13(p); p = m * p;
    f += 0.16 * noise13(p); p = m * p;
    f += 0.064 * noise13(p);
    return 0.5 + 0.30788 * f;
}

void main(void) {
    vec2 pos = 3.0 * (-resolution.xy + 2.0 * gl_FragCoord.xy) / resolution.y;
    float r = length(pos);
    if (r < 1.0) {
        glFragColor = vec4(0.0);
        return;
    }
    vec2 p = pos / r;
    r -= 1.0;
    float aa = 6.0 / resolution.y;
    vec3 color = vec3(0.0, 0.1, 0.3);
    
    float f = fbm13(vec3(10.0 * pos, 0.4 * time));
    f = clamp(f + 1.1 * exp(-5.0 * r) - 1.5, 0.0, 10.0);
    color += f * vec3(3.0, 0.8, 0.4);
    
    f = fbm13(vec3(5.0 * p, 0.2 * time - 0.5 * r));
    f = clamp(f + 1.2 * exp(-0.8 * r) - 0.8, 0.0, 1.0);
    color += vec3(0.6 * f);
    
    r = clamp(r / aa, 0.0, 1.0);    
    glFragColor = vec4(r * clamp(color, 0.0, 1.0), 1.0);
}
