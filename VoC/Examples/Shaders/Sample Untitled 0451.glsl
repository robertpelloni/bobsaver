#version 420

uniform vec2 mouse;
uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

const float Pi = 3.14159;

void main()
{
    vec2 p=(2.0*gl_FragCoord.xy-resolution)/max(resolution.x,resolution.y);
    for(int i=1;i<50;i++)
    {
        vec2 newp=p;
        newp.x-=0.3/float(i)*sin(float(i)*p.y*(.3+mouse.x)+time);
        newp.y+=0.3/float(i)*sin(float(i)*p.x*(.3+mouse.y)+time);
        p=newp;
    }
    vec3 col=vec3(p.x-floor(p.x),p.y-floor(p.y),p.x*p.y*10.0);
    glFragColor=vec4(clamp(sqrt(col - 0.5*col.g + col.r),0.0,1.0)-vec3(0.5,0.5,0.4)*0.1+vec3(0.5,0.5,0.4)*0.1, 1.0);
}
