#version 420

// original https://www.shadertoy.com/view/sssGWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,q,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,s,e,g=0.;
        ++i<80.;
        O.xyz+=.02*abs(cos(d+log(s)*.3))*exp(-.5*i*i*e)
    )
    {
        p=g*d;
        p-=vec3(1.,.1,.1);
        p=R(p,normalize(vec3(1,2,3)),time*.2);
        q=p;
        s=1.5;
        for(int j=0;j++<15;s*=e)
            p=sign(p)*(1.2-abs(p-1.2)),
            p=p*(e=8./clamp(dot(p,p),.3,5.5))+q*2.;
        g+=e=length(p)/s;
    }
    glFragColor=O;
}
