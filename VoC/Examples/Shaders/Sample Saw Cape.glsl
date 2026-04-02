#version 420

// original https://www.shadertoy.com/view/tslBRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M(p)p=length(p)*sin(vec2(-.4,1.2)+mod(atan(p.x,p.y),.8))
void main(void)
{
    vec4 O = glFragColor;
    vec2 C = gl_FragCoord.xy;

    O-=O;
    for(float g,e,i=0.;i<80.;i++)
    {
        vec3 p=g*vec3(C.xy/resolution.y-.5,1.);
        p.z+=time*3.;
        p=mod(p,6.)-3.;
        M(p.xz);
        p.z=fract(p.z)-.5;
        M(p.xz);
        M(p.zy);
        g+=e=dot(abs(p),vec3(.5))-1.2;
        O+=(e<.01)?.3/i:0.;
    }

    glFragColor = O;
}
