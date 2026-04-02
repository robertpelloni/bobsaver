#version 420

// original https://www.shadertoy.com/view/WldfW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O=vec4(0);
    vec3 r=vec3(resolution.xy,1.0),p;  
    for(float i=0.,g=0.,e,s;
        ++i<99.;
        e<.004?O.xyz+=mix(
                r/r,
                cos(p*.3+g*3.)*.5+.5,
                .8
            )*27./i/i:p
    )
    {
        p=vec3(g*(gl_FragCoord.xy-.5*r.xy)/r.y-2.,g);
        p=R(p,normalize(R(vec3(1,2,3),vec3(.577),time*.2)),time*.1);
        s=2.;
        p.y=abs(p.y-1.);
        for(int j=0;++j<8;)
            p.xz=abs(p.xz),
            p.z>p.x?p=p.zyx:p,
            p.z=1.2+clamp(-.8,.3,cos(time*.7))*.1
                -abs(p.z-.8+clamp(-.6,.6,sin(time*.5))*.1),
            p.y>p.x?p=p.yxz:p,
            p.x-=2.5,
            p.y>p.x?p=p.yxz:p,
            p.y+=.1,
            p=3.*p-vec3(6,1,1),
            s*=3.;
        g+=e=length(p)/s;
    }
    glFragColor=pow(O,vec4(1.5,1,1.8,1));
}
