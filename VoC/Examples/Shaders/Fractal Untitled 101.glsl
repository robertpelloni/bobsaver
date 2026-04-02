#version 420

// original https://www.shadertoy.com/view/flGBDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 R(vec3 p,vec3 a,float t)
{
  a=normalize(a);
  return mix(a*dot(p,a),p,cos(t))+cross(p,a)*sin(t);
}

vec2 M(vec2 p,float n)
{
  float a=asin(sin(atan(p.y,p.x)*n)*.9)/n;
  return vec2(sin(a),cos(a))*length(p);
}

#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec3 p,r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3(gl_FragCoord.xy-.5*r.xy,r.y));
    float i=0.,g=0.,e,s,t=time;
    for(;i<90.;i++)
    {
        p=d*g;
        p.z+=t*3.;
        p=R(p,vec3(1),.5);
        p=asin(sin(p)*.995);
        p.xy=M(p.xy,15.);
        p.y-=4.2;
        p=R(p,vec3(1),.4);
        s=2.;
        for(int i=0;i<7;i++)
        {
            p=.01-abs(p-.05);
            s*=e=max(1./dot(p,p),1.5);
            p=abs(p.x<p.y?p.zxy:p.zyx)*e-1.3;
        }
        e=abs(length(p.yz)/s-.01);
        g+=e+.002;
        c+=mix(vec3(1),H(log(s)),.5)*.08*exp(-i*i*e);
    }
    glFragColor = vec4(c,1);
}
