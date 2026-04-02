#version 420

// original https://www.shadertoy.com/view/NsXyzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec3 p,r=vec3(resolution.xy,1.0),c=vec3(0),
    //d=normalize(vec3((C-.5*r.xy)/r.y,1));
    d=normalize(vec3(gl_FragCoord.xy-.5*r.xy,r.y));     // thanks Xor
     for(float i=0.,s,e,g=0.,t=time;i++<90.;){
        p=g*d;
        p.z-=4.;
        p=R(p,normalize(vec3(1,3,.5)),t*.4);
        s=1.5;
        vec4 q=vec4(p,.6);
        for(int j=0;j++<4;)
            q=abs(q)-.5,
            s*=e=3.5/clamp(dot(q,q),.4,3.),
            q=q*e-vec4(1,1,2,1);
        g+=e=abs(length(q.zw)-.5)/s+1e-5;
        c+=mix(vec3(1),H(log(s)*.07),.5)*.02/exp(.3*i*i*e);
    }
    c*=c*c;
    glFragColor=vec4(c,1);
}
