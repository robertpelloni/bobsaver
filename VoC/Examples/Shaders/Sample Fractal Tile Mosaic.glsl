#version 420

// original https://www.shadertoy.com/view/wtGyzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float fract1(float a){
    return (abs(fract(a/2.0)-.5))*2.0;
}

vec2 fract1(vec2 a){
    return (abs(fract(a/2.0)-.5))*2.0;
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col;
    float t;
    
    for(int c=0;c<3;c++){
        
        vec2 uv = (gl_FragCoord.xy*40.0-resolution.xy)/resolution.y/10.0;
        uv += vec2(time/2.0,time/8.0)/2.0;
        t = time+float(c)/10.;
        float scale = 5.5;
        float scale1 = 2.0;
        for(int i=0;i<3;i++)
        {
            uv = (fract1(uv/scale1)+fract1(uv/scale/2.0))*scale1;
            uv= fract1(uv/(2.0-fract1((uv.x-uv.y)/(8.0)))-(uv/(1.7+(fract1(uv.x+uv.y))))/scale)*scale/scale1+scale1*scale;
            uv /= scale1+col.yx;
            uv=uv.yx+col.xy;
        }
     col[c] = abs(fract(uv.y)-fract(uv.x));
    }
    
    glFragColor = vec4(vec3(col),1.0);
    
}
