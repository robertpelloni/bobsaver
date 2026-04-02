#version 420

// original https://www.shadertoy.com/view/NlyGWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

///-------------image
//por jorge2017a2-
//hexagonal grid
//https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

///------------common
struct TObj
{
    float id_color;
    float id_objeto;
    float id_material;
    float dist;
    vec3 normal;
    vec3 ro;
    vec3 rd;
    vec2 uv;
    vec3 color;
    vec3 p;
    vec3 phit; //22-mar-2021
    vec3 rf;
    float marchCount;
    bool blnShadow;
    bool hitbln;
};

    
TObj mObj;
vec3 glpRoRd;
vec2 gres2;
float itime;

#define PI 3.14159265358979323846264
#define MATERIAL_NO -1.0

vec3  Arrcolores[] = vec3[] (
vec3(0,0,0)/255.0,  //0
vec3(255.,255.,255.)/255.0, //1
vec3(255,0,0)/255.0,  //2
vec3(0,255,0)/255.0,   //3
vec3(0,0,255)/255.0,   //4
vec3(255,255,0)/255.0,  //5
vec3(0,255,255)/255.0,  //6 
vec3(255,0,255)/255.0,   //7
vec3(192,192,192)/255.0,  //8
vec3(128,128,128)/255.0,  //9
vec3(128,0,0)/255.0,   //10
vec3(128,128,0)/255.0,  //11
vec3(0,128,0)/255.0,   //12
vec3(128,0,128)/255.0,  //13
vec3(0,128,128)/255.0,  //14
vec3(0,0,128)/255.0,    //15
vec3(255, 204, 188)/255.0,  //16
vec3(0.8, 0.8, 0.8),  //17
vec3(0.5, 0.5, 0.8),  //18
vec3(1, 0.5, 0),      //19
vec3(1.0, 1.0, 1.0),  //20
vec3(247./255., 168./255.,  184./255.),  //21
vec3(0, 1, 1),                           //22 
vec3(85./255., 205./255., 252./255.),    //23
vec3(0.425, 0.56, 0.9)*vec3( 0.3, 0.2, 1.0 ),  //24 
vec3(0.8,0.8,0.8)*vec3( 0.3, 0.2, 1.0 ),       //25  
vec3(1.0,0.01,0.01)*vec3( 0.3, 0.2, 1.0 ),     //26
vec3(0.1, 0.5, 1.0),                           //27   
vec3(0.0, 0.6, 0.0),                       //28 
vec3(0.1,0.1,0.7),                          //29
vec3(0.99, 0.2, 0.1), //30
vec3(.395, .95, 1.), //31
vec3(0.425, 0.56, 0.9) 
);

vec3 getColor(int i)
{    
    if (i==-2 ) {return mObj.color; }       
    if (i>-1 ) 
        return Arrcolores[i];
}

#define MAX_STEPS 100
#define MAX_DIST 100.
#define MIN_DIST 0.001
#define EPSILON 0.001
#define REFLECT 2

vec3 GetColorYMaterial(vec3 p,  vec3 n, vec3 ro,  vec3 rd, int id_color, float id_material);
vec3 getMaterial( vec3 pp, float id_material);
vec3 light_pos1;  vec3 light_color1 ;
vec3 light_pos2;  vec3 light_color2 ;

//operacion de Union  por FabriceNeyret2
#define opU3(d1, d2) ( d1.x < d2.x ? d1 : d2 )
#define opU(d1, d2) ( d1.x < d2.x ? d1 : d2 )

float sdBox( vec3 p, vec3 b )
    { vec3 d = abs(p) - b;   return length(max(d,0.0))+ min(max(d.x,max(d.y,d.z)),0.0); }
///----------Operacion de Distancia--------
float intersectSDF(float distA, float distB)
    { return max(distA, distB);}
float unionSDF(float distA, float distB)
    { return min(distA, distB);}
float differenceSDF(float distA, float distB)
    { return max(distA, -distB);}
//----------oPeraciones de Repeticion
float opRep1D( float p, float c )
    { float q = mod(p+0.5*c,c)-0.5*c; return  q ;}
vec2 opRep2D( in vec2 p, in vec2 c )
    { vec2 q = mod(p+0.5*c,c)-0.5*c; return  q ;}
vec3 opRep3D( in vec3 p, in vec3 c )
    { vec3 q = mod(p+0.5*c,c)-0.5*c; return  q ;}
