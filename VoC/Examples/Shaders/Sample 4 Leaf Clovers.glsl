#version 420

// original https://www.shadertoy.com/view/ddyGW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define _ParticlesAmount 10

float rnd(float x)
{
    return fract(sin(dot(vec2(x + 47.49,38.2467 / (x + 2.3)), vec2(12.9898, 78.233))) * (43758.5453));
}

float drawLeaf(vec2 uv, float scale, float d) {
    float ret;
    vec2 root = uv - vec2(0.0, scale);
    float r = length(root) / scale;
    float t = abs(atan(root.x, root.y) / 3.1415);
    float edge = (3.0 * t - 8.0 * t*t*t*t + 6.0 * t*t*t*t*t) / (4.0 - 3.0 * t);
    //float edge = (3.0 * t - 8.0 * t*t*t*t*t + 6.0 * t*t*t*t*t*t) / (3.0 - 2.0 * t*t);
    //float edge = (3.0 * t + 2.0 * t*t - 2.0 * t*t*t - 9.0 * t*t*t*t*t*t + 7.0 * t*t*t*t*t*t*t) / (5.0 - 4.0 * t*t);
    ret = smoothstep(edge - d, edge + d, r);
    return ret;
}

mat2 rotate(float t) {
    return mat2(cos(t), -sin(t), sin(t), cos(t));
}

float drawClover(vec2 uv, float scale, float d) {
    float ret = drawLeaf(uv, scale, d);
    uv = rotate(1.5707) * uv;
    ret *= drawLeaf(uv, scale, d);
    uv = rotate(1.5707) * uv;
    ret *= drawLeaf(uv, scale, d);
    uv = rotate(1.5707) * uv;
    ret *= drawLeaf(uv, scale, d);
    return 1.0 - ret;
}

vec4 alphaBlend(vec4 base, vec4 blend)
{
    return vec4(base.rgb * base.a * (1.0 - blend.a) + blend.rgb * blend.a, blend.a + base.a * (1.0 - blend.a));   
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);
    float t = smoothstep(1.5, 0.0, length(uv));
    glFragColor = vec4(t * vec3(0, 0.0, 0.0) + (1.0 - t) * vec3(0.0, 0.0, 0.0), 1.0);
   
    float j;
    float move_max = 2.0;
    vec2 spawn_center = vec2(0.0, 0.0);
    float spawn_length = 0.5;
    float _ParticlesAmount_f = float(_ParticlesAmount);
    
    for (int i = 1; i < _ParticlesAmount; i++)
    {
        j = float(i);
        float rnd1 = rnd(cos(j));
        float delayedTime = (0.2 + 0.2 * rnd1) * time;
        float d = floor(delayedTime / move_max);
        float rnd2 = rnd(j * d);
        float rnd3 = rnd(j * j * d);
        float r = delayedTime / move_max - d;
        float x_wave = 0.15 * sin(delayedTime * 7.0 + 6.282 / j);
        vec2 spawn = vec2(0.0, rnd3 * spawn_length);
        float ease = pow(2.0, 5.0 * (r - 1.0));
        float y_move = move_max * ease;
        float opacity = 1.0 - ease - pow(2.0, -30.0 * r);
        float scale = 1.0 - 0.65 * rnd1 + 0.15 * sin(1.8 * time * j / _ParticlesAmount_f + 6.282 / j);
        float rot_wave = 2.0 * sin(delayedTime * 3.0 * j / _ParticlesAmount_f * 2.0 + 6.282 / j);
        vec2 center = rotate(rot_wave) * (rotate(6.282 * rnd2) * (uv + spawn_center) + spawn + vec2(x_wave, y_move)) * scale;
        vec3 cloverColor = vec3(0.3 + 0.3 * rnd2, 0.98, 0.3) * (1.0 - 0.3 * rnd3);
        vec3 cloverCenterColor = cloverColor + (vec3(1.0) - cloverColor) * 0.5;
        vec3 cloverBgColor = vec3(1.0, 0.98, 0.7);
        glFragColor = alphaBlend(glFragColor, vec4(cloverBgColor, opacity * drawClover(center, 0.1, 0.3)));
           glFragColor = alphaBlend(glFragColor, vec4(cloverColor, opacity * drawClover(center, 0.1, 0.01)));
        glFragColor = alphaBlend(glFragColor, vec4(cloverCenterColor, opacity * drawClover(center, 0.05, 0.3)));
    }
}
