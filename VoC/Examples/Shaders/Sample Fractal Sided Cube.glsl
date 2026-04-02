#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
#define boxsize 1.5
float box(vec3 p)
{
    vec3 d=abs(p)-boxsize;
return    length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}
float pi=atan(1.0)*4.0,a=0.315/2.0;
  float ang=mod(time*0.01,4.0*pi);
  float t=cos(ang),r=0.5*(1.-t);
  
  vec2 c1=vec2((r+0.005)*t+0.25,(r+0.005)*sin(ang));
  vec2 c2=vec2(0.251*cos(ang)-1.0,0.251*sin(ang));
  vec2 c3=vec2(0.25/4.0*cos(ang)-1.0-0.25-0.25/4.0,0.25/4.0*sin(ang));
  vec2 c4=vec2(-0.125,0.7445)+0.095*vec2(cos(ang),sin(ang));
  vec2 c5=vec2((a+0.5*a)*cos(ang)-0.5*a*cos(3.0*ang),(a+0.5*a)*sin(ang)-0.5*a*sin(3.0*ang));
  vec2 c6=vec2(0.0,1.087)+0.158*(1.0-sin(ang))*vec2(cos(ang),sin(ang));
  vec2 c7=vec2(4.0*a*cos(ang)-a*cos(4.0*ang),4.0*a*sin(ang)-a*sin(4.0*ang));
  vec2 c= (ang<2.0*pi)?c1:c2;
vec3 Julia(vec2 p,vec2 c)
{
  vec2 s = p*0.8;
  float d = 0.0, l;
  for (int i = 0; i < 256; i++) {
    s = vec2(s.x * s.x - s.y * s.y + c.x, 2.0 * s.x * s.y + c.y);
    l = length(s);
    d += l + 0.2;
    if (l > 2.0) break;
  }
    return vec3(sin(d * 0.3), sin(d * 0.2), sin(d * 0.1))/(1.0+0.2*length(s));        
}

vec3 mandelbrot(vec2 p) {
  p.x+=1.5;
  vec2 s = p*0.5;
  float d = 0.0, l;
  for (int i = 0; i < 256; i++) {
    s = vec2(s.x * s.x - s.y * s.y + p.x, 2.0 * s.x * s.y + p.y);
    l = length(s);
    d += l+0.2;
    if(length(p-c)<0.01)return vec3(1.0);
      if (l > 2.0) break;
  }
  return vec3(sin(d * 0.31), sin(d * 0.2), sin(d * 0.1))/(1.0+0.2*length(p));
}
float calcolor(vec2 pos)
{
    float s=0.2;
    pos=mod(pos,2.0*s)-s;
    pos=abs(pos);
    float d=pos.x+pos.y-s,e=min(pos.x,pos.y),f=length(pos)-s*0.5*sqrt(2.0),g=length(pos-vec2(s,s))-s,h=length(pos-0.5*vec2(s,s))-0.5*s;
    return smoothstep(0.01,0.0,min(abs(h),min(abs(g),min(abs(f),min(abs(d)/1.414,e)))));    
}
float trace(vec3 p,vec3 dir,out vec3 target)
{
    float d,td=0.0;
    for(int i=0;i<50;i++){
        d=box(p/1.0);
        p+=dir*d;
        td+=d;
        if(d<0.001)break;        
    }    
    target=p;
    return td;
}
vec3 getcolor(vec3 p,vec3 dir)
{
    vec3 target,color;
    float d=trace(p,dir,target);
    vec2 pos;
    
        if(d<4.0){
            vec3 q=abs(target);
            if(abs(q.x-boxsize)<0.002){
                pos=target.yz;
                color=Julia(2.0*pos,c3);
            }
            else if(abs(q.y-boxsize)<0.002){    
                pos=target.xz;
                color=Julia(2.0*pos,c1);
            }
            else if(abs(q.z-boxsize)<0.002){
                pos=target.xy;
                color=Julia(2.0*pos,c2);
            }                 
        }    
    return color;
}
vec4 mul4(vec4 a,vec4 b)
{
    return vec4(a.xyz*b.w+a.w*b.xyz-cross(a.xyz,b.xyz),a.w*b.w-dot(a.xyz,b.xyz));
}
vec4 inv4(vec4 a)
{
    a.xyz=-a.xyz;
    return a/dot(a,a);    
}
vec3 rotate(vec3 pos,vec3 dir,float ang)
{
    dir=normalize(dir);
    vec4 q=vec4(dir*sin(ang*0.5),cos(0.5*ang));
    vec4 pos1=vec4(pos,1.0);
    q=mul4(q,mul4(pos1,inv4(q)));
    return q.xyz;    
}
void main( void ) {
    vec2 position = 2.0*( 2.0*gl_FragCoord.xy -resolution.xy)/ min(resolution.x,resolution.y );
    vec3 pos=vec3(position,3.0),dir=normalize(pos-vec3(0.0,0.0,8.0)),rotdir=normalize(vec3(mouse,1.0));
    pos=rotate(pos,rotdir,1.0*time);
    dir=rotate(dir,rotdir,1.0*time);
     
    glFragColor = vec4(  getcolor(pos,dir), 1.0 );

}
