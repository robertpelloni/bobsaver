#version 420

// original https://www.shadertoy.com/view/fdjfRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec3 p,r=vec3(resolution,1.0),c=vec3(0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));
     for(float i=0.,s,e,g=0.,t=time;i++<90.;){
        p=g*d;
        p=R(p,normalize(H(t*.02)*2.-1.),g/8.);
        p+=vec3(1.*cos(t*.05),.5*sin(t*.1),t*.5);
        p=asin(sin(p*.7));
        s=1.;
        for(int j=0;j++<7;)
           s*=e=max(.1/dot(p,p),1.),
           p=R(abs(p.zxy)*e-.1,vec3(.577),1.1+sin(t*.2)*.1);
        g+=e=abs(p.x)/s+5e-4;
        c+=mix(vec3(1),H(log(s)*.2),.8)*.05/exp(.5*i*i*e);
    }
    c*=c*c;
    glFragColor=vec4(c,1);
}
