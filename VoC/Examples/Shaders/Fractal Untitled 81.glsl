#version 420

// original https://www.shadertoy.com/view/ssXyz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec3 p,q,r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));
    float i=0.,s,e,g=0.,t=time;
    for(;i++<90.;){
        p=g*d;
        p.z-=mix(.9,9.,step(0.,sin(t*.3)));
        p=R(p,normalize(cos(t*.5+vec3(1,8,3))),clamp(sin(t*.3)*3.,-5.,.5));
        p=abs(p);
        q=p*1.5;
        s=3.;
        for(int i=0;i++<8;)
            p=1.-abs(abs(p-2.)-1.),
            s*=e=-13.*min(.3*max(1./dot(p,p),.8),1.),
            p=p*e+q;
        g+=e=length(p)/s-.003;
        c+=mix(vec3(1),H(log(s)*.2+t*.6),.6)*.01/exp(i*i*e);  
    }
    glFragColor=vec4(c,1);
}
