#version 420

// original https://www.shadertoy.com/view/WdyyDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.1415

float random(in vec2 _st) {
    return fract(sin(dot(_st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec2 truchetPattern(in vec2 _st, in float _index){
    _index = fract(((_index-0.5)*2.0));
    if (_index > 0.75) {
        _st = vec2(1.0) - _st;
    } else if (_index > 0.5) {
        _st = vec2(1.0-_st.x,_st.y);
    } else if (_index > 0.25) {
        _st = 1.0-vec2(1.0-_st.x,_st.y);
    }
    return _st;
}

float atan2(in float y, in float x)
{
    return mix(pi / 2.0 - atan(x, y), atan(y, x), abs(x) > abs(y));
}

vec3 sine(vec3 t) {return (sin(t) * 0.5) + 0.5;}

vec3 hsv2rgb(float h, float s, float v) {
    h /= 3.0;
    vec3 g = sine(vec3(h, h + 0.333, h + 0.666) * pi * 2.0);
    
    return (vec3(1.0) * (1.0 - s)) + ((g * s) * v);
}

void main(void) {
    vec2 res = resolution.xy;
    vec2 uv = (gl_FragCoord.xy - (0.5 * res)) / res.y;
    float t = time;
    
    vec2 ruv = uv * 10.0;
    ruv += vec2(t);
    
    vec2 id = floor(ruv);
    vec2 fr = fract(ruv);

    vec2 tile = truchetPattern(fr, random(id));
    
    float val = 0.0;
    
    float d = 0.1, w = 7.0 / res.y;
    
    val = 
        ((smoothstep(-w, w, length(tile) - 0.5+d) -
        smoothstep(-w, w, length(tile) - 0.5-d)) +
        (smoothstep(-w, w, length(tile - vec2(1.0)) - 0.5+d) -
        smoothstep(-w, w, length(tile - vec2(1.0)) - 0.5-d)));
    
    vec3 col = hsv2rgb(atan(uv.y, uv.x) * 0.5, length(uv) * 2.0, 1.0) * val * smoothstep(0.5, 0.4, length(uv));
    
    glFragColor = vec4(col,1.0);
}
