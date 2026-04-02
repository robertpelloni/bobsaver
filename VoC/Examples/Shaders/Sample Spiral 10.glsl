#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 pattern(vec2 pos, float ang) 
{
        pos = vec2(pos.x * cos(ang) - pos.y * sin(ang), pos.y * cos(ang) + pos.x * sin(ang));    
    
    //if(length(pos) < 0.2)
    if(abs(pos.x) < 0.2 && abs(pos.y) < 0.2)
       return vec4(0.0, 0.0, 0.0, 0.0);
    else if((abs(pos.x) - abs(pos.y)) > 0.0)
       return vec4(0.59, 0.45, 0.05, 1.0);
    else
       return vec4(0.27, 0.07, 0.39, 1.0);            
}

void main( void ) 
{
    vec2 pos = ( gl_FragCoord.xy / resolution.xy ) - vec2(0.5, 0.5);
    vec4 color = vec4(0.0);
    
    for(float i = 0.01 ; i < 1.0 ; i += 0.005)
    {
        float o = 1.0 - i;
        vec2 offset = vec2(o*cos(o*2.0+time)*0.5, o*sin(o*2.0+time)*0.5);
        vec4 res = pattern(pos/vec2(i*i*2.7)+offset, i*10.0+time);
        if(res.a > 0.5)
             color = res*i*2.7;
    }

    glFragColor = color;
}
