#version 420

// original https://www.shadertoy.com/view/wlycRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 O = glFragColor;    
    O-=O;
    vec2 r=resolution.xy;
    vec4 p,d=vec4((gl_FragCoord.xy-.5*r)/r.y,1,0);
    for(float i=0.,g,e,l,s;++i<99.;e<.015?O+=abs(cos(d+log(s)))/i:O)
    {
        s=3.;
        p=g*d;
        p.z+=time;
        p.xy=vec2(length(p.xy)-3.,atan(p.x,p.y));
        p.yz=fract(p.yz)-.5;
        p=abs(p);
        for(int i=0;i++<4;)
            p=.8-abs(p-.4),
            p=p*(l=-2./dot(p,p)),
            s*=l;
        g+=e=length(p.yz)/s;
    }
    glFragColor = O;
}
