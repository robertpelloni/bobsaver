#version 420

// original https://www.shadertoy.com/view/4ssGRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float continousGenerator(in vec2 intUV, in float time)
{
    float t = sin(sin((intUV.x))*time) + cos(sin(intUV.y)*time/2.0) +
        cos(cos(intUV.x * intUV.y)*time/1.5);   
    t = sin((t + 1.0)/2.0);
    return t;
}

float valueGenerator(in vec2 intUV, in float time)
{
    float t = continousGenerator(intUV, time);
    return t;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    int cellSize = 3;
    int x = int(gl_FragCoord.xy.x)/cellSize;
    int y = int(gl_FragCoord.xy.y)/cellSize;
    
    float sumT = 0.0;
    
    for(int i = x - 1; i <= x + 1; i++) {
        for(int j = y - 1; j <= y + 1; j++) {
            sumT += valueGenerator(vec2(i,j), time);
           }
    }
    
    float t = valueGenerator(vec2(x,y), time);
    if(t > 0.5)
    {
        if(sumT < 2.0 || sumT > 3.0)
            t = 0.0;
        else 
            t = 1.0;
    }
    else
    {
        if(sumT == 3.0)
            t = 1.0;
    
    }
    vec4 c1 = vec4(0.0,1.0,0.0,1.0);
    vec4 c2 = vec4(0.0,0.0,0.0,1.0);
    glFragColor = mix(c2,c1,t);
}
