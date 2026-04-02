#version 420

// original https://www.shadertoy.com/view/4lBGRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 cmult(vec2 c1, vec2 c2) {
    return vec2
        ( c1.x * c2.x - c1.y * c2.y 
        , c1.x * c2.y + c2.x * c1.y
        );
}

vec2 cdiv(vec2 c1, vec2 c2) {
    float d = c2.x * c2.x + c2.y * c2.y;
    
    return vec2
        ( c1.x * c2.x + c1.y * c2.y 
        , c2.x * c1.y - c1.x * c2.y
        ) / d;
}

vec2 step(vec2 x) {
    float t = time * 3.0;
    vec2 p = vec2(cos(t), sin(t));
    vec2 q = vec2(cos(t * 0.9), sin(t * 0.9));
    vec2 r = vec2(cos(t * 1.1), sin(t * 1.1));
    vec2 s = vec2(cos(t * 1.2), sin(t * 1.2));
    
    return x - cdiv(
        cmult(p, cmult(cmult(x, x), x)) +
        cmult(q, cmult(x, x)) +
        s,
        3.0 * cmult(p, cmult(x, x)) +
        2.0 * cmult(q, x));
}

vec2 iter(vec2 x) 
{
    for (int i = 0; i < 50; i++) {
        x = step(x);
    }
  
    return x;   
}

void main(void)
{    
    vec2 x = gl_FragCoord.xy / resolution.xy * 3.0 - vec2(1.5, 1.5);
    
    float d = cos(atan(iter(x).y, iter(x).x)) * 0.3 + 0.5;
    
    glFragColor = vec4(d, d, d * 2.0, 1.0);  
}
