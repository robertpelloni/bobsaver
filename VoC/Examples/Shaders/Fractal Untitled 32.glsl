#version 420

// original https://www.shadertoy.com/view/wtyfWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,g,e,s;
        ++i<99.;
        O+=sin(vec4(22,15,53,1)/s/e)/e/1e4
    )
    {
        p=g*d;
        p.z-=3.;
        p=R(p,normalize(vec3(1,5,0)),time*.5);
        s=3.;
        for(int i=0;i++<6;)
            p.xz=.7-abs(p.xz),
            p.x<p.z?p=p.zyx:p,
            s*=e=2.6/clamp(dot(p,p),.02,1.2),
            p=abs(p)*e-vec3(.1,15,2);
        g+=e=length(p.xy)/s+5e-4;}
    glFragColor = O;
}
