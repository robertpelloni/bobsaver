#version 420

// original https://www.shadertoy.com/view/fsXczS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec3 p,k,r=vec3(resolution,1.0),c=vec3(0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));
     for(float i=0.,s,e,g=0.,t=time;i++<90.;){
        p=g*d;
        p.z-=.8;
        k=p;
        p=R(p,normalize(vec3(1,.1,.3)),t*.4);
        s=2.;
        vec4 q=vec4(p,.5);
        for(int j=0;j++<8;)
            q=abs(q),
            q=q.x<q.y?q.zwxy:q.zwyx,
            s*=e=2.5/min(dot(q,q),2.),
            q=q*e-vec4(1,3,1,1);
        g+=e=min(k.y+.2,abs(q.w)/s+1e-4);
        c+=mix(vec3(1),H(p.z*.2),.4)*.02/exp(.1*i*i*e);
    }
    c*=c*c;
    glFragColor=vec4(c,1);
}
