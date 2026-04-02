#version 420

// original https://www.shadertoy.com/view/4lSfRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323846
void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 pos = vec2(0.5)-uv;
    
    float angle = atan(pos.x,pos.y);
    float radius = length(pos)*2.0;
    
    float r =   sin(angle*10.0+sin(radius*PI*5.0)*10.0+
      time+sin(cos(sin(angle*30.0+time)*PI)*sin(cos(radius*20.0*PI)*PI)*0.4)
      *sin(radius*20.0+time)*PI*3.0)*1.0;
    
    
    
    float g = r*radius*0.5+sin(angle*10.0+sin(radius*PI*5.0)*10.0+time+sin(cos(sin(angle*30.0+time)*PI)*sin(cos(radius*20.0*PI)*PI)*0.4)*sin(radius*20.0+time)*PI*3.0)*0.5
    +cos(angle*10.0+sin(radius*PI*5.0)*10.0+time+sin(cos(sin(angle*30.0+time)*PI)*sin(cos(radius*20.0*PI)*PI)*0.4)*sin(radius*20.0+time)*PI*3.0)*0.5;
    float b = cos(angle*10.0+sin(radius*PI*5.0)*10.0+time+sin(cos(sin(angle*30.0+time)*PI)*sin(cos(radius*20.0*PI)*PI)*0.4)*sin(radius*20.0+time)*PI*3.0);
    
    glFragColor = vec4(r,g,b,1.0);
}
