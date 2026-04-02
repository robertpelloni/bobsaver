#version 420

// original https://www.shadertoy.com/view/fsSXz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash21(vec2 v) 
{
    return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453123);
}

mat2 Rot(float a)
{
    return mat2(sin(a), cos(a), -sin(a), cos(a));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;  
    uv = uv * Rot(radians(-45.0));
    
    uv *= (sin(time*1.0) + 1.0) * 20. + 5.;
    uv.x += time * 7.;

    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);
                
    float d = 0.;
    float dir = hash21(id) < 0.5 ? -1. : 1.;

    d += smoothstep(0.25, 0.15, abs(gv.x  + gv.y * dir));
    
    vec3 col = vec3(d);    

    glFragColor = vec4(col,1.0);
}
