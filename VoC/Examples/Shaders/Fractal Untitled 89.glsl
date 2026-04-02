#version 420

// original https://www.shadertoy.com/view/7ssfD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec3 p,r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));
     for(float i=0.,s,e,g=0.,t=time;i++<90.;){
        p=g*d;
        p.z-=.4;
        p=R(p,H(t*.01),t*.2);
        p=abs(p);
        s=3.;
        for(int j=0;j++<6;)
           s*=e=max(1./dot(p,p),3.),
           p=p.x<p.y?p.zxy:p.zyx,
           p=abs(p*e-vec3(5,1,5)),
           p=R(p,normalize(vec3(2,2,1)),2.1);
        g+=e=length(p.xz)/s+1e-4;
        c+=mix(vec3(1),H(log(s)*.3),.4)*.019/exp(.2*i*i*e);
    }
    c*=c*c;
    glFragColor=vec4(c,1);
}
