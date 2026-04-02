#version 420

// original https://www.shadertoy.com/view/wd2yDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Q(a)a=length(a)*sin(vec2(-.2,1.4)+mod(atan(a.y,a.x),.4))
void main(void)
{
    vec4 O = glFragColor;
    vec2 C = gl_FragCoord.xy;

    O-=O;
    O.z+=sin(time);
    for(float e,g,j,i;i<30.;i++)
    {
        vec3 p=g*vec3(C.xy/resolution.y-.3,1);
        for(j=0.;j<5.;j++)
        {
            Q(p.xy);Q(p.yz);p.z-=8.;
        }
        g+=e=dot(abs(p),vec3(7,-5,sin(time*.5)+3.))*.1;
        O+=(e<.01)?.7/i:0.;
    }

    glFragColor = O;
}
