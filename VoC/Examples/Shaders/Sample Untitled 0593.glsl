#version 420

// original https://www.shadertoy.com/view/tl3yWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define PI 3.14159265

vec2 pmod(vec2 p,float n)
{
    float a=atan(p.x,p.y)-PI/n;
    float r=2.0*PI/n;
    a=floor(a/r)*r-PI/n;
    return rot(a)*p;
}

float Sphere(vec3 p)
{
    return length(p)-0.15;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

#define foldingLimit 1.0
vec3 boxFold(vec3 z, float dz) {
    return clamp(z, -foldingLimit, foldingLimit) * 3.0 - z;
}

void sphereFold(inout vec3 z, inout float dz, float minRadius, float fixedRadius) {
    float m2 = minRadius * minRadius;
    float f2 = fixedRadius * fixedRadius;
    float r2 = dot(z, z);
    if (r2 < m2) {
        float temp = (f2 / m2);
        z *= temp;
        dz *= temp;
    } else if (r2 < f2) {
        float temp = (f2 / r2);
        z *= temp;
        dz *= temp;
    }
}

// ref: http://blog.hvidtfeldts.net/index.php/2011/11/distance-estimated-3d-fractals-vi-the-mandelbox/
#define ITERATIONS 12
float deMandelbox(vec3 p, float scale, float minRadius, float fixedRadius) {
    vec3 z = p;
    float dr = 1.0;
    for (int i = 0; i < ITERATIONS; i++) {
        z = boxFold(z, dr);
        sphereFold(z, dr, minRadius, fixedRadius);
        z = scale * z + p;
        dr = dr * abs(scale) + 1.0;
    }
    float r = length(z);
    return r / abs(dr);
}

float map(vec3 p)
{
    //p.xyz-=0.5;
    p.xy*=rot(time);
    p.xz*=rot(time);
    p.yz*=rot(time);
    // p=mod(p,0.1)-0.05;
    
    float d2=sdBox(p,vec3(1.5));
   
    vec3 pos=p;
    float s=1.;
    for(int i=0;i<2;i++)
    {
       // pos=mod(pos,2.0)-1.0;
        pos=abs(pos);
      //  pos.xy=pmod(pos.xy,3.0);
        pos-=0.4;
        if(pos.x<pos.y)pos.xy=pos.yx;
        if(pos.x<pos.z)pos.xz=pos.zx;
        if(pos.y<pos.z)pos.yz=pos.zy;
        float h=1.0;
        float a=PI/4.0;
        pos.xy*=rot(a);
        pos.yz*=rot(a);
         pos.xz*=rot(a);
       // pos.xy=pmod(p.xy,3.0);
        //pos.yz=pmod(p.yz,3.0);
        
        pos.x-=clamp(pos.x,-h,h);
        pos*=2.;
        s*=2.;
      
      }
      pos/=s;
      
     
      
     float d1= length(vec2(length(pos.xy)-2.0,pos.z))-0.2;
    
    return deMandelbox(pos, 2.0, 1.0, 2.3);;
    //return d1;
   // return max(d1,-d2);
}

void main(void)
{
    vec2 uv=(gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);
    vec3 ro=vec3(0.0,0.0,20.0);
    vec3 rd=vec3(uv.xy,-1.0);
    
    float d,t=0.0;
    for(int i=0;i<64;i++)
    {
        d=map(ro+rd*t*0.8);
        if(d<0.001||t>1000.0)
        {
            break;
        }
        t+=d;
    }
    
    vec3 col=vec3(exp(-0.1*t));
    //*vec3(0.835,0.608,0);
   
   
    glFragColor = vec4(col,1.0);
}
