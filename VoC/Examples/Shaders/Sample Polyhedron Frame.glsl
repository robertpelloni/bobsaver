#version 420

// original https://www.shadertoy.com/view/7tS3Dy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),n=vec3(-.5,-.707,.5),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy),r.y));  
    for(float i=0.,e,g=0.;
        ++i<99.;
        O.xyz+=mix(vec3(1),H(length(p)*.5+time*3.),.7)*.05*exp(-.03*i*i*e)
    )
    {
        p=g*d;
        p.z-=10.;
        p=R(p,normalize(vec3(-1,-2,2)),time*.5);
        for(int j=0;j<4;j++)
            p.xy=abs(p.xy),
            p-=2.*min(0.,dot(p,n))*n;
        p.z=fract(log(p.z)-time*.5)-.5;
        g+=e=abs(min(length(p.yz),length(p.xz))-.03)+.001;
    }
    glFragColor=O;
}
