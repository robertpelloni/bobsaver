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
    vec4 s = .03*cos(4.5*vec4(0,1,2,3) + time + o.y*5.0 + cos(o.y*10.0) * cos(time*0.5)),
    e = s.yzwx, 
    f = max(o.x-s,e-o.x);
    glFragColor = dot(clamp(f*r.y,0.,2.), 72.*(s-e)) * (s-.1) + f;
}
