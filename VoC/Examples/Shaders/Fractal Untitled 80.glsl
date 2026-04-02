#version 420

// original https://www.shadertoy.com/view/fsXyR8

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
    float i=0.,s,e,g=0.,t=time;
    for(;i++<99.;){
        p=g*d;
        p.z-=.3;
        p=R(p,cos(t+vec3(1,8,3)),clamp(sin(t*.5)*3.,-5.,.5));
        s=3.;
        for(int j=0;j++<7;)
            p=abs(p.zxy),
            s*=e=2./min(20.,dot(p,p)),
            p=p*e-vec3(.1,.2,.8);
        g+=e=min(length(p.z)+.3,length(p.yz)-.1)/s;
        c+=mix(vec3(1),H(log(s)*.2+t*.2),H(log(s)*.5))*.01/exp(i*i*e);  
    }
    glFragColor=vec4(c,1);
}
