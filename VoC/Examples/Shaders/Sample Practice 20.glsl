#version 420

// original https://www.shadertoy.com/view/wsSGzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float square(vec2 p,float s)
{
    vec2 k=vec2(abs(p.x)+abs(p.y),0.5); 
    return smoothstep(0.1*s,0.1*s+0.04,k.x);
    
}

vec2 brickSquare(vec2 st,float n)
{
    st*=n;
    return fract(st)-0.5;
}

vec3 changeRGB(vec3 col)
{
    return col/256.0;
}

void main(void)
{
    vec2 p=(gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);
    p*=1.0+0.3*sin(p.x*5.+time)+0.1*sin(p.y*5.+time);
    float n=5.0;
       p=brickSquare(p,n);
    float col=square(p,5.);
    vec3 colA=changeRGB(vec3(15.0,92.0,120.0));
    vec3 colB=changeRGB(vec3(15.0,92.0,160.0));
    vec3 c=mix(colA,colB,p.x+0.4);
    glFragColor=vec4(vec3(c+(1.-col)),1.);  
}
