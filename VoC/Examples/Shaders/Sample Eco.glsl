#version 420

// original https://www.shadertoy.com/view/7s3XR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 o = gl_FragCoord.xy;
    o-=resolution.xy/vec2(2.0);
    o/=resolution.y/vec2(7.0);
    
    float x = (mod(abs(o.x),100.0));
    float y = (mod(abs(o.y),100.0));
    
    float mx = 0.0; //(-resolution.x/2.0+mouse*resolution.xy.x)/resolution.x*8.0;
    float my = 0.0; //(-resolution.y/2.0+mouse*resolution.xy.y)/resolution.y*8.0;
    
    float R = x*x+y*y;
    float L=pow(o.x+(mx)/5.0,2.0)+pow(o.y+(my)/5.0,2.0);
    
    float t = mod(time,x/y);
    float f = mod(time,y/x);
    
    float r1 = f*sin(x+sin(x+y)*L)+f*cos(y-sin(x-y)*L);
    float r2 = t*sin(x+sin(y-x)*L)+t*cos(y-sin(-y-x)*L);   
    
    glFragColor = vec4(
        mod(cos(r1),cos(r2)),
        mod(cos(r1),sin(r2)),
        max(sin(r2),sin(r1)),
        //mod(cos(r1),cos(r2)),
        //1.5*mod(cos(r1),sin(r2)),
        //abs(sin(r2)*sin(r1)),
    0)/sin(pow(R,0.5));
}
