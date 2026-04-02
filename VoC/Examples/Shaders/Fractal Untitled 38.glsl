#version 420

// original https://www.shadertoy.com/view/WtyBzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,g=0.,e,s;
        ++i<99.;
        O.rgb+=mix(vec3(1),H(time*.1),.2)*pow(dot(p,p),.2)*log(s)*8e-4
    )
    {
        p=g*d;
        p.z+=time*1.2;
        p=R(p,vec3(.577),.3);
        s=4.;
        for(int i=0;i++<6;p*=e)
            p=abs(p-vec3(0,2,1.5)),
            p=mod(p,4.)-2.,
            s*=e=-4./dot(p,p);
        g+=abs(p.y)/s+1e-4;
    }
    glFragColor=O;
}
