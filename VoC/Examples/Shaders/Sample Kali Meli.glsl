#version 420

// original https://www.shadertoy.com/view/ttscD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define blend(c,b) mix(c.rgb,b.rgb,b.a)
#define shape(d,s) smoothstep(s,0.,d)
#define skin_color vec3(.8,.6,.5)
#define eyes_color vec3(.35,.25,.1)
#define lips_color vec3(.8,.45,.4)
#define hair_color vec3(.07,.0,.0)
#define headphones_color vec3(.0,.2,.4)
#define background_color vec3(1.,.2,.0)

float box(vec2 p, vec2 c) {
    return length(max(vec2(0.),abs(p)-c));
}

vec4 head(vec2 p) 
{
    p*=.77;
     p.x*=.94-p.y*p.y;
    p.x*=1.45;
    p.x*=1.-p.y*.9;
    p.x*=1.-smoothstep(-.05,.1,-p.y)*.05;
    p.x*=1.+smoothstep(0.1,.4,-p.y)*.15;
    float d=length(p)-.3;
    return vec4(skin_color-d*.7,shape(d,.01));
}

vec4 neck(vec2 p) 
{
    float d=p.x-.175-sin(p.y*30.+15.)*.02;
    return vec4(skin_color*.8,shape(d,.01));
}

vec4 headphones(vec2 pos) 
{
    vec2 p=pos;
    p.x=abs(p.x);
    p.x-=.28+p.y*p.y;
    p.x*=1.5;
    float d1=length(p)-.11;
    p.x-=.1;
    p.x*=2.;
    float d2=length(p)-.05;
    p=pos;
    p.x+=.37+sin(p.y*20.+4.)*.03+p.y*.3;
    float d3=abs(p.x)-.001;
    d3=max(d3,p.y);
    return vec4(headphones_color-min(0.,d1*4.)-shape(d2,.01)*.1-shape(d3,.01)*.2,shape(min(min(d1,d2),d3),.01));
}

vec4 eyes(vec2 pos) 
{
    pos.y-=.0;
    vec3 c=vec3(1.);
    pos.x-=.145;
    vec2 p=pos;
    p.y*=1.5+p.x*p.x*20.;
    p.y+=smoothstep(0.05,.1,-p.x)*.05;
    p.y=abs(p.y-.05)+.055;
    float d1=length(p)-.09;
    c-=abs(1.-shape(d1+.01,.015))*.4;
    p=pos;
    p.y-=.045;
    float d2=length(p)-.03;
    float d3=length(p)-.012;
    c=mix(c,eyes_color,shape(d2,.01));
    c*=1.-shape(d3,.015);
    p+=.005;
    float d4=length(p)-.003;
    c+=shape(d4,0.01)*.5;
    return vec4(c,shape(d1,.01));
}

float eyelids(vec2 pos) 
{
    vec2 p=pos;
    p.x-=.135;
    p.y-=.085-p.x*p.x*7.+p.x*.25;
    p.y*=15.;
    float d1=length(p)-.07;
    p=pos;
    p.x-=.155;
    p.y-=.06-p.x*p.x*5.;
    p.y*=15.;
    float d2=length(p)-.07;
    p=pos;
    p.x-=.15;
    p.x*=.8;
    p.y+=.01-p.x*p.x*7.;
    p.y*=15.;
    float d3=length(p)-.07;
    return shape(d1,.01)*.15+shape(d2,.03)*.5+shape(d3,.01)*.03;
}

float eyebrows(vec2 p) 
{
    p.x-=.135+p.x*.2;
    p.y-=.13-p.x*p.x*4.-smoothstep(.03,.1,p.x)*.03;
    p.y*=6.;
    float d=length(p)-.05;
    return shape(d,.04)*.7*(.5+fract(p.x*100.+p.y*10.)*.5);
}

float nose(vec2 pos) 
{
    vec2 p=pos;
    p*=.9;
    p.y-=p.x*p.x*3.;
    p.x*=smoothstep(0.,.05,p.x);
    p.y+=.16+cos(p.x*90.)*.005;
    p.y*=15.;
    float d1=length(p)-.08;
    p=pos;
    p.x-=.047;
    p.y+=.17;
    p.y*=2.;
    float d2=length(p)-.005;
    p=pos;
    p.y+=.02;
    p.x-=.045+p.y*p.y*3.;
    p.x*=10.;
    float d3=length(p)-.05;
    return shape(d1,.01)*.1+shape(d2,.03)*.15+shape(d3,.1)*.04;
}

