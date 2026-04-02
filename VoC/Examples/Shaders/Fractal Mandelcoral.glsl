#version 420

// original https://www.shadertoy.com/view/WtVczh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// using iq's mandelbrot distance https://www.shadertoy.com/view/lsX3W4

vec2 cpow(vec2 c, float power) {
    if (abs(c.x) < 1e-5 && abs(c.y) < 1e-5) return vec2(0.0);
    vec2 cm = vec2(log(length(c)), atan(c.y, c.x)) * power;
    float pr = exp(cm.x);
    return vec2(pr * cos(cm.y), pr * sin(cm.y));
}

vec3 f(vec2 p, float time) {
    vec3 res = vec3(1.0);
    float n = 2.0;
    float zoom = 0.006 + sin(time) / 500.0;
    vec2 c = p * zoom - vec2(1.341, 0.065);
    float imax = 300.0;
    float bailout = 2.1;
    vec2 z = vec2(0.0);
    vec2 dz = z;
    float m2 = 0.0;
    
    for (float i = 0.0; i < imax; i++) {
        if (m2 > bailout) break;
        vec2 ch = n * cpow(z, n - 1.0);
        dz = mat2(ch, -ch.y, ch.x) * dz + vec2(1.0, 0.0);
        z = cpow(z, n) + c + sin(time) * 0.005;
        m2 = dot(z, z);
    }
    
    float lm2 = log(m2);
    float d = 0.5 * sqrt(m2 / dot(dz, dz)) * lm2;
    res *= d * imax;
    res.g /= 1.0 - 0.2 * lm2;
    res = clamp(res, vec3(0.0, 0.0, 0.1), vec3(50.0 * d, 0.3, 1.0));
    res += vec3(0.002, 0.6, 0.6) / length(dz);
    res *= sin(vec3(2.0, 0.4, 20.0) * tanh(1.0 - 1.0 / length(tan(z - 100.0) * 0.95)));
    res += pow(clamp(vec3(1.0) - length(c - z * 1.6), 0.0, 1.0) * 160.0, vec3(0.7)) * res;
    return res;
}

vec2 rot(vec2 p, float a) {
    return cos(a) * p + sin(a) * vec2(p.y, -p.x);
}

void main(void)
{
    float time = 1024.0 + mod(time * 0.1, 1024.0);
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv /= vec2(resolution.y/resolution.x, 1.0);
    uv *= 4000.0 / time;
    
    vec3 col = f(rot(uv, time), time);

    glFragColor = vec4(pow(col, vec3(1.0/2.2)), 1.0);
}
