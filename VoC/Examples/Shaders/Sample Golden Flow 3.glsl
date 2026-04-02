#version 420

// original https://www.shadertoy.com/view/wdcSzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 q=7.0*(gl_FragCoord.xy-0.5*resolution.xy)/max(resolution.x,resolution.y);
    
    for(float i=1.0;i<40.0;i*=1.1)
    {
        vec2 o=q;
        o.x+=(0.5/i)*cos(i*q.y+time*0.297+0.03*i)+1.3;        
        o.y+=(0.5/i)*cos(i*q.x+time*0.414+0.03*(i+10.0))+1.9;
        q=o;
    }

    vec3 col=vec3(0.5*sin(3.0*q.x)+0.5,0.5*sin(3.0*q.y)+0.5,sin(1.3*q.x+1.7*q.y));
    float f=0.43*(col.x+col.y+col.z);

    glFragColor=vec4(f+0.6,0.2+0.75*f,0.2,1.0);
}
