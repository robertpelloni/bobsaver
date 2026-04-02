#version 420

// original https://neort.io/art/bq2hidc3p9fefb926vpg

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define NEAR (1.0)
#define FAR (20.0)

#define repeat(m,n) (mod(m,n*2.0)-n)
#define PI acos(-1.0)
void rotate(inout vec2 v,float a){
  float c=cos(a),s=sin(a);
  v=vec2(v.x*c-v.y*s,v.x*s+v.y*c);
}

float smin(float a,float b,float k){
  return -log(exp(-a*k)+exp(-b*k))/k;
}

vec2 rotateRe(vec2 v,float a){
  vec2 vb=v;
  rotate(vb,a);
  return vb;
}

vec3 camera(vec2 uv,vec3 pos){
  float fov=1.0;
  vec3 forw=normalize(vec3(0.0,0.3,1.0));
  vec3 up=vec3(0.0,1.0,0.0);
//  vec3 right=vec3(1.0,0.0,0.0);
vec3 right=normalize(vec3(rotateRe(forw.xz,asin(-1.0)),0.0).xzy);

  return normalize(uv.x*right+uv.y*up+fov*forw);
}

float sdPyramid( vec3 p, float h)
{
  float m2 = h*h + 0.1;
    
  p.xz = abs(p.xz);
  p.xz = (p.z>p.x) ? p.zx : p.xz;
  p.xz -= 0.4;

  vec3 q = vec3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);
   
  float s = max(-q.x,0.0);
  float t = clamp( (q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0 );
    
  float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
  float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);
    
  float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);
    
  return sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float treeIfs(vec3 p,inout vec4 col){
  vec3 z=p;
  float scale=1.3,sum=scale,d=10.0,h=2.0;
#define IMAX (18.0)
  float count=0.0;
  for(float i=0.0;i<IMAX;i++){
    float td = (i>IMAX-6.0)?sdSphere(z,0.6):sdPyramid(z,h) / sum;
    
    d = (i>IMAX-7.0)?min(d,td):smin(td, d,0.5+i*5.0);
  //  d=min(d,td);
      if((z.y<0.0&&i==0.)||d<1e-4){break;}
    z = abs(z) - vec3(0, h*0.7, 0);

    float ofset=(i==0.0)?PI/10.0:0.0;
    rotate(z.xy,PI/4.5+ofset);
    //rotate(z.yz,PI/4.0);
    rotate(z.xz,PI/2.0);
    z *= scale;
    sum *= scale;
    count++;
  }
  col=(d<1e-4&&p.x>0.0&&p.y>0.0)?
          (count>IMAX-5.1)?
            vec4(1.,0.75,0.79,.1)
            :vec4(0.69,0.4156,0.066666,0.1)
          :vec4(0.0);
  return d;
}

float trees(vec3 p,inout vec4 col){
  float rep=2.0;
  p.z-=(p.x>0.0)?rep:0.0;
  p.z =repeat(p.z,rep);
  p.x=3.7+((p.x>0.0)?-p.x:p.x); 
  return treeIfs(p,col);
}

float map(vec3 p,inout vec4 col){
  return trees(p,col);
}

void colNomal(vec3 p,inout vec3 normal){
  float d=1e-4;
  vec4 dam;
  normal=normalize(
    vec3(1.0,1.0,1.0)*map(vec3(1.0,1.0,1.0)*d+p,dam)+
    vec3(1.0,-1.0,-1.0)*map(vec3(1.0,-1.0,-1.0)*d+p,dam)+
    vec3(-1.0,1.0,-1.0)*map(vec3(-1.0,1.0,-1.0)*d+p,dam)+
    vec3(-1.0,-1.0,1.0)*map(vec3(-1.0,-1.0,1.0)*d+p,dam)
    );

}

float march(vec3 dir,vec3 pos,inout vec4 col,inout vec3 normal){
  vec2 dist=vec2(NEAR,0.0);
  vec3 p;
  for(int i=0;i<60;i++){
    p=pos+dist.x*dir;
    dist.y=map(p,col);
    if(dist.x>FAR)break;    
    if(dist.y<1e-4){break;}
    dist.x+=dist.y;
  }
  colNomal(p,normal);
  return dist.x;
}

void main(){
  vec2 uv=(gl_FragCoord.xy*2.0-resolution)/min(resolution.x,resolution.y);
  vec3 pos=vec3(0.0,0.8,(time));
  vec3 dir=camera(uv,pos);
  vec4 col=vec4(0.0);
  vec3 normal=vec3(0.0);
  float dist=march(dir,pos,col,normal);

    glFragColor=vec4((col.w>0.0)?(col.xyz+dot(dir,normal)*.5)/max(1.0,(pow(length(dist),2.0)*0.5)):vec3(0.0),1.0);
    

}
