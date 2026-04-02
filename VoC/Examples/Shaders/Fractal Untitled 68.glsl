#version 420

// original https://www.shadertoy.com/view/ftjXRD

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
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,s,e,g=.3;
        ++i<90.;
        O.xyz+=mix(vec3(1),H(log(s)*.3),.8)*.03*exp(-i*i*e)
    )
    {
        p=g*d;
        p+=vec3(.3,.3,-1.8);
        p=R(p,vec3(.577),time*.1);
        s=3.;
        for(int j=0;j++<8;)
            p=clamp(p,-.5,.5)*2.-p,
            s*=e=7.*clamp(.3/min(dot(p,p),1.),.0,1.),
            p=p*e+q;
        g+=e=length(p)/s;
    }
    glFragColor=O;
}
