#version 420

// original https://www.shadertoy.com/view/sdS3zt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,s,e,g=0.;
        ++i<90.;
        O.xyz+=mix(vec3(1),H(log(s)*.6),.8)*.001/e/i
    )
    {
        p=g*d-vec3(0,0,1.5);
        p=R(p,normalize(vec3(1,2.*sin(time*.1),3)),time*.2);
        s=5.;
        p=p/dot(p,p)+1.;
        for(int i=0;i++<8;)
            p=abs(p-vec3(.8,2,1.5))-vec3(1,1.5,2.5),
            s*=e=1.6/clamp(dot(p,p),.2,1.5),
            p*=e;
        g+=e=abs(p.x)/s+1e-3;
    }
    glFragColor=O;
}
