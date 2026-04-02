#version 420

// original https://www.shadertoy.com/view/slfyR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec3 p,r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,.7));
    float i=0.,s,e,g=0.,t=time;
    for(;i++<90.;){
        p=g*d;
        p=R(p,normalize(H(t*.1)),g*.1);
        p.z+=t;
        p=abs(asin(.7*sin(p)));
        s=1.5;
        vec4 q=vec4(p,.5);
        for(int i=0;i++<7;)
            s*=e=max(1.1/dot(q,q),1.2),
            q=abs(q-.04)*e-vec4(.7,1.2,1.1,1.2);
        g+=e=length(q.xz)*length(q.wy)/s;
        c+=mix(vec3(1),H(p.z*.8),.6)*.02/exp(.05*i*i*e);
    }
    c*=c;
    glFragColor=vec4(c,1);
}
