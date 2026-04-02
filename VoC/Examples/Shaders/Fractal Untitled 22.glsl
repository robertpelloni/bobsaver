#version 420

// original https://www.shadertoy.com/view/WttfWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O=vec4(0);
    vec3 r=vec3(resolution.xy,1.0),p;  
    for(float i=0.,g=0.,e,s;
        ++i<99.;
        e<.001?O.xyz+=mix(
                r/r,
                cos(vec3(7,24,2)+log(s)*.5)*.5+.5,
                .7
            )*.6/i:p
    )
    {
        p=vec3(g*(gl_FragCoord.xy-.5*r.xy)/r.y,g-6.);
        p=R(p,normalize(vec3(1,2,3)),time*.2);
        s=2.;
        p=2.-abs(p);
        p.x<p.z?p=p.zyx:p;
        p.y<p.z?p=p.xzy:p;
        p.x<p.y?p=p.yxz:p;
        for(int j=0;j++<6;)
            p=1.3-abs(p-.7),
            e=dot(p,p),
            s*=e=3./min(e,2.)+2./min(e,.5),
            p=abs(p)*e-vec3(2,7,1);
        g+=e=length(p.yz)/s;
    }
    O=pow(O,vec4(1.5,2.2,2.8,1));
    glFragColor = O;
}
