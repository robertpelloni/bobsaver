#version 420

// original https://www.shadertoy.com/view/3dcSDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate2D(vec2 _st, float _angle){
    _st =  mat2(cos(_angle),-sin(_angle),sin(_angle),cos(_angle)) * _st;
    return _st;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    vec2 polar = vec2(length(uv), atan(uv.y / uv.x));   
    uv = rotate2D(uv, time);    
    vec3 bg = vec3(sin((abs(uv.x) + abs(uv.y)) * 2. - time), sin((abs(uv.x) + abs(uv.y)) *3.  - time), sin((abs(uv.x) + abs(uv.y)) *4.  - time));    
    float glowy = length(uv) * 2. * smoothstep(0.1, sin(length(vec2(polar.x, polar.y)) * 5. - time *2.), 0.3);        
    vec3 col = clamp(glowy * bg + bg * 0.5 + glowy * 0.5, -.4 ,1.);
    glFragColor = vec4(col,1.0);
}
