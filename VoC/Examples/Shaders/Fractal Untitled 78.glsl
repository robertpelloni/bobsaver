#version 420

// original https://www.shadertoy.com/view/Nt3GR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void) //WARNING - variables void (out vec4 O, vec2 C) need changing to glFragColor and gl_FragCoord.xy
{
    vec3 p,r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));
    float i=0.,s,e,g=0.,t=time;
    for(;++i<99.;)
    {
        p=g*d;
        p=R(p,vec3(.577),t*.2);  
        p.z-=t;
        p=sin(p);
        s=2.;
        for(int i=0;i++<5;)
        {
           s*=e=2./min(dot(p,p),1.);
           p=abs(p)*e-vec3(3,20,9);
        }
        g+=e=abs(length(p.xy-clamp(p.xy,-.5,.5))/s)+.005;        
        c+=mix(vec3(1),H(log(s)*.5),.3)*12e-5*exp(sin(i))/e;
    }
    c*=c*c*c*c;
	glFragColor=vec4(c,1);
}
