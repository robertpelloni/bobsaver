#version 420

// original https://www.shadertoy.com/view/stsXDl

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
        O.xyz+=mix(vec3(1),H(g*.1),.8)*1./e/8e3
    )
    {
        p=g*d;
        p.z+=time*1.5;
        a=10.;
        p=mod(p-a,a*2.)-a;
        s=6.;
        for(int i=0;i++<8;){
            p=.3-abs(p);
            p.x<p.z?p=p.zyx:p;
            p.z<p.y?p=p.xzy:p;
            s*=e=1.4+sin(time*.1)*.1;
            p=abs(p)*e-
                vec3(
                    5.+sin(time*.3+.5*sin(time*.3))*3.,
                    120,
                    8.+cos(time*.5)*5.
                 );
         }
         g+=e=length(p.yz)/s;
    }
    glFragColor=O;
}
