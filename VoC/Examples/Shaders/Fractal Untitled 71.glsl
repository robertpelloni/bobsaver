#version 420

// original https://www.shadertoy.com/view/fdy3WG

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
        O.rgb+=mix(r/r,H(log(s)),.7)*.08*exp(-i*i*e))
    {
        p=g*d;
        p.z-=.6;
        p=R(p,normalize(vec3(1,2,3)),time*.3);
        s=4.;
        for(int j=0;j++<8;)
            p=abs(p),p=p.x<p.y?p.zxy:p.zyx,
            s*=e=1.8/min(dot(p,p),1.3),
            p=p*e-vec3(12,3,3);
        g+=e=length(p.xz)/s;
  
    }
    O=pow(O,vec4(5));
    glFragColor=O;
 }
