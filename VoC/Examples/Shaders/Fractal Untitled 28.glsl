#version 420

// original https://www.shadertoy.com/view/wtdfRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)cos(h*6.3+vec3(0,23,21))*.5+.5
void main(void)
{
    vec4 O=vec4(0);
    vec3 r=vec3(resolution,1.0),p;  
    for(float i=0.,g,e,s;
        ++i<99.;
        (e<.002)?O.xyz+=mix(r/r,H(log(s)*.25),.5)*1./i:p
    )
    {
        p=g*vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1);
        p.z-=2.;
        p=R(p,normalize(vec3(1,1,0)),time*.3);
        p.y-=sin(time*.2)*5.;
        p.xz=abs(p.xz)-1.;
        p.x>p.z?p=p.zyx:p;
        s=3.;
        for(int j=0;j++<7;)
            s*=e=2.7/clamp(dot(p,p),.1,1.7),
            p=abs(p)*e-vec3(1,5,.003);
        g+=e=length(p.xz)/s;
    }
    glFragColor=O;
}
