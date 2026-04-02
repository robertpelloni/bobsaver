#version 420

// original https://www.shadertoy.com/view/Nlsczf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec3 p,r=vec3(resolution,1.0),c=vec3(0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));
    float i=0.,s,e,g=0.,t=time;
    for(;i++<90.;){
        p=g*d;
        p=R(p,normalize(H(t*.05)),g*.06);
        p+=vec3(.3,.5,1.5)*t;
        p=abs(asin(.9*sin(p*.4)));
        s=1.;
        vec4 q=vec4(p,.6);
        for(int i=0;i++<7;)
            s*=e=6./min(dot(q,q),5.),
            q=abs(.35-abs(q-.17))*e-vec4(2,2.5,1.5,3);
        g+=e=length(q.xy)*length(q.wz)/s;
        c+=mix(vec3(1),H(p.z*.8),.4)*.015/exp(.03*i*i*e);
    }
    c*=c;
    glFragColor=vec4(c,1);
}
