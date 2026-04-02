#version 420

// original https://www.shadertoy.com/view/fdtBR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec3 r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3(gl_FragCoord.xy-.5*r.xy,r.y));
    float i=0.,s,e,g=0.,t=time;
    for(;i++<90.;){
        vec4 p=vec4(R(g*d,normalize(H(t*.1)),g*.1),.2 );
        p.z+=t*.4;
        p=asin(sin(p));
        s=1.;
        for(int i=0;i++<6;p=p*e-vec4(1,.3,.5,1.7))
            p=abs(p),
            p=p.x<p.y?p.zwxy:p.zwyx,
            s*=e=2.7/min(dot(p,p),2.);
        g+=e=abs(p.w)/s+1e-4;
        c+=mix(vec3(1),H(log(s)*.3),.4)*.04/exp(i*i*e);
    }
    c*=c*c;
    glFragColor=vec4(c,1);
}
