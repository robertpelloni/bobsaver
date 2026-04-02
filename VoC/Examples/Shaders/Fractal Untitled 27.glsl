#version 420

// original https://www.shadertoy.com/view/3lcfRX

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
        (e<.001)?O.xyz+=mix(r/r,H(log(s)*.15),.5)*1.5/i:p
    )
    {
        p=g*vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1);
        p.z-=2.5;
        p=R(p,vec3(0,1,0),time*.2);
        p.y-=sin(time*.1)*16.;
        s=3.;
        for(int j=0;j++<8;)
            s*=e=3.8/min(dot(p,p),2.),
            p=abs(p)*e-vec3(1,15,1);
        g+=e=length(cross(p,vec3(1,1,-1)*.577))/s;
    }
    glFragColor=O;
}
