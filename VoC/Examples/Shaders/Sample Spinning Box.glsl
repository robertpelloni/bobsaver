#version 420

// original https://www.shadertoy.com/view/3lSBRV

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
    _size = vec2(0.5)-_size*0.5;
    vec2 aa = vec2(_smoothEdges*0.5);
    vec2 uv = smoothstep(_size,_size+aa,_st);
    uv *= smoothstep(_size,_size+aa,vec2(1.0)-_st);
    return uv.x*uv.y;
}

vec3 col255to1(vec3 col) {
    return col / 255.;
}

void main(void)
{
    // st or uv, both are the same
    vec2 st = gl_FragCoord.xy/resolution.xy;
    st.x *= resolution.x/resolution.y;
    
    vec3 jet = col255to1(vec3(51., 53., 51.));
    vec3 timberwolf = col255to1(vec3(207., 219., 213.));
    
    st *= 5.;
    float isOdd = step(1., mod(st.y, 2.));
    st.x += isOdd * 0.5 * time;
    st.x -= (1.-isOdd) * 0.5 * time;
    st = fract(st);
    vec2 st1 = st;
    
    st = rotate2D(st, PI * .25);
    float box1 = box(st, vec2(.5), 0.001);
    float box2 = box(st, vec2(.4), 0.001);
    float finBox = 1. - (box1 - box2);
    
    st1 = rotate2D(st1, ((isOdd * 2. - 1.)) * time * 2.);
    float cross = 1. - (box(st1, vec2(.2, 1.), .001) + box(st1, vec2(1., .2), .001));
    
    float final = finBox + cross;
    
    vec3 color = vec3(final);
    color = step(1., length(color)) * timberwolf + (1. - step(1., length(color))) * jet;

    glFragColor = vec4(color,1.0);
}
