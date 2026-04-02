#version 420

// original https://www.shadertoy.com/view/ttKyD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O = glFragColor;
    O-=O;
    float i,g,e=1.,s,B=2.95,H=.9;
    vec3 r=vec3(resolution,0.0),p;
    for(i=0.;
        ++i<99.&&e>.001;
        g+=e=length(p.xy)/s-.007
        )
    {
        p=g*vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1);
        p=R(p,normalize(vec3(1,2,3)),sin(time*.3+.5*sin(time*.2))*.5+.6);
        p.z+=time; 
        s=2.;
        p.z=mod(p.z-2.,4.)-2.;
        for(int j=0;j++<8;)
        {
            p=abs(p);
            p.x<p.z?p=p.zyx:p;
            p.x=H-abs(p.x-H);
            p.y<p.z?p=p.xzy:p;
            p.xz+=.1;
            p.y<p.x?p=p.yxz:p;
            p.y-=.1;
        }
        p*=B;
        p-=2.5;
        s*=B;
    }  
    O.xyz+=mix(vec3(1),cos(vec3(8,5,3)+p*10.),.4)*20./i;
    glFragColor = O;
}
