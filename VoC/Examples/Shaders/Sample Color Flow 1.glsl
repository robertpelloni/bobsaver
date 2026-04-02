#version 420

// original https://www.shadertoy.com/view/3sV3Dd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// modification of https://www.shadertoy.com/view/ldX3Wn

const float Pi = 3.14159;

void main(void)
{
    vec2 p=4.0*(abs(gl_FragCoord.xy-0.5*resolution.xy)/max(resolution.x,resolution.y));
    
    for(int i=1;i<45;i++)
    {
        vec2 newp=p;
        newp.x+=(0.5/(1.5*float(i)))*cos(float(i)*p.y+time*11.0/37.0+0.03*float(i))+1.3;        
        newp.y+=(0.5/(1.5*float(i)))*cos(float(i)*p.x+time*17.0/41.0+0.03*float(i+10))+1.9;
        p=newp;
    }

    vec3 col=vec3(0.5*sin(3.0*p.x)+0.5,0.5*sin(3.0*p.y)+0.5,sin(1.3*p.x+1.7*p.y));
    glFragColor=vec4(col, 1.0);
}
