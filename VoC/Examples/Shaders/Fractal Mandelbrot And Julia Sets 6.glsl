#version 420

// co3moz - mandelbrot
precision highp float;
uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERATION 640
float cave(vec2 p)
{
    float r=length(p+vec2(1.0,0.0));
    return smoothstep(0.01,0.0,abs(r-0.25));    
}
float cave2(vec2 p)
{
    p.x+=-0.25;
    float r=length(p);
    return smoothstep(0.01,0.0,abs(r-r*r/.5-p.x));
}
float cave3(vec2 p)
{
    float r=length(p+vec2(1.0+0.25+0.25/4.0,0.0));
    return smoothstep(0.01,0.0,abs(r-0.25/4.));
}
float cave4(vec2 p)
{
    vec2 ctr=vec2(-0.125,0.7445);
    float r=0.095;
    return smoothstep(0.0003,0.0,abs(length(p-ctr)-r));    
}
float cave5(vec2 p)//r=a(1-sin(a))
{
    vec2 ctr=vec2(0.0,1.087);
    p-=ctr;
    float sinang=1.0-length(p)/0.158,cosang=abs(sinang)<1.0?sqrt(1.0-sinang*sinang):0.0;
    if(p.x<0.0)cosang=-cosang;        
    float r=0.158*(1.0-sinang);
    vec2 p1=r*vec2(cosang,sinang);
    float d=length(p-p1);
    return smoothstep(0.01,0.0,d);    
}
vec2 r_ang(float r,float ang)
{
    return vec2(cos(ang),sin(ang))*r;
}
vec2 epicycloid(float a,float b,float ang)
{
    return r_ang(a+b,ang)-r_ang(b,(a+b)/b*ang);    
}
float pi2=3.1415926*2.0;
float dist(float a,float b,vec2 p)
{
     float l=length(p);
    if(l>a+2.0*b||l<a)return 0.0;
    float na=acos(((a+b)*(a+b)+b*b-l*l)/(2.0*(a+b)*b));//na=a/b*ang
    float d=100.0;
    for(float k=0.0;k<2.;k+=1.0){//k<a/b
        float ang1=b/a*(na+pi2*k),ang2=b/a*(-na+pi2*k);
        vec2 pos1=epicycloid(a,b,ang1),pos2=epicycloid(a,b,ang2);
        d=min(d,length(p-pos1)/sqrt((a+b)*(a+b)+b*b-2.0*(a+b)*b*cos(na)));
        d=min(d,length(p-pos2)/sqrt((a+b)*(a+b)+b*b-2.0*(a+b)*b*cos(na)));
    }
    return smoothstep(0.01,0.0,min(d,length(p)-a));
}

float pi=atan(1.0)*4.0,a=0.385;
  float ang=mod(time*0.1,4.0*pi);
  float t=cos(ang),r=0.5*(1.-t);
  
  vec2 c1=vec2((r+0.005)*t+0.25,(r+0.005)*sin(ang));
  vec2 c2=vec2(0.251*cos(ang)-1.0,0.251*sin(ang));
  vec2 c3=vec2(0.25/4.0*cos(ang)-1.0-0.25-0.25/4.0,0.25/4.0*sin(ang));
  vec2 c4=vec2(-0.125,0.7445)+0.095*vec2(cos(ang),sin(ang));
  vec2 c5=vec2((a+0.5*a)*cos(ang)-0.5*a*cos(3.0*ang),(a+0.5*a)*sin(ang)-0.5*a*sin(3.0*ang));
  vec2 c6=vec2(0.0,1.087)+0.158*(1.0-sin(ang))*vec2(cos(ang),sin(ang));
  vec2 c= (ang<2.0*pi)?c5:c6;

vec3 Julia(vec2 p)
{
  p.x-=1.5;
    vec2 s = p;
  float d = 0.0, l;
      
  for (int i = 0; i < ITERATION; i++) {
    s = vec2(s.x * s.x*s.x - 3.0*s.y * s.y*s.x + c.x, 3.0 * s.x * s.x*s.y-s.y*s.y*s.y + c.y);
    l = length(s);
    d += l+0.2;
      if (l > 2.0) break;
  }
    return vec3(sin(d * 0.31), sin(d * 0.2), sin(d * 0.1))/(1.0+0.2*length(p));
        
}
vec3 mandelbrot(vec2 p) {
  p.x+=1.5;
  vec2 s = p;
  float d = 0.0, l;
  float a=0.385;
  float db=max(dist(a,0.5*a,p),cave5(p));
  for (int i = 0; i < ITERATION; i++) {
    s = vec2(s.x * s.x*s.x - 3.0*s.x*s.y * s.y + p.x, 3.0 * s.x *s.x* s.y-s.y*s.y*s.y + p.y);
    l = length(s);
    d += l+0.2;
    if(length(p-c)<0.01)return vec3(1.0);
      if (l > 2.0) break;
  }
  return max(vec3(sin(d * 0.31), sin(d * 0.2), sin(d * 0.1))/(1.0+0.2*length(p)),db);
}

void main() {
    vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
  vec2 p = surfacePos*4.0;
  float b=0.385;
//   c=epicycloid(b,b*0.5,time*0.05);
//   c=vec2(0.0,1.087)+0.158*(1.0-sin(0.05*time))*vec2(cos(0.05*time),sin(0.05*time));
  glFragColor = vec4(p.x<0.0?mandelbrot(p):Julia(p), 1.0);
}
