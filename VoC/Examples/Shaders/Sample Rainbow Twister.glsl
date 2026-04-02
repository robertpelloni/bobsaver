#version 420

// original https://www.shadertoy.com/view/XsSfW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//With AA (243 c)
void main(void)
{
    vec2 r = resolution.xy;
    vec2 o = gl_FragCoord.xy;
    o -= r/2.;
    o = vec2(length(o) / r.y - .3, atan(o.y,o.x));    
    vec4 s = .1*cos(1.6*vec4(0,1,2,3) + time + o.y + sin(o.y) * sin(time)*2.),
    e = s.yzwx, 
    f = min(o.x-s,e-o.x);
    glFragColor = dot(clamp(f*r.y,0.,1.), 40.*(s-e)) * (s-.1) - f;
}
