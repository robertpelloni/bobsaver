#version 420

// original https://www.shadertoy.com/view/styfWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec3 r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3(gl_FragCoord.xy-.5*r.xy,r.y));
    float i=0.,s,e,g=0.,t=time;
    for(;i++<99.;){
        vec4 p=vec4(g*d,.08);
        p.z-=.7;
        p.xyz=R(p.xyz,normalize(H(t*.05)),t*.2);
        s=1.;
        for(int j=0;j++<7;)
            p=.04-abs(p-.2),
            s*=e=max(1./dot(p,p),1.3),
            p=abs(p.x<p.y?p.wzxy:p.wzyx)*e-.9;
        e=abs(length(p.wz*p.x-p.y)/s-.04);
        g+=e+1e-4;
        c+=mix(vec3(1),H(log(s)*.9),.5)*.04/exp(i*i*e);
    }
    c*=c;
  glFragColor=vec4(c,1);
}
