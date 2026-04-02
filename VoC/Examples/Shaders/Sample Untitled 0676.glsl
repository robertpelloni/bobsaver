#version 420

// original https://www.shadertoy.com/view/csBGRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define R2(p,t) p*cos(t)+vec2(p.y,-p.x)*sin(t)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void) //WARNING - variables void (out vec4 O, vec2 C) need changing to glFragColor and gl_FragCoord.xy
{
    vec3 p,q,r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1.));
    float i=0.,e,g=0.,t=time;
    for(;i++<90.;)
    {
        p=R(g*d,normalize(H(t*.03)*2.-1.),g*.02);
        q=p;
        p.z+=t*3.;
        p=abs(fract(p)-.5);
        e=length(p)-.15;
        p=p.x<p.z?p.zyx:p;
        p=p.x>p.y?p.yxz:p;
        p.xy=R2(p.xy,.98-sin(length(q.xy)));
        g+=e=max(-e,length(p.xz))*.6;
        c+=mix(vec3(1),H(q.z*.05+.4),.7)*.4/exp(30.*e)/g;
    }
    glFragColor=vec4(c,1);
}