vec3  opRep(vec3 p, vec3 r)
   { return mod(p,r)-0.5*r; }
///------------------------------------
// object transformation
vec3 rotate_x(vec3 p, float phi)
{   float c = cos(phi);    float s = sin(phi);
    return vec3(p.x, c*p.y - s*p.z, s*p.y + c*p.z);
}
vec3 rotate_y(vec3 p, float phi)
{    float c = cos(phi);    float s = sin(phi);
    return vec3(c*p.x + s*p.z, p.y, c*p.z - s*p.x);
}
vec3 rotate_z(vec3 p, float phi)
{    float c = cos(phi);    float s = sin(phi);
    return vec3(c*p.x - s*p.y, s*p.x + c*p.y, p.z);
}

vec2 rotatev2(vec2 p, float ang)
{   float c = cos(ang);
    float s = sin(ang);
    return vec2(p.x*c - p.y*s, p.x*s + p.y*c);
}

float sdHexPrism( vec3 p, vec2 h )
{
  const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
  p = abs(p);
  p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
  vec2 d = vec2(
       length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
       p.z-h.y );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec3 GetDist(vec3 p  ) 
{    vec3 res= vec3(9999.0, -1.0,-1.0);  
    vec3 p0=p;
    
    p= opRep(p, vec3(11.7,9.5,10.0) );
    p.z=abs(p.z)-3.0;
    float d1= sdHexPrism(p, vec2(5.0,0.5) );
    float d2= sdHexPrism(p, vec2(4.5,1.0) );
    float d1d2=differenceSDF(d1, d2);
    
    p.x=abs(p.x)-2.7;
    p.y=abs(p.y)-4.70;
    float d3=sdBox( p-vec3(0.0,0.0,-1.0), vec3(0.25,0.25,3.0)  );
    
    res =opU3(res, vec3(d1d2,1.0,-1.0));
    res =opU3(res, vec3(d3,2.0,-1.0));
 
   
    return res;
}

vec3 GetNormal(vec3 p)
{   float d = GetDist(p).x;
    vec2 e = vec2(.001, 0);
    vec3 n = d - vec3(GetDist(p-e.xyy).x,GetDist(p-e.yxy).x,GetDist(p-e.yyx).x);
    return normalize(n);
}

float RayMarch(vec3 ro, vec3 rd, int PMaxSteps)
{   float t = 0.; 
    vec3 dS=vec3(9999.0,-1.0,-1.0);
    float marchCount = 0.0;
    vec3 p;
    
    #define DISTANCE_BIAS 0.75
    float minDist = 9999.0; 
    
    for(int i=0; i <= PMaxSteps; i++) 
    {      p = ro + rd*t;
        dS = GetDist(p);
        t += dS.x;
        if ( abs(dS.x)<MIN_DIST  || i == PMaxSteps)
            {mObj.hitbln = true; minDist = abs(t); break;}
        if(t>MAX_DIST)
            {mObj.hitbln = false;    minDist = t;    break; } 
        marchCount++;
    }
    mObj.dist = minDist;
    mObj.id_color = dS.y;
    mObj.marchCount=marchCount;
    mObj.id_material=dS.z;
    mObj.normal=GetNormal(p);
    mObj.phit=p;
    return t;
}

float GetShadow(vec3 p, vec3 plig)
{   vec3 lightPos = plig;
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    float dif = clamp(dot(n, l), 0., 1.);
    float d = RayMarch(p+n*MIN_DIST*2., l , MAX_STEPS/2);
    if(d<length(lightPos-p)) dif *= .1;
    return dif;
}

vec3 amb(vec3 c, float k)
{  return c * k; }

float diff(vec3 p,vec3 lp,vec3 n )
{   vec3 l = normalize(lp - p);
    float dif = clamp(dot(l, n), 0.0, 1.0);
    return dif;
}
float spec( vec3 p, vec3 lp,vec3 rd,vec3 n )
{ vec3 l = normalize(lp - p);
  vec3 r = reflect(-l, n);
  float spe =pow(clamp(dot(r, -rd), 0.0, 1.0), 20.0);
  return spe;
}

vec3 lightingv3(vec3 normal,vec3 p, vec3 lp, vec3 rd, vec3 ro,vec3 col) 
{   vec3 l = lp - p;
    vec3 ldir = normalize(p-rd);
    
    float distA = max(length(l), 0.01);
    float distB = 1.0/(length(p-lp));
    float dist=(distA+distB)/2.0;
    float atten = min(1./(1. + dist*0.5), 0.2);
    l /= (dist);
    
    vec3 n = normal;
       vec3 amb=amb(col, 0.5);
    float dif = diff( p, lp, n );
    float spe= spec(  p,  lp, rd, n );
    float occ = 0.5 + 0.5*n.y;

    float fshadow;
    if (mObj.blnShadow==true) {fshadow=GetShadow(p,lp);}
    else {fshadow=0.5;}

    vec3 lin=vec3(1.0);
    lin*= amb*occ;

    lin += 1.0*(dif)*occ;
    lin += 2.5*spe*vec3(1.0);
    lin *= atten*0.5*col*fshadow;
    lin *= vec3(1.0)*  max(normalize(vec3(length(lin))).z, 0.)+ .75; 
    lin = pow(lin,vec3(0.4545)); 
    return lin;
}

vec3 Getluz(vec3 p, vec3 ro, vec3 rd, vec3 nor , vec3 colobj ,vec3 plight_pos)
{  float intensity=1.0;
     vec3 result;
    result = lightingv3( nor, p, plight_pos,  rd,ro, colobj);
    return result;
}

vec3 GetColorYMaterial(vec3 p,  vec3 n, vec3 ro,  vec3 rd, int id_color, float id_material)
{      vec3 colobj; 
   
    if (id_color<100)
        { colobj=getColor(int( id_color)); }
    return colobj;
}

vec3 Render(vec3 ro, vec3 rd)
{  vec3 col = vec3(0);
   TObj Obj;
   mObj.rd=rd;mObj.ro=ro;
   vec3 p;

     float d=RayMarch(ro,rd, MAX_STEPS);
   
    Obj=mObj;
    if(mObj.hitbln) 
    {   p = (ro + rd * d );  
        vec3 nor=mObj.normal;
        vec3 colobj;
        colobj=GetColorYMaterial( p, nor, ro, rd,  int( Obj.id_color), Obj.id_material);

        float dif1=1.0;
        vec3 result;
        result=  Getluz( p,ro,rd, nor, colobj ,light_pos1);
        result+= Getluz( p,ro,rd, nor, colobj ,light_pos2);
        col= result;
        col *= 1.0 - pow(d/(MAX_DIST) , 2.5);    
    }
   
   return col;
}

///---------------------------------------------
vec3 linear2srgb(vec3 c) {
    return mix(
        12.92 * c,1.055 * pow(c, vec3(1.0/1.8)) - 0.055,
        step(vec3(0.0031308), c));
}

vec3 exposureToneMapping(float exposure, vec3 hdrColor) 
{    return vec3(1.0) - exp(-hdrColor * exposure);  }

// See: http://filmicgames.com/archives/75
vec3 Uncharted2ToneMapping(vec3 color)
{
    float gamma = 2.2;
    float A = 0.15;
    float B = 0.50;
    float C = 0.10;
    float D = 0.20;
    float E = 0.02;
    float F = 0.30;
    float W = 11.2;
    float exposure = 0.012;
    color *= exposure;
    color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
    float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
    color /= white;
    color = pow(color, vec3(1. / gamma));
    return color;
}

///---------------------------------------------
void main(void)
{  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
   mObj.uv=uv;
    float t;
    t=mod(time*5.0,360.0);
    itime=t;
    //mObj.blnShadow=false;
    mObj.blnShadow=true;
        
     light_pos1= vec3(10.0, 10.0, -10.0 ); light_color1=vec3( 1.0 );
     light_pos2= vec3( -10.0, 5.0,10.0 ); light_color2 =vec3( 1.0 ); 
 
   vec3 ro;
   ro=vec3(6.0,15.0,-25.0+t);
   vec3 rd=normalize( vec3(uv.x,uv.y,1.0));
   
   float tt=time*2.5;
   float t1=mod(time,4.0);
   float t2=mod(time,8.0);
   
   if (t1<t2)
   {    
       ro=vec3(6.0,15.0+t,-25.0);
       rd= rotate_y(rd, radians(tt));
   }    
      
    light_pos1+=ro;
    light_pos2+=ro;
    vec3 col= Render( ro,  rd);
    col=exposureToneMapping(2.0, col);
    col=linear2srgb(col);
    col+=Uncharted2ToneMapping(col);
    
    glFragColor = vec4(col,1.0);
}
