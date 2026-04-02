#version 420

// original https://www.shadertoy.com/view/3ltfD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O = glFragColor;
    O=vec4(0);
    vec3 r=vec3(resolution,1.0),p;
    
    for(float i=0.,g,e,l,s;
        ++i<99.;
        (e<.003)?O.xyz+=cos(vec3(1,2,3)+log(s)*.5)*.5/i:p
        )
    {
        p=g*vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1);
        p.z-=.3;
        p=R(p,vec3(.577),time*.5);
        p.x<-p.y?p.xy=-p.yx:gl_FragCoord.xy,
        p.x<-p.z?p.xz=-p.zx:gl_FragCoord.xy,
        p.y<-p.z?p.zy=-p.yz:gl_FragCoord.xy;
        s=3.;
        for(int j=0;j++<5;)
            s*=l=2./clamp(dot(p,p),.1,1.),
            p=abs(p)*l-vec3(1,1,5);
        g+=e=length(cross(p,r/r))/s;
    }

    glFragColor = O;
}
