#version 420

// original https://www.shadertoy.com/view/wtyGDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323846

vec2 rotate2D(vec2 _st, float _angle){
    _st -= 0.5;
    _st =  mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle)) * _st;
    _st += 0.5;
    return _st;
}

vec2 tile(vec2 _st, float _zoom){
    _st *= _zoom;
    return fract(_st);
}

float box(vec2 _st, vec2 _size, float _smoothEdges){
    _size = vec2(0.4)-_size*0.5;
    vec2 aa = vec2(_smoothEdges*0.5);
    vec2 uv = smoothstep(_size,_size+aa,_st);
    uv *= smoothstep(_size,_size+aa,vec2(1.0)-_st);
    return uv.x*uv.y;
}

float check(vec2 _st){
    float ratio = (sin(time * PI * 0.5)+1.0) / 2.0;
    vec2 v_ratio = vec2(cos(time* PI)*0.5+0.5, sin(time*PI)*0.5 + 0.5);
    v_ratio = vec2(fract(time));
    float res = step(v_ratio.x, _st.x);
    float res2 = step(v_ratio.y, _st.y);
    float res3 = step(_st.x, v_ratio.x);
    float res4 = step(_st.y, v_ratio.y);
    return res * res2 + res3 * res4;
}

vec2 scale(vec2 _st, vec2 _scale)
{
    return mat2(_scale.x, 0.0,
               0.0, _scale.y) * _st;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec3 color = vec3(0.0);

    uv = tile(uv,3.0);
    
    vec2 uv2 = gl_FragCoord.xy/resolution.xy;
    uv2 = tile(uv2,4.0);

    uv = rotate2D(uv, time * PI);

    vec3 pink = vec3(1.000,0.604,0.887);
    vec3 white = vec3(1.0);
    vec3 waterblue = vec3(0.545,0.933,1.000);
    
    vec3 pattern = vec3(box(uv,vec2(0.5),0.01));
    vec3 rev_pattern = vec3(1.0) - pattern;
        
    color += pattern * pink;
    color += rev_pattern * waterblue;
    
    vec3 checkpattern = vec3(check(uv2));
    vec3 rev_checkpattern = vec3(1.0) - checkpattern;
    vec3 color2 = checkpattern * pink + rev_checkpattern;
    
    vec3 result = color2 * color;

    glFragColor = vec4(result,1.0);
}
