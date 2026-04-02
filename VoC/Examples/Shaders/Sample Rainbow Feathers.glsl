#version 420

// original https://www.shadertoy.com/view/7sSGWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col;
    float t = time;
    vec2 uv = (gl_FragCoord.xy*10.0-resolution.xy)/resolution.y/10.0;
    uv += vec2(t/2.0,t/3.0)/4.0;
    for(int c=0;c<3;c++){
        float scale = 5.5;
        float scale1 = 1.4;
        float s1 = scale1*scale;
        for(int i=0;i<6;i++)
        {
            uv = fract(uv/s1)*s1;
            uv=-fract(uv/(2.0-abs((uv.x-uv.y)/(16.0)))-(uv/(2.5+(fract(uv.x+uv.y))))/scale)*scale/scale1+s1;
            uv /= scale1+col.yx;
            uv=uv.yx+col.xy;
            uv.x *= -(1.0+col.x/scale);
            col[c] = fract((.25*col[c]+col.x+(uv.y)-(uv.x))/2.5);
        }
     
    }
    
    glFragColor = vec4(vec3(col),1.0);
    
}
