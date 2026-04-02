#version 420

// original https://www.shadertoy.com/view/7dlXzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI (atan(1.)*4.)
#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
#define M(p,n)vec2(asin(sin(atan(p.x,p.y)*n))/n,1)*length(p)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,q,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,s,e,g=0.;
        ++i<90.;
        O.xyz+=mix(vec3(1),H(length(q)*.5),.7)*.01*exp(-8.*i*i*e)
    )
    {
        p=g*d;
        p.z-=10.;
        q=p=R(p,normalize(vec3(1,2,2)),time*.5);
        s=3.;
        for(int i=0;i++<8;){
            p.xy= M(p.xy,4.);
            p.y-=1.;
            p.zy = M(p.zy,3.);
            p.y-=3.;
            s*=3.;
            p*=3.;
        }
        g+=e=length(p.xy)/s-.001;
    }
    glFragColor=O;
}
