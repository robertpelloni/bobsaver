#version 420

// original https://www.shadertoy.com/view/Wsj3R1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.1415926535897932384626433832795
#define M_PI05 (M_PI * 0.5)

vec2 rotate(vec2 v, float c, float s){
    return vec2(v.x*c - v.y*s, v.x*s + v.y*c);
}

vec2 rotate(vec2 v, float r){
    return rotate(v, cos(r), sin(r));
}

vec2 fracOrigin(vec2 v){
    return (fract(v) - 0.5) * 2.0;
}

vec3 hsv2rgb(vec3 hsvValue) {
    const vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(hsvValue.x + t.xyz) * 6.0 - t.w);
    return hsvValue.z * mix(t.xxx, clamp(p - t.x, 0.0, 1.0), hsvValue.y);
}

float heartLength(vec2 pos){
    pos.y -= 0.35;
    pos *= 2.2;
    float r = abs(atan(pos.x, pos.y) / M_PI);
    float r2 = r * r;
    float s = (39.0 * r - 66.0 * r2 + 30.0 * r2 * r) / (6.0 - 5.0 * r);   
    return length(pos) / s;
}

float ease_in_quad(float t){ return t * t; }
float ease_out_quad(float t){ return -t * (t - 2.0); }
float ease_in_cubic(float t){ return ease_in_quad(t) * t; }
float ease_out_cubic(float t){ return ease_in_cubic(t - 1.0) + 1.0; }
float ease_in_quart(float t){ return ease_in_cubic(t) * t; }
float ease_out_quart(float t){ return -ease_in_quart(t - 1.0) + 1.0; }
float ease_out_back(float t){ float g = 1.70158; return (ease_in_quad(t - 1.0) * ((g + 1.0) * (t - 1.0) + g) + 1.0); }

vec4 mixin(vec4 src1, vec4 src2){
    return vec4(mix(src1.rgb, src2.rgb, src2.a), max(src1.a, src2.a));
}

vec4 circleEffect(vec2 pos, float t){
    float t2 = ease_out_quad(t);
    float len = length(pos);
    float r = (1.0 - smoothstep(0.8 + t2 * 0.1, 0.81 + t2 * 0.1, len)) * smoothstep(t2, t2 + 0.01, len);
    return vec4(hsv2rgb(vec3(0.0 - ease_in_cubic(t), 0.5, 0.9)), r);
}

vec4 circleEffect2(vec2 pos, float t){
    float t1 = ease_out_quart(t);
    float t2 = ease_in_quart(t);
   
    float r = length(pos);
    float s = atan(pos.y, pos.x) / M_PI;

    float s2 = floor(s * 3.505) / 3.505;
    float hash = sin(s2 * 4863.89644169) * 0.05;
    vec2 uv2 = pos + rotate(vec2(mix(0.5, 1.0 + hash, t1), 0.0), s2 * M_PI + 3.4);
    vec2 uv3 = pos + rotate(vec2(mix(0.8, 0.9 + hash, t1), 0.0), s2 * M_PI + 3.65);
    
    float aa = length(uv2);
    float aa2 = length(uv3) * 1.8;
    aa = min(aa, aa2);
    aa = 1.0 - smoothstep(0.1, 0.11, aa +  t2 * 0.11);
    
    return vec4(hsv2rgb(vec3(s2 * 0.5 - 0.1, 0.5, 0.95)), aa);
}

vec4 heartEffect(vec2 pos, float t){
    float t3 = max(1.0 - t * 3.0, ease_out_back(t));
    float heart = 1.0 - smoothstep(1.0, 1.02, heartLength(pos * mix(6.0, 2.0, (t3))));
                             
    return vec4(hsv2rgb(mix(vec3(0.0, 0.0, 0.8), vec3(0.0, 0.5, 0.95), t)), heart);   
}

vec4 effect(vec2 pos, float t){
    vec4 col = vec4(1.0, 1.0, 1.0, 0.0);    
    col = mixin(col, heartEffect(pos, t));
    col = mixin(col, step(0.001, t) * circleEffect(pos, clamp(t * 3.0, 0.0, 1.0)));
    col = mixin(col, step(0.001, t) * circleEffect2(pos, clamp(t * 1.2, 0.0, 1.0)));  
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.yy * 2.2;  
    glFragColor = effect(uv, clamp((fract(time * 0.5) - 0.5) * 3.0, 0.0, 1.0));
}