float mouth(vec2 p) 
{
     p.y+=.27+cos(p.x*45.)*.005-p.x*p.x*2.-smoothstep(.1,.2,p.x)*.07;
    p.y*=20.;
    float d=length(p)-.13;
    return shape(d,.01)*.2;
}

vec4 lips(vec2 pos) 
{
    vec2 p=pos;
    p.y+=.29-p.x*p.x*3.;
    p.y-=smoothstep(.05,.07,p.x)*.01;
    p.y*=10.;
    float d1=length(p)-.12;
    p=pos;
    p.y+=.27-p.x*p.x*3.;
    p.y+=smoothstep(.05,.07,p.x)*.01;
    p.y*=8.;
    float d2=length(p)-.12;
    return vec4(lips_color,shape(min(d1,d2),.01));
}

vec4 hair(vec2 pos) {
    vec2 p=pos;    
    p.x-=.14-p.y*p.y*.3-smoothstep(.25,.6,p.y)*.1;
    p.x-=p.y*p.y*smoothstep(0.,.3,-p.x)*2.+sin(p.y)*.2;
    p.y-=.28-p.x*p.x+fract(p.x*20.+p.y*5.)*.1+fract(p.x*10.)*.05-p.x*.5;
    float d1=box(p,vec2(.2,.25));
    float h=fract(p.x*40.)*shape(d1,.01);
    p=pos;
    p.x*=-1.;
    p.x-=.17-p.y*p.y*.3-smoothstep(.22,.7,p.y)*.2;
    p.x-=p.y*p.y*smoothstep(0.,.3,-p.x)*2.+sin(p.y)*.2;
    p.y-=.29-p.x*p.x*.5+fract(p.x*15.+p.y*2.+.3)*.1+fract(p.x*20.)*.05-p.x*.5;
    float d2=box(p,vec2(.16,.25));
    h+=fract(p.x*40.)*shape(d2,.01);
    return vec4(hair_color,shape(min(d1,d2),.02));
}

float lighting(vec2 pos) {
    vec2 p=pos;
    p.y+=.14;
    p.y*=1.2;
    p.x*=.8;
    float d1=length(p)-.01;
    p.x-=.12;
    p.y*=1.;
    float d2=length(p)-.01;
    p=pos;
    p.y+=.19+cos(p.x*10.)*.07;
    p.y*=2.5;
    float d3=length(p)-.05;
    p=pos;
    p.y-=0.04;
    p.x-=.14;
    p.y*=1.5;
    float d4=length(p)-.05;
    p=pos;
    p.y-=0.05;
    p.x*=4.;
    float d5=length(p*p)+.075;
    p=pos;
    p.y+=.24-p.x*.2;
    p.x*=.4;
    float d6=length(p)-.001;
    p=pos;
    p.y+=.36-p.x*.4;
    p.x*=.4;
    float d7=length(p)-.01;
    return shape(d1,.05)*.2+shape(d2,.1)*.1+shape(d3,.1)*.15-shape(d4,.12)*.2+shape(d5,.1)*.7-shape(d6,.02)*.12+shape(d7,.05)*.2;
}

vec3 background(vec2 p) {
    float x=1.-p.x*p.x*5.;
    vec2 id=floor(p*15.);
    p=fract(p*15.)-.5;
    float d=shape(length(p)-.4,.2)*.8;
    float l=shape(length(p)-.2,.1)*.5;
    vec3 c=background_color*d+l;
    c*=fract(cos(time+dot(id.x,id.y)));
    return c*d+x*background_color;
}

vec3 render(vec2 p) 
{
    p*=.73;
    vec2 pos=p;
    p.x=abs(p.x);
    vec3 c=background(pos)*smoothstep(2.,3.,time);
    c=blend(c,neck(p));
    c=blend(c,headphones(pos));
    c=blend(c,head(p));
    c=blend(c,eyes(p));
    c=blend(c,lips(p));
    c-=nose(p);
    c-=eyelids(p);
    c-=eyebrows(p);
    c-=mouth(p);
    c+=lighting(p);
    c=blend(c,hair(pos));
    return c;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    uv=floor(uv*130.)/130.;
    vec3 col = render(uv);
    col*=mod(gl_FragCoord.xy.y,4.)*.35*min(1.,time/2.);
    glFragColor = vec4(col,1.0);
}
