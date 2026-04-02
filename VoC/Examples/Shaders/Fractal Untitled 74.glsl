#version 420

// original https://www.shadertoy.com/view/NsyGDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)cos((h)*6.3+vec3(0,23,21))*.5+.5
#define lpNorm(p,n)pow(dot(pow(abs(p),vec2(n)),vec2(1)),1./n)

void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    float i=0.,g=0.,e,s,a;
    for(;++i<90.;){
        p=d*g;
        p=R(p,normalize(vec3(1)),.2);
        p.z+=time*.5;
        p.xy-=vec2(.03,-.1)*sin(time*.5);
        p=asin(sin(p*5.));        
        p.xy=vec2(lpNorm(p.xy,8.)-1.);
        s=3.;
        for(int i=0;i++<5;){
            p=vec3(15,2,6)-abs(p-vec3(16,2,9));
            p=p.x<p.y?p.zxy:p.zyx;
            s*=e=8./min(dot(p,p),5.);
            p=abs(p)*e;
        }
        g+=e=abs(p.y)/s+.001;
        O.xyz+=(H(log(s)*.3)+.3)*exp(sin(i))/e*3e-5;
    }
    O*=O*O*O;
    glFragColor = O;
 }
