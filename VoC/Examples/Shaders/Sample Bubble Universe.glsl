#version 420

// original https://www.shadertoy.com/view/fdfXDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void main(void)
{
    vec4 O=vec4(1);
    vec3 p,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,g,e,s;
        ++i<99.;
        O.xyz+=5e-5*abs(cos(vec3(3,2,1)+log(s*9.)))/dot(p,p)/e
    )
    {
        p=g*d;
        p.z+=time*.1;
        p=R(p,normalize(vec3(1,2,1)),.5);   
        s=2.5;
        p=abs(mod(p-1.,2.)-1.)-1.;
        
        for(int j=0;j++<10;)
            p=1.-abs(p-vec3(-1.)),
            s*=e=-1.8/dot(p,p),
            p=p*e-.7;
            g+=e=abs(p.z)/s+.0001;
     }
     O /= 4.0;
    glFragColor=O;
}
