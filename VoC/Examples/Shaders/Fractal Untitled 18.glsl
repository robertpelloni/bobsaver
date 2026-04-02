#version 420

// original https://www.shadertoy.com/view/Wl3BW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)cos(h*6.3+vec3(0,23,21))*.5+.5
void main(void)
{
    vec4 O = glFragColor;    
    O-=O;
    vec3 r=vec3(resolution.xy,1.0),p;
    float i,g,e,l,s;
    for(i=0.;
        ++i<99.;
        e<.002?O.xyz+=mix(r/r,H(g),.5)*.8/i:p
        )
    {
    p=g*vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1);
    p=R(p,R(normalize(vec3(2,5,3)),vec3(.577),time*.3),.4);
    p.z+=time;
    p=mod(p-2.,4.)-2.;
    for(int k=0;k++<3;)
        p=abs(p),
        p=p.x<p.y?p.zxy:p.zyx;
    s=2.;
    for(int j=0;j++<5;)
        s*=l=2./clamp(dot(p,p),.1,1.),
        p=abs(p)*l-vec3(1,1,8);
    g+=e=length(p.xz)/s;}
    glFragColor=O;
}
