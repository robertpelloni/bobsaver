#version 420

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

void main()
{
    vec2 p=(2.0*gl_FragCoord.xy-resolution)/max(resolution.x,resolution.y);
    vec2 newp;
    for(int i=1;i<50;i++)
    {
        newp=p;
        newp.x+=0.6/float(i)*sin(float(i)*p.y+time+0.3*float(i))+0.1;
        newp.y+=0.6/float(i)*sin(float(i)*p.x+time+0.3*float(i+10))-0.7;
        p=newp;
    }
    vec3 col=vec3(0.5*sin(3.0*p.x)+0.5,0.5*sin(3.0*p.y)+0.5,sin(p.x+p.y));
    glFragColor=vec4(col, 1.0);
}
