#version 420

// original https://www.shadertoy.com/view/7ssGRs

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
    for(float i=1.,s,e,g=.1;
        ++i<80.;
        O.xyz+=.03*abs(cos(d+.5+log2(s)*.6))*exp(-.3*i*i*e)
    )
    {
        p=g*d-vec3(.1,.2,1);
        p.z-=1.;
        p=R(p,normalize(vec3(1,2,3)),time*.2);
        q=p;
        s=2.;
        for(int j=0;j++<8;)
            p-=clamp(p,-.9,.9)*2.,
            p=p*(e=3./min(dot(p,p),1.))+q,
            s*=e;
            g+=e=length(p)/s;
    }
    O.xyz=pow(O.xyz,vec3(1.8,1.,1.2));
    glFragColor=O;
}
