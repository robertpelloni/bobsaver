#version 420

// original https://www.shadertoy.com/view/3tdBWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)cos(h*6.3+vec3(0,23,21))*.5+.5
void main(void)
{
    vec2 C = gl_FragCoord.xy;
    vec4 O = glFragColor;
    O=vec4(0);
    vec3 r=vec3(resolution,1.0),p;  
    for(float i=0.,g,e,l,s;
        ++i<99.;
        (e<.002)?O.xyz+=mix(r/r,H(g*.5),.5)*.5/i:p
    )
    {
        p=g*vec3((C-.5*r.xy)/r.y,1);
        p.z-=.4;
        p=R(p,normalize(vec3(1,3,3)),time*.2);
        p=mod(p-1.,2.)-1.;
        p.x<-p.z?p.xz=-p.zx:C;
        s=3.;
        for(int j=0;j++<6;)
            s*=l=2./min(dot(p,p),1.),
            p=abs(p)*l-vec3(1,1,15);
        g+=e=length(cross(p,r/r))/s;
    }

    glFragColor = O;
}
