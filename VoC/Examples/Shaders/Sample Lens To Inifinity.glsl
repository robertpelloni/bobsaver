#version 420

// original https://www.shadertoy.com/view/tl3XRj

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
     vec2 ir = resolution.xy;
    vec2 uv = gl_FragCoord.xy/ir;
    uv-=.5;
    uv.x*=ir.x/ir.y;
    
    uv*=8.-5.*cos(date.w);
    if (length(uv)<3.5) uv*=.5+5.*cos(date.w)/length(uv);
    float col = 1.*length(round(uv)-uv);
    vec4 o = vec4(col);
    o.rb-=.1*(uv);
    if (length(uv)<1.5) o.rb+=.15*(uv);
    glFragColor = o;
}
