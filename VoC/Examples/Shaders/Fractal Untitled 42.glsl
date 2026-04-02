#version 420

// original https://www.shadertoy.com/view/fdfGR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O=vec4(0);
    vec3 q=vec3(3,3,.0),
    p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,s,e,g=.3;
        ++i<99.;
        O.xyz+=cos(vec3(7,6,9)/log(s*.2))*.02
    )
    {
        p=g*d-vec3(.4,.1,.8);
        p=R(p,normalize(vec3(1,2,3)),-time*.1);
        s=2.;
        for(int i=0;
            i++<7;
            p=q-abs(p-q*.4)
        )
            s*=e=15./min(dot(p,p),15.),
            p=abs(p)*e-2.;
        g+=min(10.,length(p.xz)-.5)/s;
    }
    O.xyz=pow(O.xyz,vec3(1.5,3.6,.2));
    glFragColor=O;
}
