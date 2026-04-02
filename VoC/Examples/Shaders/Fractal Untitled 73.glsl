#version 420

// original https://www.shadertoy.com/view/NsyGWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)cos((h)*6.3+vec3(0,23,21))*.5+.5
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    float i=0.,g=0.,e,s,a;
    for(;++i<99.;){
        p=d*g;
        p.z+=time*.2;
        p=R(p,vec3(1),1.2);
        p=mod(p,2.)-1.;
        // There is no basis for this line. 
        // It is written by mistake. 
        // I noticed later.
        // However, since the picture is out, it is left as it is
        p.xy=vec2(dot(p.xy,p.xy),length(p.xy)-1.);
        s=3.;
        for(int i=0;i++<5;){
            p=vec3(10,2,1)-abs(p-vec3(10,5,1));
            s*=e=12./clamp(dot(p,p),.2,8.);
            p=abs(p)*e;
        }
        g+=e=min(length(p.xz),p.y)/s+.001;
        a=cos(i*i/80.);
        O.xyz+=mix(vec3(1),H(log(s)*.3),.5)*a*a/e*6e-5;
    }
    O=pow(O,vec4(4));
    glFragColor = O;
 }
