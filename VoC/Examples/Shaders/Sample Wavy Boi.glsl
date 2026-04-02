#version 420

// original https://www.shadertoy.com/view/3sBcW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

precision highp float;
#define resolution resolution.xy
#define time time
#define pi 3.14159

vec3 render(vec2 fc)
{
    vec2 p=(fc.xy-.5*resolution)/
        max(resolution.x,resolution.y);
    vec2 q=p;
    float vig=smoothstep(.55,.1,length(p));
    float cnt=smoothstep(.0,.075,length(p));
    vec3 col=vec3(.0);
    float r=10.;
    float t=fract(time/r);
    t*=pi*2.;
    vec3 d=vec3(.0);
    p*=150.;
    float k=t*2.;
    float f=fwidth(length(p));
    float sky=smoothstep(.0,-.01,q.y);
    p.xy=p.yx*vec2(-1,1);
    float g=pow(sin(t*2.),3.)*.4;
    g*=.3;
    float i=.3;
    float j=-5.;
    p.x=abs(p.x);
    p.y+=sin(p.x+time)*sky*3.;
    
    d.x=abs(pow(p.x,i)/p.x+(1.-sky)*.2)
        *cos(p.x+j-time*2.)/sin(pow(p.x,i)-k*1.*sky+90.+sky*.2);
    d.y=sin(j*p.y/p.x-g*sky-time*sky);
    float w=d.x/d.y;
    
    float v=w;
    w=smoothstep(f*f*length(p),0.,abs(w));
    col=mix(vec3(.3,.7,1.)
            ,vec3(1.)
            ,1.-sky)*v*w;
    col*=smoothstep(.0,.12,abs(q.y));
    col*=5.;
    col*=vig;
    return col;
}

void main(void)
{
    vec2 fc = gl_FragCoord.xy;
    vec3 col=render(fc);
    col=pow(col,vec3(1./2.2));
    glFragColor=vec4(col,1.);
}
