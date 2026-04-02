#version 420

// original https://www.shadertoy.com/view/3ttBWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h) (cos(h*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O = glFragColor;    
    O-=O;
    vec3 r=vec3(resolution.xy,1.0),p;
    float i,g=1.,e=1.,l,s;
    for(i=0.;
        ++i<99.&&e>.001;
        g+=e=length(p)/s
        )
    {
        p=vec3(g*(gl_FragCoord.xy-.5*r.xy)/r.y,g-2.5);
        p=R(p,vec3(.577),time*.2);
        s=2.;
        for(int j=0;++j<10;)
            p=abs(p-.1)-.5,
            p.z>p.x?p=p.zyx:p,
            p.y>p.z?p=p.xzy:p,
            p.z=abs(p.z)-1.2,
            p.y+=.6,
            p.x-=p.y*.8,
            p=3.*p-vec3(9,2,3),
            s*=3.;
    }  
    O.xyz+=mix(r/r,H(g*.25),.5)*8e2/i/i;
    glFragColor = O;
}
