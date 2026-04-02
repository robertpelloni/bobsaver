#version 420

// original https://www.shadertoy.com/view/7tsSDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,q,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy*2.-r.xy)/r.y,1));  
    for(float i=0.,a,s,e,g=0.;
        ++i<70.;
        O.xyz+=mix(vec3(1),H(g*.15),.8)*1./e/8e3
    )
    {
        p=g*d;
        p.z-=3.5;
        p=R(p,normalize(vec3(1,2,3)),time*.3);
        s=1.;
        for(int i=0;i++<12;p=abs(p)*e-vec3(1,2,1))
            p=.2-abs(p-.6),
            p.x<p.z?p=p.zyx:p,
            p.z<p.y?p=p.xzy:p,
            s*=e=1.22;
         g+=e=abs(p.x)/s+.001;
    }
    glFragColor=O;
}
