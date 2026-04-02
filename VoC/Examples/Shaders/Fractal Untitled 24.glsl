#version 420

// original https://www.shadertoy.com/view/tlcBzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O=vec4(0);
    vec3 r=vec3(resolution,1.0),p;  
    for(float i=0.,g=1.,e,s;
        ++i<99.;
        e<.004?O.xyz+=mix(
                r/r,
                cos(vec3(1,2,3)+log(s)*10.)*.5+.5,
                .8
            )*.5/i:p
    )
    {
        p=vec3(g*(gl_FragCoord.xy-.5*r.xy)/r.y,g-10.);
        p=R(p,normalize(R(vec3(1,2,3),vec3(.577),time*.3)),time*.1);
        s=2.;
        p.y=abs(p.y);
        for(int j=0;++j<7;)
            p.xz=abs(p.xz)-2.3,
            p.z>p.x?p=p.zyx:p,
            p.z=1.5-abs(p.z-1.3+sin(p.z)*.2),
            p.y>p.x?p=p.yxz:p,
            p.x=3.-abs(p.x-5.+sin(p.x*3.)*.2),
            p.y>p.x?p=p.yxz:p,
            p.y=.9-abs(p.y-.4),
            e=12.*clamp(.3/min(dot(p,p),1.),.0,1.)+
            2.*clamp(.1/min(dot(p,p),1.),.0,1.),
            p=e*p-vec3(7,1,1),
            s*=e;
        g+=e=length(p)/s;
    }
    glFragColor=pow(O,vec4(1.5,2,1.2,1));
}
