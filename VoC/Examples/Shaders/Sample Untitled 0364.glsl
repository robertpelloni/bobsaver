#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
float num=5.0;
float  dim=1.5,size=dim/num,thk=0.02;

float box(vec3 p)
{
    vec3 d=abs(p)-dim;
    return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

float pi=atan(1.0)*4.0;
  float ang=mod(time*0.1,6.0*pi);
  float t=cos(ang),r=0.5*(1.-t);
  
  vec2 c=vec2(r*t+0.25,r*sin(ang));

float calcolor(vec2 pos)
{

    float dr=1.0;
    float s=size;
    pos=mod(pos,2.0*size)-size;
    pos=abs(pos);
    float d=pos.x+pos.y-s,e=min(pos.x,pos.y),f=length(pos)-s*0.5*sqrt(2.0),g=length(pos-vec2(s,s))-s,h=length(pos-0.5*vec2(s,s))-0.5*s;
    return smoothstep(thk,0.0,min(abs(h),min(abs(g),min(abs(f),min(abs(d)/1.414,e)))));    
}
vec3 getNormal(vec2 pos)
{
    float d=calcolor(pos);
    float dx=calcolor(vec2(pos.x+0.0001,pos.y))-d,dy=calcolor(vec2(pos.x,pos.y+0.0001))-d;
    vec3 norm=cross(vec3(0.0001,0.0,dx),vec3(0.0,0.0001,dy));
    return normalize(norm);    
}
vec3 target[2];
int faceid[2];
float trace(vec3 p,vec3 dir)
{
    int idx=0;
    float b=dot(p,dir),delt=b*b-dot(p,p)+3.0;
    float t1=-b+sqrt(delt),t2=-b-sqrt(delt);
    vec3 p1=p+dir*t1,p2=p+dir*t2;
    p1=abs(p1),p2=abs(p2);
    float max1=max(max(p1.x,p1.y),p1.z),max2=max(max(p2.x,p2.y),p2.z);
    if(max1==p1.x){
        p1/=p1.x;
        p1*=dim;
        target[0].xy=p1.yz;target[0].z=t1;
    }
    else if(max1==p1.y){
        p1/=p1.y;
        p1*=dim;
        target[0].xy=p1.xz,target[0].z=t1;
    }
    else {
        p1/=p1.z;
        p1*=dim;
        target[0].xy=p1.xy,target[0].z=t1;
    }
    if(max2==p2.x){
        p2/=p2.x;
        p2*=dim;
        target[1].xy=p2.yz,target[1].z=t2;
    }
    else if(max2==p2.y){
        p2/=p2.y;
        p2*=dim;
        target[1].xy=p2.xz,target[1].z=t2;
    }
    else {
        p2/=p2.z;
        p2*=dim;
        target[1].xy=p2.xy,target[1].z=t2;
        
    }
    /*
    float tx1=(dim-p.x)/dir.x;
    vec2 pos=abs(vec2(p.yz+tx1*dir.yz));
    if(pos.x<dim&&pos.y<dim){
        if(idx==0){
            target[0].xy=pos;target[0].z=tx1;idx++;
            faceid[0]=0;
             }
        else {
            target[1].xy=pos;target[1].z=tx1;idx++;
            faceid[1]=0;
        }
    }
    
    float tx2=(-dim-p.x)/dir.x;
    pos=abs(vec2(p.yz+tx2*dir.yz));
    if(pos.x<dim&&pos.y<dim){
        if(idx==0){
            target[0].xy=pos;target[0].z=tx2;idx++;
            faceid[0]=1;
             }
        else {
            target[1].xy=pos;target[1].z=tx2;idx++;
            faceid[1]=1;
        }
    }
    
    float ty1=(dim-p.y)/dir.y;
    pos=abs(vec2(p.xz+ty1*dir.xz));
    if(pos.x<dim&&pos.y<dim){
        if(idx==0){
            target[0].xy=pos;target[0].z=ty1;idx++;
            faceid[0]=2;
             }
        else {
            target[1].xy=pos;target[1].z=ty1;idx++;
            faceid[1]=2;
        }
    }
    
    float ty2=(-dim-p.y)/dir.y;
    pos=abs(vec2(p.xz+ty2*dir.xz));
    if(pos.x<dim&&pos.y<dim){        
        if(idx==0){
            target[0].xy=pos;target[0].z=ty2;idx++;
            faceid[0]=3;
             }
        else {
            target[1].xy=pos;target[1].z=ty2;idx++;
            faceid[1]=3;
        }
    }

    
    float tz1=(dim-p.z)/dir.z;
    pos=abs(vec2(p.xy+tz1*dir.xy));
    if(pos.x<dim&&pos.y<dim){        
        if(idx==0){
            target[0].xy=pos;target[0].z=tz1;idx++;
            faceid[0]=4;
             }
        else {
            target[1].xy=pos;target[1].z=tz1;idx++;
            faceid[1]=4;
        }
    }
    
    float tz2=(-dim-p.z)/dir.z;
    pos=abs(vec2(p.xy+tz2*dir.xy));
    if(pos.x<dim&&pos.y<dim){
        if(idx==0){
            target[0].xy=pos;target[0].z=tz2;idx++;
            faceid[0]=5;
             }
        else {
            target[1].xy=pos;target[1].z=tz2;idx++;
            faceid[1]=5;
        }
    }
    if(target[0].z>target[1].z){
       vec3 t=target[0];
        target[0]=target[1];
        target[1]=t;
       int i=faceid[0];
       faceid[1]=faceid[0];
       faceid[0]=i;
    }
    if(idx==0)return 100.0;
    else return target[0].z;
*/
    if(delt<0.0)return 100.0;
    else return target[0].z;
}

vec3 faceNorm(int faceid)
{
            vec3 norm;
            if(faceid==0)norm=vec3(1.0,0.0,0.0);
            else if(faceid==1)norm=vec3(-1.0,0.0,0.0);
            else if(faceid==2)norm=vec3(0.0,1.0,0.0);
            else if(faceid==3)norm=vec3(0.0,-1.0,0.0);
            else if(faceid==4)norm=vec3(0.0,0.0,1.0);
            else norm=vec3(0.0,0.0,-1.0);
    return norm;
}
float getcolor(vec3 p,vec3 dir)
{
    float d=trace(p,dir),color=0.0;
    vec2 pos;
    int i=0;
        if(d<4.0){
            vec3 norm1=faceNorm(faceid[0]),norm2=-faceNorm(faceid[1]);
            
            color=calcolor(target[0].xy)/sqrt(1.0+target[0].z);      
            color=max(color,calcolor(target[1].xy)/sqrt(1.0+target[1].z));
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
    vec3 pos=vec3(position,2.0),dir=normalize(pos-vec3(0.0,0.0,8.0)),rotdir=normalize(vec3(mouse,1.0));//,light=normalize(vec3(0.4,0.3,1.0));
    vec3 bkclr=abs(vec3(cos(20.*position.y),sin(30.*position.x),cos(time)));
    pos=rotate(pos,rotdir,1.0*time);
    dir=rotate(dir,rotdir,1.0*time);
//    light=rotate(light,rotdir,1.0*time);
    float color=getcolor(pos,dir);
    vec3 clr=color<0.01?0.4*bkclr:vec3(color);
    glFragColor = vec4(clr, 1.0 );

}
