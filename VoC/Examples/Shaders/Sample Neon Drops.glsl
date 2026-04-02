#version 420

// original https://www.shadertoy.com/view/7d2czc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const uint seed = 1u;

const uint m = 0x80000000u;

const vec3 colors[6] = vec3[] (
    vec3(1.0, 0.5, 0.1),
    vec3(1.0, 0.1, 0.5),
    vec3(0.5, 1.0, 0.1),
    vec3(0.1, 1.0, 0.5),
    vec3(0.5, 0.1, 1.0),
    vec3(0.1, 0.5, 1.0)
);

float rand(uint seed){
    return float((seed * 1103515245u + 12345u) % m) / float(m);
}

vec3 drop(vec2 p, float timeOffset, int colorIndex)
{
    float t = mod(time - timeOffset, 10.0);
    float l = 10.0 * length(p);
    float d = t - l;
    float r = 1.0 + t;
    float s = 1.0 + d;
    
    
    if (d < 0.0) {
        return vec3(0.0, 0.0, 0.0);
    }
    
    float a = 3.0 * cos(10.0 * d) / (r * r) / (s * s);
    return a * colors[colorIndex];
}

void main(void)
{   
    float size = min(resolution.x, resolution.y);
    vec2 norm = gl_FragCoord.xy / size;
    vec2 ratio = resolution.xy / size;
    
    float x = rand(seed);
    float y = rand(uint(x * float(m)));
    float z = rand(uint(y * float(m)));
    
    for (int i = 0; i < 100; i++) {
    
        vec2 p = norm - vec2(x, y) * ratio;
        vec3 c = drop(p, 0.1 * float(i), int(z * 6.0));

        x = rand(uint(z * float(m)));
        y = rand(uint(x * float(m)));
        z = rand(uint(y * float(m)));

        // Output to screen
        glFragColor += vec4(c, 1.0);
    }
}
