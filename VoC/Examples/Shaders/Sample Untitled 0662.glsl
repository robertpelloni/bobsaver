#version 420

// original https://www.shadertoy.com/view/fld3zX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.283
#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1.));
    float z=100.,cnt=30.;
    for(float j=0.;j++<cnt;)
    {
        float i=0.,g=0.,e;
        for(;++i<50.||g<z;){
            p=g*d;
            p.z-=6.;
            p=R(p,vec3(.577),time*.5);
            p=R(p,vec3(0,1,0),1.5*j*TAU/cnt);
            p=R(p,vec3(1,0,0),.04*j);
            p.x-=.5;
            g+=e=length(vec2(length(p.xz)-1.-j*.03,p.y))-.05;
            if(e<.001)
            {
                if(g<z)
                {
                    z=g;
                    O.xyz=mix(vec3(1),H(j/cnt),.7)*3./i;
                }
                break;
            }
        }
    }
	glFragColor=O;
}
