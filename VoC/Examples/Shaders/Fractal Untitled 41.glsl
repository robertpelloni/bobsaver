#version 420

// original https://www.shadertoy.com/view/wlyBDt

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
    for(float i=1.,g=0.,e,s;
        ++i<99.;
        O.rgb+=mix(vec3(1),H(log(s)/6.+.9),.2)*pow(abs(cos(i*i/20.)),3.)/e/1e5
    )
    {
        p=g*d-vec3(.3,.1,2);
        p=R(p,normalize(vec3(1,2,3)),time*.4);
        p.xz=vec2(atan(p.z,p.x),length(p.xz));
        p.yz=vec2(atan(p.z,p.y),length(p.yz));
        p.z=fract(log(p.z)-time*.2)-.5;
        s=2.5;
        for(int j=0;j++<6;p=abs(p)*e-vec3(1.8,3,.01))
            s*=e=5./min(dot(p,p),2.8);
        g+=e=abs(length(p.yz)/s-5e-4)+1e-4;
    }
    glFragColor=O;
}
