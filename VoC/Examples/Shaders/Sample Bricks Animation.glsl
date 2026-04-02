#version 420

// original https://www.shadertoy.com/view/NsG3DV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 coord=gl_FragCoord.xy/resolution.xy*15.0;
    for(int n=1;n<20;n++)
    {
        float i=float(n);
        coord +=vec2(sin(time)/i*sin(coord.y+time),sin(time)/i*sin(coord.x+time));
        coord +=vec2(cos(time)/i*sin(coord.x+time),cos(time)/i*sin(coord.y+time));
        
    }
    

    vec3 color =vec3(0.5*sin(coord.x+time)+0.5,0.5*sin(coord.y+time)+0.5,0.5*atan(coord.y,coord.x)+0.5);
    
    glFragColor=vec4(color,1.0);

}
