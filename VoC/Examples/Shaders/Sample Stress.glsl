#version 420

// original https://www.shadertoy.com/view/ltjSWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(in float theta) {
    return mat2(
        cos(theta), -sin(theta), sin(theta), cos(theta)
    );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    vec2 p = -1.0 + 2.* uv;
    
    p.x *= resolution.x/resolution.y;
    
    float t = time*.1 - cos(p.x*.25) - cos(p.y*.25);
    
    p = p*rotate(t);
    
    p *= 10.0;
    
    p = mod(p, 2.0);
    
    float f = length(floor(p));
    
    vec3 c = f * vec3(p.x) + vec3(.1,0.05,0.0);
    
    glFragColor = vec4(c,1.0);
}
