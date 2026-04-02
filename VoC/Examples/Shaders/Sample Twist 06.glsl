#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main()
{
    vec2 r = resolution,
    o = gl_FragCoord.xy - r/2.;
    o = vec2(length(o) / r.y - .3, atan(o.y,o.x));    
    vec4 s = .07*cos(1.5*vec4(0,1,2,3) + time + o.y + cos(o.y) * cos(time)),
    e = s.yzwx, 
    f = max(o.x-s,e-o.x);
    glFragColor = dot(clamp(f*r.y,0.,1.), 72.*(s-e)) * (s-.1) + f;
}
