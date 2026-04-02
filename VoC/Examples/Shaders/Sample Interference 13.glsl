#version 420

// original https://www.shadertoy.com/view/3tlSzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int colorCalc(vec2 uv,vec2 circle1)
{
        float d = (mod(distance (uv,circle1),0.04))*25.0;
    if(d>0.5)
    {
        return 0;
    }
    else
    {
        return 1;
    }
}

float interDistance(vec2 a, vec2 b)
{
     return distance(a,b);
}

void main(void)
{
 
       // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.y;
 
    
    vec2 circle1 = vec2(0.8+sin(time*1.1)/1.5,   0.5 + sin(time)/2.2);
    vec2 circle2 = vec2(1.2+sin(time*0.9)/1.5,   0.5 + sin(time*0.8)/2.2);
    
    int c1 = colorCalc(uv,circle1);
    int c2 = colorCalc(uv,circle2);
    
      int c =  c1+c2;
    if (c>=1)
    {
        glFragColor = vec4(1,1,0,1);
       
    }else
    {
        glFragColor = vec4(0,0,1,1);
        
    }
         
}
