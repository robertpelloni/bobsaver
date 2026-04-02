#version 420

// original https://www.shadertoy.com/view/7lsSDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,s,e,g=0.;
        ++i<160.;
        O.xyz+=mix(vec3(1),H(g*.15),.8)*.01*exp(-10./e/i/i)
    )
    {
        p=g*d;
        p.z-=2.;
        p=R(p,normalize(vec3(1,2,3)),time*.1);
        s=2.;
        for(int i=0;i++<12;p=abs(p)*e-vec3(1,2,1))
            p=.5-abs(p-.6),
            p.x<p.z?p=p.zyx:p,
            p.z<p.y?p=p.xzy:p,
            s*=e=1.3;
        g+=e=abs(p.z)/s;
    }
    glFragColor=O;
}
