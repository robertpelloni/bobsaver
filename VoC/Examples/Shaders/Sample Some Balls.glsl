#version 420

// original https://www.shadertoy.com/view/wlBGRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float R=0.3;
vec3 sph=vec3(0.5,0.5,0.5);    

vec4 Distance(vec3 p) {
float dst,h;
vec3 grad;
vec3 pt;
float ID;
float rad;
    
   ID=floor(p.x)+floor(p.y)+floor(p.z);
   rad=0.3+0.05*sin(ID+time*1.0);
   p.x=fract(p.x);
   p.y=fract(p.y);
   p.z=fract(p.z);
   pt=p-sph;
   h=dot(pt,pt);
   dst=h-rad*rad+0.001*(sin(p.x*200.0)+
                        sin(p.y*200.0)+
                        sin(p.z*200.0));
       
   grad=2.0*pt+0.001*200.0*vec3(cos(p.x*200.0),
                                cos(p.y*200.0),
                                cos(p.z*200.0));                   
   h=length(grad);
   if (h>1.0) 
       dst=dst/h;
    
   return vec4(grad,dst);
}

void main(void)
{
    
    vec3 pos=vec3(20.0*sin(time*0.031),0,20.0*sin(time*0.0234));
    vec3 dir2=vec3(gl_FragCoord.xy-resolution.xy/2.0,resolution.x); 
    vec3 dir;
    float angle=time*0.02045;
    float dist;
    vec3 p,n;
    vec3 lp,lv;
    int i;
    vec4 h;
    mat4 m;
     
    dir.x=dir2.x;
    dir.y=dir2.y*cos(angle)-dir2.z*sin(angle);
    dir.z=dir2.y*sin(angle)+dir2.z*cos(angle);
    
    dir=dir/length(dir);

    lp=vec3(40.0*sin(time),40.0*cos(time),0);
    
    dist=0.0;
    for (i=0;i<500;i++) {
      h=Distance(pos+dist*dir);
      dist+=h.w;
      if (h.w<0.0001) break;
    }
    n=h.xyz;
    n=n/length(n);
    lv=lp-p;
    lv=lv/length(lv);
    float shade=(0.5*dot(lv,n)+0.5)/(1.0+dist*0.01);
   
    
    shade=clamp(shade,0.0,1.0);
    vec3 color=vec3(shade,shade,shade);
    if (i==500) glFragColor=vec4(0,0,0,0);
           else glFragColor=vec4(color,0);
}
