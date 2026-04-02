#version 420

// original https://www.shadertoy.com/view/dsGfDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 3

const float PI = 3.14159265;
const int MAX_ITER = 125;
const float BOUND = 25.0;

vec2 implicit(vec2 c, float time) {
    vec2 z = vec2(0.0);
    int i;
    for (i = 0; i < MAX_ITER; i++) {
        vec2 sin_z = vec2(sin(z.x) * cosh(z.y), cos(z.x) * sinh(z.y));
        z = vec2(c.x * sin_z.x - c.y * sin_z.y, c.x * sin_z.y + c.y * sin_z.x);
        z += 0.2 * vec2(sin(0.05 * time), cos(0.05 * time));
        if (dot(z, z) > BOUND * BOUND) break; 
    }
    return vec2(float(i), dot(z, z));
}

void main(void)
{
    vec3 col = vec3(1.0);
    vec2 pan = vec2(0.878729, 1.504069); 
    float zl = 0.005; //please don't zoom out XD

    for(int m = 0; m < AA; m++) //AA technique from iq
    for(int n = 0; n < AA; n++)
    {
        vec2 uv = ((gl_FragCoord.xy + vec2(float(m), float(n)) / float(AA) - 0.5 * resolution.xy) / min(resolution.y, resolution.x)
        * zl + pan) * 2.033 - vec2(2.04278);
        vec2 z_and_i = implicit(uv, time);
        float iter_ratio = z_and_i.x / float(MAX_ITER);
        //float lenSq = z_and_i.y;

        vec3 col1 = 0.5 + 0.5 * cos(time + vec3(0.6, 0.8, 1.0) + 5.0 * PI * vec3(iter_ratio));
        col += col1;
     
    }
    col /= float(AA * AA); 

    glFragColor = vec4(col, 1.0);
}
