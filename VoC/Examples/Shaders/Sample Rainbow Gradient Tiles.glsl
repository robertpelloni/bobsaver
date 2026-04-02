#version 420

// original https://www.shadertoy.com/view/WsdGRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 sunset(vec2 st) {
    float stretchTime = time/20.0 + st.y/40.0;
    
    float r = 0.7 * abs(cos(stretchTime)) + 0.2;
    float g = 0.6 * abs(cos(stretchTime*9.743)) - 0.4 * sin(stretchTime);
    float b = 0.9 * abs(cos(stretchTime)) + 0.1;

    return vec3(r,g,b);
}

// From the Book of Shaders
vec2 rotate2D(vec2 _st, float _angle){
    _st -= 0.5;
    _st =  mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle)) * _st;
    _st += 0.5;
    return _st;
}

// Box from the book
float box(vec2 _st, vec2 _size, float _smoothEdges){
    _size = vec2(0.5)-_size*0.5;
    vec2 aa = vec2(_smoothEdges*0.5);
    vec2 uv = smoothstep(_size,_size+aa,_st);
    uv *= smoothstep(_size,_size+aa,vec2(1.0)-_st);
    return uv.x*uv.y;
}

void main(void)
{
    float repeat = 8.;
    vec2 st = gl_FragCoord.xy/resolution.y * repeat;
    vec3 color = sunset(st);
    st = fract(st);
    
    float gridWidth = resolution.y/repeat;
    vec2 coords = floor(gl_FragCoord.xy/gridWidth);
    float diag = mod(coords.x + coords.y, 2.) + 1.;

    float rotation = 0.7854 * diag *(1. - time*0.3);

    st = rotate2D(st,rotation);

    // Draw a square
    float bx = box(st,vec2(0.7),10./resolution.y);

    glFragColor = vec4(color * bx, 1.);
}
