#version 420

// original https://www.shadertoy.com/view/sss3R8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O=vec4(0);
    vec3 q=vec3(2.6,2.8,2.1)+
           vec3(cos(time*.6+.5*cos(time*.3))*.3,sin(time*.5)*.1,sin(time*1.2)*.2),
    p,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=1.,s,e,g=0.;
        ++i<80.;
        O.xyz+=cos(vec3(9,3,4)+log(s))*5./dot(p,p)/i
    )
    {
        p=g*d-vec3(0,-.6,2.2);
        p=R(p,normalize(vec3(1,8,0)),-time*.15);
        s=2.;
        s*=e=6./dot(p,p);
        p*=e;
        for(int i=0;i++<2;)
        {
            p=q-abs(p-q);
            s*=e=9./min(dot(p,p),6.);
            p=abs(p)*e;
        }
        g+=e=min(length(p.xz)-.2,p.y)/s;
    }
    glFragColor=O;
}
