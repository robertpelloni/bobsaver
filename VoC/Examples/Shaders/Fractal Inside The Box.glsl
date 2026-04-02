#version 420

// original https://www.shadertoy.com/view/wlyczd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(a) mat2(cos(a),sin(a),-sin(a),cos(a))
void main(void)
{
    vec4 O = glFragColor;
    O-=O;
    vec3 r=vec3(resolution.xy,0.0),p,q,d=vec3((gl_FragCoord.xy-.5*r.xy)/r.y,.6);
    for(float i=0.,g,e,l,s;++i<80.;e<.001?O.xyz+=abs(cos(d+log(s)))/i:p)
    {
        s=4.;
        p=g*d;
        p.z-=.9;
        p.xy*=R(time*.2);
        p.yz*=R(time*.3);
        q=p;
        s=2.;
        for(int j=0;j++<9;)
            p-=clamp(p,-1.,1.)*2.,
            p=p*(l=8.8*clamp(.72/min(dot(p,p),2.),0.,1.))+q,
            s*=l;
        g+=e=length(p)/s;
    }
    glFragColor = O;
}
