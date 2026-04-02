#version 420

// original https://www.shadertoy.com/view/fsXBzN

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = atan(-1.);

mat2 rot(float a)
{
  float c=cos(a),s=sin(a);
  return mat2(c,-s,s,c);
}

vec2 fan(vec2 p, int n)
{
  float N=float(n);
  
  float a = atan(p.y,p.x);
  a=mod(a,pi*2./N)-pi/N;
  return length(p)*vec2(cos(a),sin(a));

}

float box(vec3 p, vec3 s)
{
  vec3 d = abs(p)-s;
  return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

float map(vec3 p)
{
    float t = float(frames)/60.;
    //p*=.2;
    p.xz*=rot(-1.8);
    
    t*=30.;
    float d = 1e3;
    
    
    float k = .5;
    float kk = .0625;
    float n = -.075;
    
    float gears = 40.;
    float gearheight=.015;
    float height =.05;
    vec3 q=p;
    {
    p.y-=k+kk;
    p.x-=n;
    p=p.yxz;
    float a = atan(p.z,p.x);
    float b = a;
    
    
    //p.
    //p.yz*=rot(-pi/4.);
    p.xz*=rot(pi/2.);
    p.yz*=rot(-pi/2.);
    p.xz=fan(p.xz,300)-vec2(k,.0);
    p.xy*=rot(a/2.);
    
    d=box(p,vec3(.1,height-(sin(b*gears+gears/(pi*2.)+t))*gearheight,5.));
    
    }
    
    
    {
    q=-q;
    q.y-=k+kk;
    q.x-=n;
    q=q.yxz;
    float a = atan(q.z,q.x);
    
    //p.
    //p.yz*=rot(-pi/4.);
    
    q.xz*=rot(pi/2.);
    q.yz*=rot(-pi/2.);
    q.xz=fan(q.xz,300)-vec2(k,.0);
    q.xy*=rot(a/2.);
    
    d=min(d,
    box(q,vec3(.1,height-(sin(a*gears-t))*gearheight,5.)
    ))
    ;
    
    }
    
    return d*.7;
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(1,0)*.0025;
  return normalize(vec3(
  map(p+e.xyy)-map(p-e.xyy),
  map(p+e.yxy)-map(p-e.yxy),
  map(p+e.yyx)-map(p-e.yyx)
  ));
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 col = vec3(0);
    
    
    float t= 0.;
    vec3 ro = vec3(0,0,-5);
    vec3 rd = normalize(vec3(uv,2.5));
    bool hit= false;
    
    for(int i =0;i<128;++i)
    {
      float h = map(ro+rd*t);
      
      if(h < .01)
      {hit=true;break;}
      if(t>15.)break;
      t += h;
    }
    
    if(hit)
    {
      vec3 p = ro+rd*t;
      vec3 n = normal(p);
      vec3 l = normalize(vec3(3,4,-5));
      float dif=max(0.,dot(l,n));
      col += .05+dif;
    }
    
    

    glFragColor = vec4(col,1.0);
}
