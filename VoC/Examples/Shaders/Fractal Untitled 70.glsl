#version 420

// original https://www.shadertoy.com/view/sdy3Rd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O = glFragColor;
    vec2 C = gl_FragCoord.xy;
    O-=O;
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((C-.5*r.xy)/r.y,1));  
    for(
        float i=0.,g=0.,e,s;
        ++i<99.;
        O.rgb+=mix(r/r,H(log(s)),.4)*.02*exp(-.5*i*i*e))
    {
        p=R(g*d,vec3(.577),.2);
        p.z+=time;
        p=fract(p)-.5;
        s=3.;
        for(int j=0;j++<8;)
            p=abs(p),
            p=p.x<p.y?p.zxy:p.zyx,
            s*=e=2./min(dot(p,p),1.),
            p=p*e-vec3(.2,1,4);
        g+=e=length(p)/s;
    } 
    glFragColor = O;
 }
