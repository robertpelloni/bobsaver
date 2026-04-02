#version 420

// original https://www.shadertoy.com/view/4ssGWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AMBIENT 0.01
#define GAMMA (1.0/2.2)
#define TINY_AMOUNT 0.001
#define MAX_TRACE_DEPTH 6
#define FOCUS_DISTANCE 4.0
#define APERTURE 0.06
#define SAMPLES_PER_PIXEL 32

vec3 LightPos = vec3( 5.0,3.0,2.0);
vec3 LightCol = vec3(70.0);
 
vec2 Pixel;
 
struct Ray
{
    vec3 Origin;
    vec3 Direction;
};

struct Intersection
{
  bool Intersected;
  vec3 Intersection;
  vec3 Normal;
 };
 
 struct Material
 {
  vec3 Colour;
  float Reflection;
  float Specular;
  float Sharpness;
 };
 
float Rand( float n)
{
     return fract(sin(n)*43758.5453123) ;
}

vec3 RotateY(vec3 v , float a)
{
    v = vec3( v.x*cos(a) - v.z*sin(a) , v.y , v.x*sin(a) + v.z*cos(a) );
    return v;
}

Ray CreatePrimaryRay2(float t , vec2 screen, int N)
{
    Ray r;
    float cYaw = t*0.25;
    r.Origin = vec3(0.0,1.0,-4.0);
    r.Direction = normalize( vec3( screen.x , screen.y , 1) );

    vec3 A = r.Origin;
    vec3 B = r.Origin + r.Direction * FOCUS_DISTANCE;
    
    A = A + APERTURE * vec3( Rand(float(100*N)+9.28742)-0.5 , Rand(float(100*N)+2.554627)-0.5 , 0.0 );    
    
    r.Origin = RotateY( A , cYaw );
    r.Direction = RotateY( normalize(B-A) , cYaw );

    return r;
}

 float TracePlane( Ray r , inout Intersection iSec , vec3 normal , float distance)
 {
    iSec.Intersected = false;
    float d = - r.Origin.y / r.Direction.y;
     if( d > 0.0 )
     {
         iSec.Intersected = true;
         iSec.Intersection = r.Origin + d * r.Direction;
         iSec.Normal = vec3(0.0,1.0,0.0);
     }
     return d;
 }
 
 float TraceSphere( Ray r , inout Intersection iSec , vec3 centre , float radius)
 {
    iSec.Intersected = false;
    float d=0.0,t0,t1;
    r.Origin -= centre;
    float a = dot(r.Direction, r.Direction);
    float b = 2.0 * dot(r.Direction, r.Origin);
    float c = dot(r.Origin, r.Origin) - (radius * radius);
    float disc = b * b - 4.0 * a * c;
    if (disc < 0.0)
        return -1.0;
    float distSqrt = sqrt(disc);
    float q;
    if (b < 0.0)
        q = (-b - distSqrt)/2.0;
    else
        q = (-b + distSqrt)/2.0;
    t0 = q / a;
    t1 = c / q;
    if (t0 > t1)
    {
        float temp = t0;
        t0 = t1;
        t1 = temp;
    }
    if (t1 < 0.0)
        return t0;
    iSec.Intersected = true;
    iSec.Intersection = r.Origin + t0 * r.Direction + centre;
    iSec.Normal = normalize(r.Origin + t0*r.Direction);
    return t0;
 }
 
 void Trace( Ray r , inout Intersection iSec, out Material m )
 {
    iSec.Intersected = false;
    float D , Dmin;
    Dmin = 1000000.0;
    Intersection iTemp;
    
    D = TracePlane(r , iTemp , vec3(0.0,1.0,0.0) , 0.0);
    if( iTemp.Intersected && D < Dmin )
    {
        Dmin = D;
        float q = sin(time*0.1) * 0.5;
        if( (fract(iTemp.Intersection.x)+q < 0.5 && fract(iTemp.Intersection.z)+q < 0.5) ||
            (fract(iTemp.Intersection.x)+q >= 0.5 && fract(iTemp.Intersection.z)+q >= 0.5))
            m.Colour = vec3(0.4);
        else
            m.Colour = vec3(0.02);
        m.Reflection = 0.2;
        m.Specular = 0.3;
        m.Sharpness = 2.0;
        iSec = iTemp;
    }
    
    D = TraceSphere(r , iTemp , vec3(0.0,1.0 + 0.4 * sin( time ),0.0) , 0.6);
    if( iTemp.Intersected && D < Dmin )
    {
        Dmin = D;
        m.Colour = vec3(0.01,0.01,0.1);
        m.Reflection = 0.6;
        m.Specular = 0.6;
        m.Sharpness = 50.0;
        iSec = iTemp;
        iSec.Normal += vec3( Rand( iSec.Intersection.x ) , 
                             Rand( iSec.Intersection.y ) , 
                             Rand( iSec.Intersection.z ) ) * 0.1 - 0.05;
        iSec.Normal = normalize( iSec.Normal );
    }
     
    D = TraceSphere(r , iTemp , vec3(1.5,0.4,0.0) , 0.4);
    if( iTemp.Intersected && D < Dmin )
    {
        Dmin = D;
        m.Colour = vec3(0.1,0.01,0.01);
        m.Reflection = 0.6;
        m.Specular = 0.6;
        m.Sharpness = 50.0;
        iSec = iTemp;
        iSec.Normal += vec3( 0.0 , sin(iSec.Intersection.y*150.0 + 10.0*time) , 0.0 ) * 0.05 - 0.025;
        iSec.Normal = normalize( iSec.Normal );
    }
     
    D = TraceSphere(r , iTemp , vec3(0.0,0.4,1.5) , 0.4);
    if( iTemp.Intersected && D < Dmin )
    {
        Dmin = D;
        m.Colour = vec3(0.01,0.1,0.01);
        m.Reflection = 0.6;
        m.Specular = 0.6;
        m.Sharpness = 50.0;
        iSec = iTemp;
    }
     
    D = TraceSphere(r , iTemp , vec3(-1.5,0.4,0.0) , 0.4);
    if( iTemp.Intersected && D < Dmin )
    {
        Dmin = D;
        m.Colour = vec3(0.1,0.1,0.01);
        m.Reflection = 0.6;
        m.Specular = 0.6;
        m.Sharpness = 50.0;
        iSec = iTemp;
        iSec.Normal += vec3( sin(iSec.Intersection.x*150.0) , 
                             0.0 , 
                             cos(iSec.Intersection.y*150.0) ) * 0.05 - 0.025;
        iSec.Normal = normalize( iSec.Normal );
    }
     
    D = TraceSphere(r , iTemp , vec3(0.0,0.4,-1.5) , 0.4);
    if( iTemp.Intersected && D < Dmin )
    {
        Dmin = D;
        m.Colour = vec3(0.1,0.01,0.1);
        m.Reflection = 0.6;
        m.Specular = 0.6;
        m.Sharpness = 50.0;
        iSec = iTemp;
    }
    
     float a = time * 2.0;
    D = TraceSphere(r , iTemp , vec3(2.0*cos(a),0.2,2.0*sin(a)) , 0.2);
    if( iTemp.Intersected && D < Dmin )
    {
        Dmin = D;
        m.Colour = vec3(sin(a),sin(a+2.1),sin(a+4.2))*0.1+0.3;
        m.Reflection = 0.1;
        m.Specular = 0.6;
        m.Sharpness = 50.0;
        iSec = iTemp;
    }
 }
 
 vec4 CalcColour(Ray r , Intersection iSec, Material m)
 {
     vec3 lDir = normalize(LightPos - iSec.Intersection);

      // Ambient
     vec3 c = m.Colour * AMBIENT;

     

    // Shadow ray
    Ray sr;
    Intersection si;
    Material sm;

    sr.Origin = iSec.Intersection + lDir * TINY_AMOUNT;
    sr.Direction = lDir;
     
    Trace( sr , si , sm );
    
    float lFactor = 1.0/pow(length(LightPos - iSec.Intersection),2.0);
     
     if( !si.Intersected )
     {
     
    
     
    // diffuse
    c += m.Colour * lFactor * LightCol * clamp( dot( iSec.Normal , lDir ) , 0.0 , 1.0); 

    // specular
    vec3 rDir = reflect( r.Direction , iSec.Normal );
    c += m.Specular * lFactor * LightCol * pow( clamp( dot( lDir , rDir ) , 0.0 , 1.0 ) , m.Sharpness );
     }
     
    return vec4(c,1.0);
 }
 
 
 vec4 TracePixel( Ray ray )
 {
  float coefficient = 1.0;
  vec4 col = vec4(0.0);
  Material mat;
  Intersection iSec;
  for(int i=0; i<MAX_TRACE_DEPTH; i++)
  {
    Trace( ray , iSec , mat );
    if( iSec.Intersected )
        col += coefficient * CalcColour( ray , iSec , mat );
    coefficient *= mat.Reflection;
    if( !iSec.Intersected || coefficient < 0.01 )
     break;
    ray.Direction = reflect( ray.Direction , iSec.Normal );
    ray.Origin = iSec.Intersection + TINY_AMOUNT * ray.Direction;
    iSec.Intersected = false;
  }
  return col;
 } 
 
void main(void)
 {
    Pixel = vec2( 1.0 / resolution.x , 1.0 / resolution.y );
   vec2 screen = gl_FragCoord.xy / resolution.xy - vec2(0.5,0.5);
   screen.x *= resolution.x / resolution.y;
   vec4 c = vec4(0.0);
    vec4 avg = vec4(0.0);
     vec4 oldAvg = vec4(-1000.0);
     int count = 0;
     for(int s=0;s<SAMPLES_PER_PIXEL;s++)
   {
     vec2 AAscreen = screen + 0.3*Pixel * vec2( Rand(float(100*s)+2.72545) , Rand(float(100*s)+5.278933) );
     Ray primaryRay = CreatePrimaryRay2( time , AAscreen , s);
     
     c += TracePixel(primaryRay);
     avg = c / float(s+1);
     if( s>3 && length( oldAvg-avg) < 0.02 )
         break;
     oldAvg = avg;
       count++;
   }
   glFragColor = vec4( pow(avg.xyz,vec3(GAMMA)) , 1.0 );
 }
