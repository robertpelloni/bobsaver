#version 420

// original https://www.shadertoy.com/view/fdlyzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec3 p,r=vec3(resolution.xy,1.0),c=vec3(0),
    d=normalize(vec3(gl_FragCoord.xy-.5*r.xy,r.y));
     for(float i=0.,s,e,g=0.,t=time;i++<80.;){
        p=g*d;
        // https://twitter.com/Totetmatt/status/1482756320239493120
        // Rotation using p.z
        p=R(p,normalize(vec3(1,3,.5)),.3-p.z*.1);
        p.z+=t;
        p=asin(cos(p))-vec3(2,4,1);
        s=1.;
        for(int i=0;i++<7;)
            p=abs(p),
            p=p.x<p.y?p.zxy:p.zyx,
            s*=e=1.8,
            p=p*e-vec3(2,3,6);
        g+=e=abs(length(p-min(p,2.))-9.)/s+1e-5;
        c+=vec3(1,1,2)*.02/exp(i*i*e);
    }
    c*=c;
    glFragColor=vec4(c,1);
}
