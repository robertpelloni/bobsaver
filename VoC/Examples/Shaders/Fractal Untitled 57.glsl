#version 420

// original https://www.shadertoy.com/view/7sS3DV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));
    ;
    for(float i=0.,s,e=1.,g=0.;
        e>.001&&++i<70.;
        O.rgb+=mix(vec3(1),H(length(p)*.3),.8)*.02*exp(-.01*i*i*e)
    )
    {
        p=g*d-vec3(0,0,1);
        p.y-=p.z*.6;
        p.xz=asin(sin((p.xz+time*.3)*PI/2.))/PI*2.;
        s=2.;
        for(int i=0;i<6;i++)
            p.xz=abs(p.xz-vec2(1,2))-1.1,
            s*=e=2.2/clamp(dot(p.xz,p.xz),.2,3.5),
            p.xz=p.xz*e-.6;
        vec2 q=vec2(abs(p.z/s),p.y);
        g+=e=.5*min(p.y,length(q-min(q,vec2(.001,.08))));
    }
    glFragColor=O;
}
