#version 420

// original https://www.shadertoy.com/view/fdfGzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=1.,s,e,g=.2,l;
        ++i<80.;
        O+=abs(cos(vec4(4,3,24,1)+log(s)*.8))*s*1e-4/i
    )
    {
        p=g*d-vec3(.1,.2,1);
        p=R(p,normalize(vec3(1,2,3)),time*.2);
        s=2.;
        l=dot(p,p);
        p=abs(abs(p)-.7)-.5;
        p.x<p.y?p=p.yxz:p;
        p.y<p.z?p=p.xzy:p;
        for(int i=0;i++<8;){
            s*=e=2./clamp(dot(p,p),.004+tan(10.*sin(time*.2))*.002,1.35);
            p=abs(p)*e-vec2(.5*l,12.).xxy;
        }
        g+=e=length(p-clamp(p,-1.,1.))/s;
    }
    O.xyz=pow(O.xyz,vec3(1.1,.6,.5));
    glFragColor=O;
}
