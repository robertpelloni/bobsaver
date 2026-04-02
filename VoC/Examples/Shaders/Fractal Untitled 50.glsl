#version 420

// original https://www.shadertoy.com/view/NslGDj

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
        O.xyz+=.03*abs(cos(d+log(s)*.8))*exp(-1.5*i*i*e)
    )
    {
        p=g*d;
        p.z-=1.5;
        p=R(p,normalize(vec3(1,2,3)),time*.2);
        q=p;
        s=3.;
        for(int j=0;j++<8;s*=e)
            p=sign(p)*(1.-abs(abs(p-2.)-1.)),
            p=p*(e=6./clamp(dot(p,p),.3,3.))+q-vec3(8,.2,8);
        g+=e=length(p)/s;
    }
    glFragColor=O;
}
