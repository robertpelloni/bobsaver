#version 420

// original https://www.shadertoy.com/view/ssySDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec4 O=vec4(0);
    vec3 p,q,r=vec3(resolution.xy,1.0),d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1.));
    for(float i=0.,g,e=1.;++i<99.;){
        p=g*d;
        p.z+=time*6.;
        q=sin(p);
        p+=cross(sin(p*1.5+time*3.),cos(p.zxy*1.2+time*2.));
        p=cos(p/3.);
        g+=e=abs(length(p)-1.)+1e-3;
        O.xyz+=mix(vec3(1),H(dot(q,q)*.3),.8)*.014*exp(-1e-3*i*i*e);
    }
    O*=O*O*O*O;
    glFragColor=O;
}
