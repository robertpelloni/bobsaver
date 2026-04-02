#version 420

// original https://www.shadertoy.com/view/Ndfczl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec3 r=vec3(resolution.xy,1.0),c=vec3(0);
    vec4 p,d=normalize(vec4(gl_FragCoord.xy-.5*r.xy,r.y,.5));
     for(float i=0.,s,e,g=0.,t=time;i++<80.;){
        p=g*d;
        p.xyz=R(p.xyz,normalize(H(t*.07)*2.-1.),g*.3);
        p.z+=t*.3;
        p=asin(cos(p))-1.;
        s=1.;
        for(int i=0;i++<8;)
            p=p.x<p.y?p.wzxy:p.wzyx,
            s*=e=2.2/min(dot(p,p),1.6),
            p=abs(p)*e-vec4(.45,.25,1.25,1.21);
        g+=e=abs(p.w)/s+1e-4;
        c+=mix(vec3(1),H(log(s)*.3+t*.2),.4)*.025/exp(i*i*e);
    }
    c*=c;
    glFragColor=vec4(c,1);
}
