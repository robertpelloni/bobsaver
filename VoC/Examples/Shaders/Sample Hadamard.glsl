#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Mt3fDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int cyclic_mul(int a, int b) {
    return (a + b) % 3;
}

int cyclic_exp(int a, int b) {
    int r = 1;
    int k = a;
    for (int i = 0; i < 32; ++i) {
        if (((b >> i) & 1) == 1) {
            r = cyclic_mul(r, k);
        }
        k = cyclic_mul(k, k);
    }
    return r;
}

int dim_product(int a, int b, int n) {
    int k = n / 2;
    int r = 0;
    for (int i = 0; i < k; ++i) {
        r += (a * b) % 2;
        a /= 2;
        b /= 2;
    }
    return r;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv.y = 1.0 - uv.y;
    
    int s = int(exp2(1.0 + mod(floor(time * 8.0), 10.0)));
    
    vec2 ac = vec2(resolution.x / resolution.y, 1.0);
    
    vec2 val = floor(uv * float(s));
    
    int k = dim_product(int(val.x), int(val.y), s);
    
    int e = cyclic_exp(1, k);
    
    float c = float(e - 1);
    
    vec3 fc = vec3(c, c, c);
    
    if (abs(uv.x) > 1.0) {
        //fc = vec3(0.5);
    }

    glFragColor = vec4(fc, 1.0);
}
