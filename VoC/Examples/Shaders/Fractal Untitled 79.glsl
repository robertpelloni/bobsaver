#version 420

// original https://www.shadertoy.com/view/7ttSW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define B (1.-fract(t*2.))
#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec3 p,r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));
    float i=0.,s,e,g=0.,t=time;
    for(;i++<99.;)
    {
        p=g*d;;
        p.z-=3.;
        p=R(p,vec3(.577),t*.3);
        s=3.;
        for(int i=0;i++<8;p*=e)
            p=vec3(1,3.+sin(t)*.3,2)-abs(p-vec3(1,2,1.5+sin(t)*.2)),
            s*=e=9./clamp(dot(p,p),.8,9.);
        g+=e=abs(p.y/s-.001)+1e-3;
        c+=mix(vec3(1),H(length(p*.2+.5)),.6)*.0015/i/e;  
    }
    c*=c;
    glFragColor=vec4(c,1);
}
