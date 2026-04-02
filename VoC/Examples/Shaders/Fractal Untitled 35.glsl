#version 420

// original https://www.shadertoy.com/view/WlGBzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,g=0.,e,s;
        ++i<99.;
        e<.001?O+=3.*(cos(vec4(3,8,25,0)+log(s)*.5)+3.)/dot(p,p)/i:O
    )
    {
        p=g*d;
        p-=vec3(0,-.9,1.5);
        r=normalize(vec3(1,8,0));
        s=time*.2;
        p=mix(r*dot(p,r),p,cos(s))+sin(s)*cross(p,r);
        s=2.;
        s*=e=3./min(dot(p,p),20.);
        p=abs(p)*e;
        for(int i=0;i++<4;)
            p=vec3(2,4,2)-abs(p-vec3(4,4,2)),
            s*=e=8./min(dot(p,p),9.),
            p=abs(p)*e;
        g+=e=min(length(p.xz)-.15,p.y)/s;
    }
    glFragColor = O;
}
