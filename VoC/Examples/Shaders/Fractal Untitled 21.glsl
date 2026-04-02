#version 420

// original https://www.shadertoy.com/view/wl3fDM

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
    for(float i=0.,g=0.,e,l,s;
        ++i<99.;
        e<.003?O.xyz+=mix(
                r/r,
                cos(vec3(8,3,12)+g*3.)*.5+.5,
                .6
            )*.9/i:p
    )
    {
        p=vec3(g*(gl_FragCoord.xy-.5*r.xy)/r.y,g-2.);
        p=R(p,normalize(vec3(1,2,3)),time*.2);
        p=.7-abs(abs(p-1.+sin(p*.1))-1.);
        for(int k=0;k++<2;)
            p=abs(p),
            p=p.x<p.y?p.zxy:p.zyx;
        s=4.;
        for(int j=0;j++<4;)
            s*=l=2./min(dot(p,p),2.),
            p=abs(p)*l-vec3(2,1,3);
        g+=e=length(p.yz)/s;
    }
    O=pow(O,vec4(.8,.6,1.3,1));
    glFragColor = O;
}
