#version 420

// original https://www.shadertoy.com/view/fsf3Wf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,q,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,s,e,g=0.;
        ++i<90.;
        O.xyz+=.1*H(log(s)*.1+.2)*exp(-2.*i*i*e)
    )
    {
        p=g*d-vec3(-.2,.3,2.5);
        p=R(p,normalize(vec3(1,2.*sin(time*.1),3)),time*.2);
        q=p;
        s=4.;
        for(int j=0;j++<6;s*=e)
            p=sign(p)*(1.-abs(abs(p-2.)-1.)),
            p=p*(e=6./clamp(dot(p,p),.1,3.))-q*vec3(2,8,1)-vec3(5,2,1);
        g+=e=length(p)/s;
    }
    glFragColor=O;
}
