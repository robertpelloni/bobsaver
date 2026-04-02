#version 420

// original https://www.shadertoy.com/view/ttBcW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define PI 3.1415927
#define SS(U) smoothstep(.05,0.,U)

float rand (vec2 p)
{
    return fract(sin(dot(p.xy,vec2(12389.1283,8941.1283)))*(12893.128933));
}

bool removed(float h, vec2 p)
{
    float h2 = rand(vec2(20.+h*(+floor(p.y))+10.84));
    return h*dot(h,h2)*5.<=.5;
}

void main(void)
{
    vec4 c=glFragColor; 
    vec2 p = ((2.0*gl_FragCoord.xy-R)/R.y),u=p;
    p = vec2(log(length(p.xy)), atan(p.y,p.x));
    p*= (6.0/PI)*10.;
    p+=vec2(p.y/3.34-time*3.,6.);    
    vec2 lp = fract(p);
    p=floor(p);
    float hash = rand(p),
          size = 4.;
    vec3 col = vec3(0.);
    if(!removed(hash, p))col=vec3(SS(length(lp-.5)-.4));       
    p=mod(p+2.,vec2(size+2.*4.,10.));    
    col*=min(length(u)*4.,1.);
    if(abs(p.x)<=size&&abs(p.y)<=size)c.rgb=col;
    glFragColor=c;
}
