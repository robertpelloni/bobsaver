#version 420

// original https://www.shadertoy.com/view/ws33Dl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAIN_COLOR vec3(1.0, 1.0, 1.0)

void main(void)
{
    vec2 p=(2.0*gl_FragCoord.xy-resolution.xy)/max(resolution.x,resolution.y);
    for(int i=1;i<10;i++)
    {
        vec2 newp=p;
        newp.x+=0.6/float(i)*sin(float(i)*p.y+time+0.3*float(i))+1.0;
        newp.y+=0.6/float(i)*sin(float(i)*p.x+time+0.3*float(i+10))-1.4;
        p=newp;
    }
    vec3 col=vec3(1.0 - abs(sin(p.x)), 1.0 - abs(sin(p.x+p.y)), 1.0 - abs(sin(p.y)))
                    * MAIN_COLOR;
    glFragColor=vec4(col, 1.0);
}
