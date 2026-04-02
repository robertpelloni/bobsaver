#version 420

// original https://www.shadertoy.com/view/ws2yWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 O = glFragColor;
    vec2 C = gl_FragCoord.xy;
    O-=O;
    for(float g,e,i=0.;i<30.;i++)
    {
        vec3 p=vec3(C.xy/resolution.y-.6,1.)*g;
        p.xy+=sin(time)*.1;
        g+=e=length(vec2(mod(length(p.xy),.4)-.2,mod(p.z+time*2.,.8)-.4))-.01;
        O+=cos(vec4(6,2,9,0)+atan(p.x,p.y)*16.)*((e<.01)?1./i:0.);
    }
    glFragColor = O;
}
