#version 420

// original https://www.shadertoy.com/view/7ddXRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec2 C = gl_FragCoord.xy;
    vec3 p,r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3((C-.5*r.xy)/r.y,1));
    float i=0.,s,e,g=0.;
    for(;++i<99.;)
    {
        p=g*d;
        p.z+=time*.8;
        p=R(p,vec3(.577),.3);
        s=2.;
        p=cos(p);
        for(int i=0;i++<7;)
        {
            p=1.8-abs(p-1.2);
            p=p.x<p.y?p.zxy:p.zyx;
            s*=e=4.5/min(dot(p,p),1.5);
            p=p*e-vec3(.2,3,4);
        }
        g+=e=length(p.xz)/s;
        c+=mix(vec3(1),H(log(s*5.)),.3)*.01*exp(-9./i/i/e);
    }
    c*=c;
    glFragColor=vec4(c,1);
}
