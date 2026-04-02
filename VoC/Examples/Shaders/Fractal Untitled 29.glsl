#version 420

// original https://www.shadertoy.com/view/ttdBRf

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
        (e<.002)?O.xyz+=mix(r/r,H(log(s)*.25),.7)*1./i:p
    )
    {
        p=g*vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1);
        p.z-=6.;
        p=R(p,normalize(vec3(1,1,0)),time*.3);
        p.y-=.5;
        p.xz=vec2(atan(p.z,p.x),length(p.xz)-2.5);
        p.yz=vec2(atan(p.z,p.y),length(p.zy)-1.);
        p.z=abs(p.z)-.3;
        p.z=abs(p.z)-.3;
        s=3.;
        for(int j=0;j++<8;)
            s*=e=2.3/clamp(dot(p,p),.1,1.6),
            p=abs(p)*e-vec3(6.5,2,.005);
        g+=e=length(p.xz)/s;
    }
    glFragColor=O;
}
