#version 420

// original https://www.shadertoy.com/view/Nd3XzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
#define lpNorm(p,n)pow(dot(pow(abs(p),vec3(n)),vec3(1)),1./n)

void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));
    float i=0.,g=0.,e,s,h;
    for(;++i<99.;)
    {
        p=g*d;
        p.z-=.9;
        p.xy-=.1;
        p=R(p,normalize(vec3(1,2,3)),time*.3);
        s=4.;
        for(int j=0;j++<8;)
        {
            p=abs(p);
            p=p.x<p.y?p.zxy:p.zyx;
               h=lpNorm(p,3.);
            s*=e=2./min(h*h,1.45);
            p=p*e-vec3(12,3,5);
        }
        g+=e=abs(length(p.xz)/s-15e-4)+5e-4;
        O.rgb+=mat3(.33,.36,.46,1.,.64,.46,.24,.38,.27)*
            (H(log(s)*.8)+.9)*6e-6*exp(sin(i))/e;  
    }
    O=pow(O,vec4(5));
    glFragColor=O;
 }
