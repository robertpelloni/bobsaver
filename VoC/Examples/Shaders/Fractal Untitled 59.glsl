#version 420

// original https://www.shadertoy.com/view/sd2GW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI (atan(1.)*4.)
#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,s,e,g=0.;
        ++i<90.;
        O.xyz+=mix(vec3(1),H(log(s)*.2),.6)*.02*exp(-.3*i*i*e)
    )
    {
        p=g*d;
        p+=vec3(0,0,time*.5);
        p=R(p,normalize(vec3(1,2,2)),.5);
        p=sin(p+3.*sin(p*.5));
        s=2.;
        for(int i=0;i++<5;)
            p=abs(p-2.7)-1.3,
            s*=e=2./min(dot(p,p),1.5),
            p=abs(p)*e;
        g+=e=length(p)/s;
    }
    glFragColor=O;
}
