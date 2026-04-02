#version 420

// original https://www.shadertoy.com/view/dlycRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)

vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}
void main(void)
{
    vec4 O=vec4(0);
    vec2 C = gl_FragCoord.xy;    

    vec3 p,q,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((C*2.-r.xy)/r.y,1));  
    for(float i=0.,a,s,e,g=0.;
        ++i<110.;
        O.xyz+=mix(vec3(1),H(g*.1),sin(.8))*1./e/8e3
    )
    {
        p=g*d;
        p.z+=time*6.5;
        a=10.;
         p.xy=rotate(p.xy,time/10.-length(p.xy)*1.);
        p=mod(p-a,a*5.)-a;
        s=6.;
        for(int i=0;i++<8;){
            p=1.13-abs(p);
            
            p.x<p.z?p=p.zyx:p;
            p.z<p.y?p=p.xzy:p;
            
            s*=e=1.4+sin(time*.234)*.1;
            p=abs(p)*e-
                vec3(
                    5.+sin(time*.3+.5*cos(time*.3))*1.,
                    120,
                    10.+cos(time*.2)*5.
                 );
         }
         g+=e=length(p.yz)/s;
    }
    
    glFragColor = O;
}