#version 420

// original https://www.shadertoy.com/view/fdycz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,t) (p*cos(t)+vec2(-p.y,p.x)*sin(t))
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1.));
    for(float i=0.,e,g=0.;i++<80.;O+=.01/exp(i*i*e))
        p=(d-i/7e4)*g,
        p.z-=8.,      
        p.xz+=vec2(cos(p.z*5.+time*2.),sin(p.x*8.)),
        p.xz=R(p.xz,atan(p.x,p.z)-.8),
        g+=e=.12*(p.z-p.y*p.y-1.5);
    O.xyz*=mix(vec3(1),H(p.x*.3),.6);
    glFragColor = O;
}
