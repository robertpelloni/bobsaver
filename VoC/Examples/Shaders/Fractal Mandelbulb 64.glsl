#version 420

// original https://www.shadertoy.com/view/fsGGzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 200
#define MAX_DIST 130.   
#define SURF_DIST .001
float Power = 1.0;
int steps=0;
int S;
vec3 color;
void rot(inout vec2 p, float a){  
     float c,s;vec2 q=p;  
      c = cos(a); s = sin(a);  
      p.x = c * q.x + s * q.y;  
      p.y = -s * q.x + c * q.y; 
 } 
struct complex
{
   float x;
   float y;
   float z;
};
complex plus(complex a, complex b)
{
    complex c;
    c.x = a.x+b.x;
    c.y = a.y+b.y;
    c.z = a.z+b.z;
    return c;
}
complex mult(complex a, complex b)
{
     complex c;
     c.x = a.x*b.x - a.y*b.y + a.y*b.z + a.z*b.y - a.z*b.z;
     c.y = a.x*b.y+a.y*b.x;
     c.z = a.x*b.z + a.z*b.x;
     return c;
}
float smin(float a,float b,float k)
{
     float h=clamp(0.5+0.5*(b-a)/k,.0,1.);
     return mix(b,a,h)-k*h*(1.-h);
}
float mand(vec3 pos)
{
    pos/=2.0;
    complex Z;
    Z.x = pos.x;
    Z.y = pos.y;
    Z.z = pos.z;
    
    float dr = 1.0;
    float r = 0.0;
    for (int i = 0; i < 40 ; i++)
    {
         r = sqrt(Z.x*Z.x+Z.y*Z.y+Z.z*Z.z);
         if(r>2.0) break;
         Z = mult(Z,Z);
         Z.x+=pos.x;
         Z.y+=pos.y;
         Z.z+=pos.z;
         complex g;
         g.x = Z.x*2.0*dr;
         g.y = Z.y*2.0*dr;
         g.z = Z.z*2.0*dr;
         
         dr = 1.0+sqrt(g.x*g.x+g.y*g.y+g.z*g.z);
    }
    return 0.5*log(r)*r/dr;
}
float SDF(vec3 pos) {
    vec3 z = pos;
    z.x=pos.x;
    z.y=pos.y;
    z.z=pos.z;
    float dr = 1.0;
    float r = 0.0;
    for (int i = 0; i < 20 ; i++) {
        r = length(z);
        
        if (r>4.0) break;
        
        
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow( r, Power-1.0)*Power*dr + 1.0;
        
        
        float zr = pow( r,Power);
        theta = theta*Power;
        phi = phi*Power;
        
        
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
        
    }

    return 0.5*log(r)*r/dr;
}
float sphere(vec4 s,vec3 p)
{
   return length(p-s.xyz)-s.w;
}
float GetDist(vec3 p)
{
rot(p.xz,sin(time/11.0+1.0)*3.14);
rot(p.yz,cos(time/14.0)*3.14);
float l = SDF(p);
float l2 = sphere(vec4(0.0,0.0,0.0,2.0),p);

if(l2>3.0)
return min(l,l2);
else
return l;
}
float RayMarch(vec3 ro,vec3 rd)
{
    float dO=0.0;
    for(int i=0; i<MAX_STEPS; i++)
    { 
        steps = i;
        vec3 p=ro+rd*dO;
        float ds=GetDist(p);
        dO+=ds;
        if(MAX_DIST<dO || ds<SURF_DIST)
        break;
    }
    return dO;
}
vec3 GetNormal(vec3 p)
{
    float d = GetDist(p);
    vec2 e = vec2(.001,0);

    vec3 n = d-vec3(
       GetDist(p-e.xyy),
       GetDist(p-e.yxy),
       GetDist(p-e.yyx));
     
     return normalize(n);
}
float GetLight(vec3 p)
{
    vec3 pos = vec3(5.*sin(time),5,-6.*cos(time)+6.);
    vec3 l=vec3(1.,2.,-2.);
    l = normalize(l);
    vec3 n = GetNormal(p);
    float dif = mix(0.2,1.,dot(n,l));
    
    float d=RayMarch(p+n*0.01,l);
    if(d<MAX_DIST)
    dif/=3.0;
    
    return dif;
}
void main(void)
{
    Power = 1.0+time/5.0;
    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.0);
    
    vec3 ro = vec3(0.,0.0,-3.2);
    vec3 rd = normalize(vec3(uv.xy,1.0));
    
    float d = RayMarch(ro,rd);
    S=steps;
    vec3 p=ro+rd*d;
    
    float dif = GetLight(p);
    
    color = mix(vec3(0.0,0.0,0.7),vec3(0.0,1.0,0.0),length(p)/2.0);
    if(d<MAX_DIST && steps<MAX_STEPS)
    col=vec3(dif)*color;

    float k = float(S)/float(MAX_STEPS);
    
    glFragColor = vec4(col+mix(vec3(1.0,0.0,0.0),vec3(0.25,0.0,1.0),k)*k*1.5,1.0);
}
