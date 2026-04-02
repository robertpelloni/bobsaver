#version 420

// original https://www.shadertoy.com/view/wdK3Dd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float Pi = 3.14159;

void main(void)
{
 
    
    vec2 q=7.0*(gl_FragCoord.xy-0.5*resolution.xy)/max(resolution.x,resolution.y);
    vec2 p=vec2(abs(q.x),q.y);
    
    for(int i=1;i<40;i++)
    {
        vec2 newp=p;
        newp.x+=(0.5/(1.0*float(i)))*cos(float(i)*p.y+time*11.0/37.0+0.03*float(i))+1.3;        
        newp.y+=(0.5/(1.0*float(i)))*cos(float(i)*p.x+time*17.0/41.0+0.03*float(i+10))+1.9;
        p=newp;
    }

    vec3 col=vec3(0.5*sin(3.0*p.x)+0.5,0.5*sin(3.0*p.y)+0.5,sin(1.3*p.x+1.7*p.y));
    col.x=smoothstep(0.90,1.0,col.x);   
    col.y=smoothstep(0.90,1.0,col.y);
    col.z=smoothstep(0.90,1.0,col.z);
    float f=col.x;
    f=max(f,col.y);
    f=max(f,col.z);
    f=(f*20.)-19.;       
    
    glFragColor=vec4(f,0.75*f,0.1,1.0);
    
}
