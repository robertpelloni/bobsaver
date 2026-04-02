#version 420

// original https://www.shadertoy.com/view/3tGfzc

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
        ++i<120.;
        e<.002?O+=3.*(cos(vec4(3,8,25,0)+log(s)*.5)+3.)/dot(p,p)/i:O
    )
    {
        p=g*d;
        p-=vec3(0,-1.7,2);
        r=normalize(vec3(1,3,0));
        s=time*.2;
        p=mix(r*dot(p,r),p,cos(s))+sin(s)*cross(p,r);
        p=abs(p);
        p.xz=vec2(atan(p.z,p.x),length(p.xz));
        p.yz=vec2(atan(p.z,p.y),length(p.yz)-2.);
        s=3.;
        s*=e=3./min(dot(p,p),50.);
        p=abs(p)*e;
        for(int i=0;i++<5;)
            p=vec3(2,4,2)-abs(p-vec3(3.8,4.6,2.)),
            s*=e=7./clamp(dot(p,p),.2,5.),
            p=abs(p)*e;
        g+=e=min(length(p.xz)-.2,p.y)/s;
    }
    glFragColor = O;
}
