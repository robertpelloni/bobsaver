#version 420

// original https://www.shadertoy.com/view/WtGyWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define fold(p,v)p-2.*min(0.,dot(p,v))*v;
void main(void)
{
    vec4 O = glFragColor;
    O-=O;
    vec3 r=vec3(resolution,0.0),p;
    float i,g,e=1.,l,s;
    for(i=0.;
        ++i<99.&&e>.001;
        g+=e=length(p.xy)/s
        )
    {
        p=g*vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1);
        p=R(p,normalize(vec3(1)),time*.2);
        p.z-=-1.;
        p.x-=sin(.4*time+.5*sin(time*.5))*.2;
        p.y-=cos(.7*time+.5*cos(time*.5))*.2;
        s=3.;
        for(int i = 0;++i<15;)
        {
            p.xy=fold(p.xy,normalize(vec2(1,-1.3)));
            p.y=-abs(p.y);
            p.y+=.5;
            p.xz=abs(p.xz);
            p.yz=fold(p.yz,normalize(vec2(8,-1)));
            p.x-=.5;
            p.yz=fold(p.yz,normalize(vec2(1,-2)));
            p-=vec3(1.8,.4,.1);
            l = 2.6/dot(p,p);
            p*=l;
            p+=vec3(1.8,.7,.2);
            s*=l;
        }
    }  
    O.xyz+=mix(vec3(1),cos(vec3(5,18,3)+p*10.),.5)*500./i/i;
    glFragColor = O;
}
