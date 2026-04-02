#version 420

// original https://www.shadertoy.com/view/7dtBR7

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
        p=R(g*d,normalize(H(t*.1)),g*.1);
        p.z+=t*.5;
        p=asin(.7*sin(p));
        s=2.5+sin(.5*t+3.*sin(t*2.))*.5;
        for(int i=0;i++<6;p=p*e-vec3(3,2.5,3.5))
            p=abs(p),
            p=p.x<p.y?p.zxy:p.zyx,
            s*=e=2.;
        g+=e=abs(length(p.xz)-.3)/s+2e-5;
        c+=mix(vec3(1),H(p.z*.5+t*.1),.4)*.02/exp(.5*i*i*e);
    }
    c*=c;
    glFragColor=vec4(c,1);
}
