#version 420

// original https://www.shadertoy.com/view/WtVBzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,g=0.,e,s;
        ++i<99.;
        e<.001?O+=mix(vec4(1),cos(vec4(1,2,3,0)+log(s))*5.,.3)/length(p)/i:O
    )
    {
        p=g*d;
        p-=vec3(0,-.9,1.5);
        p=R(p,normalize(vec3(1,8,0)),time*.2);   
        s=3.;
        s*=e=6./min(dot(p,p),2.);
        p=abs(p)*e;
        for(int i=0;i++<2;){
            p.x =1.-abs(p.x-5.2);
            p.y =3.6-abs(p.y-4.3);
            p.z =1.8-abs(p.z-2.5);
            s*=e=8./min(dot(p,p),9.);
            p=abs(p)*e;
        }
        g+=e=min(length(p.xz)-.3,p.y)/s;
    }
    glFragColor=O;
}
