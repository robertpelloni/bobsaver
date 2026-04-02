#version 420

// original https://www.shadertoy.com/view/wtyBzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,g=0.,e,s;
        ++i<99.;
        e<.001?O.xyz+=500.*abs(cos(vec3(3,2,1)+log(s)))/length(p)/i/i:p
    )
    {
        p=g*d;
        p.z-=16.;
        p=R(p,normalize(vec3(0,10,1)),time*.5);   
        s=3.;
        p.y=abs(p.y)-1.8;
        p=clamp(p,-3.,3.)*2.-p;
        s*=e=6./clamp(dot(p,p),1.5,50.);
        p=abs(p)*e-vec3(0,1.8,0);
        p.xz =.8-abs(p.xz-2.);
        p.y =1.7-abs(p.y-2.);
        s*=e=12./clamp(dot(p,p),1.0,50.);
        p=abs(p)*e-vec2(.2,1).xyx;
        p.y =1.5-abs(p.y-2.);
        s*=e=16./clamp(dot(p,p),.1,9.);
        p=abs(p)*e-vec2(.3,-.7).xyx;
        g+=e=min(
            length(p.xz)-.5,
            length(vec2(length(p.xz)-12.,p.y))-3.
            )/s;
     }
    glFragColor=O;
}
