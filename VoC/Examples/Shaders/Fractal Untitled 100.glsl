#version 420

// original https://www.shadertoy.com/view/NddfR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void) //WARNING - variables void (out vec4 O, vec2 C) need changing to glFragColor and gl_FragCoord.xy
{
    vec3 r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3(gl_FragCoord.xy-.5*r.xy,r.y));
    float i=0.,s,e,g=0.,t=time;
    for(;i++<90.;){
        vec4 p=vec4(R(g*d,normalize(H(t*.1)),g*.1),.7)+
            vec4(1.2,-.8,t*.4,0);
        p=asin(sin(p))-i/2e4;
        s=2.;
        for(int i=0;i++<6;p=p*e-vec4(1.1,2.9,1.2,1))
           p=1.-abs(abs(p)-2.3),s*=e=max(1.,5./dot(p,p));
        g+=e=abs(length(p.wz)-.3)/s+2e-4;;
        c+=mix(vec3(1),H(log(s)*.2+.3),.4)*.04/exp(i*i*e);
    }
    c*=c*c;
    glFragColor=vec4(c,1);
}
