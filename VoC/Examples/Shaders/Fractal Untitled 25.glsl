#version 420

// original https://www.shadertoy.com/view/wldBR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)cos(h*6.3+vec3(0,23,21))*.5+.5
void main(void)
{
    vec4 O=vec4(0);
    vec3 r=vec3(resolution,1.0),p;  
    for(float i=0.,g,e,s;
        ++i<99.;
        (e<.005)?O.xyz+=mix(r/r,H(g*.5),.6)*.05*exp(-g*10.):p
    )
    {
        p=g*vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1);
        p-=vec3(.02,.01,.08);
        p=R(p,normalize(vec3(1,3,3)),time*.2);
        p+=p;
        s=2.;
        for(int j=0;++j<7;)
            s*=e=1.8/min(dot(p,p),1.2),
            p=abs(p)*e-3.;
        g+=e=length(p.yz)/s;
    }
    glFragColor=O;
}
