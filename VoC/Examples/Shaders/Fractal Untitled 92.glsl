#version 420

// original https://www.shadertoy.com/view/fsSfWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec3 p,r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,3));
    vec4 q;
    float i=0.,s,e,g=0.,t=time;
    for(;i++<99.;)
    {
        p=g*d;;
        p.xyz=R(p.xyz,normalize(H(t*.05)*2.-1.),g*.2);
        p.z+=t*.3;
        p=asin(cos(p*.8));
        q=vec4(p,.7+.005*sin(t*.05));
        s=1.;
        for(int i=0;i++<8;)
            s*=e=max(3./dot(q,q),1.),
            q=.1-abs(q-.1),
            q=abs(q.x<q.y?q.wzxy:q.wzyx)*e-vec4(.3,.8,1.2,1.2);
        g+=e=max(-q.w,q.z)/s;
        c+=mix(vec3(1),H(log(s*.1)+t*2.),.6)*.02/exp(.2*i*i*e);  
    }
    c*=c*c*c;
    glFragColor=vec4(c,1);
}
