#version 420

// original https://www.shadertoy.com/view/NdByDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//----------image
//por jorge2017a2-
//bola bola---29-ene-2022
//https://www.shadertoy.com/view/NdSyDW
//https://www.shadertoy.com/view/Xls3D2

#define MAX_STEPS 100
#define MAX_DIST 100.
#define MIN_DIST 0.001
#define EPSILON 0.001
#define REFLECT 2

//----------common
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
#define COLOR_NO -1.0
#define COLORSKY vec3(0.1, 0.1, 0.6)

vec3  Arrcolores[] = vec3[] (
vec3(0,0,0),  //0
vec3(1.,1.,1.), //1
vec3(1,0,0),  //2
vec3(0,1,0),   //3
vec3(0,0,1),   //4
vec3(1,1,0),  //5
vec3(0,1,1),  //6 
vec3(1,0,1),   //7
vec3(0.7529,0.7529,0.7529),  //8
vec3(0.5,0.5,0.5),  //9
vec3(0.5,0,0),   //10
vec3(0.5,0.5,0.0),  //11
vec3(0,0.5,0),   //12
vec3(0.5,0,0.5),  //13
vec3(0,0.5,0.5),  //14
vec3(0,0,0.5),    //15
vec3(1.0, 0.8, 0.737),  //16
vec3(0.8, 0.8, 0.8),  //17
vec3(0.5, 0.5, 0.8),  //18
vec3(1, 0.5, 0),      //19
vec3(1.0, 1.0, 1.0),  //20
vec3(0.968,0.6588,  0.721),  //21
vec3(0, 1, 1),                           //22 
vec3(0.333, 0.803, 0.988),    //23
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

vec3 GetColorYMaterial(vec3 p,  vec3 n, vec3 ro,  vec3 rd, int id_color, float id_material);
vec3 getMaterial( vec3 pp, float id_material);
vec3 light_pos1;  vec3 light_color1 ;
vec3 light_pos2;  vec3 light_color2 ;

//operacion de Union  por FabriceNeyret2
#define opU3(d1, d2) ( d1.x < d2.x ? d1 : d2 )
#define opU(d1, d2) ( d1.x < d2.x ? d1 : d2 )

float sdSphere( vec3 p, float s )
    { return length(p)-s;}
float sdBox( vec3 p, vec3 b )
    { vec3 d = abs(p) - b;   return length(max(d,0.0))+ min(max(d.x,max(d.y,d.z)),0.0); }

float intersectSDF(float distA, float distB)
    { return max(distA, distB);}
float unionSDF(float distA, float distB)
    { return min(distA, distB);}
float differenceSDF(float distA, float distB)
    { return max(distA, -distB);}
float opRep1D( float p, float c )
    { float q = mod(p+0.5*c,c)-0.5*c; return  q ;}

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

//https://www.shadertoy.com/view/NdSyDW
float pathterrain(float x,float z)
{
    // Common height function for path and terrain
    return 
        sin(x*.5 )*1.+cos(z*.3 )*0.3
        +cos(x*3.+z )*0.1+sin(x-z*.2 )*0.2;
}

//https://www.shadertoy.com/view/Xls3D2
float height(in vec2 p)
{
    float h = sin(p.x*.1+p.y*.2)+sin(p.y*.1-p.x*.2)*.5;
    h += sin(p.x*.04+p.y*.01+3.0)*4.;
    h -= sin(h*10.0)*.1;
    return h;
}

vec3 GetDist(vec3 p  ) 
{    vec3 res= vec3(9999.0, -1.0,-1.0);  vec3 p0=p;
   float h1= pathterrain(p.x,p.z);
    float planeDist1 = p.y+h1;
    res =opU3(res, vec3(planeDist1,-1.0,7.0));
    
    float h2= height(p.yz);
    float planeDist3 = p.x+30.0+h2; 
    res =opU3(res, vec3(planeDist3,-1.0,9.0));
    
    float h3= height(p.yz);
    float planeDist4 = 30.0-p.x+h3; 
    res =opU3(res, vec3(planeDist4,-1.0,9.0));
    
    float h4= height(p.xz);
    float planeDist2 = 20.0-p.y+h4;  //piso sup
    res =opU3(res, vec3(planeDist2,-1.0,7.0));
   
    vec3 pnew=vec3(p.x-5.0,p.y-2.0, p.z-itime);
    float sds1=sdSphere(pnew, 2.0 );
    res =opU3(res, vec3(sds1,2.0,-1.0));
   
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

float occlusion(vec3 pos, vec3 nor)
{
    float sca = 2.0, occ = 0.0;
    for(int i = 0; i < 10; i++) {
        float hr = 0.01 + float(i) * 0.5 / 4.0;
        float dd = GetDist(nor * hr + pos).x;
        occ += (hr - dd)*sca;
        sca *= 0.6;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}

vec3 lightingv3(vec3 normal,vec3 p, vec3 lp, vec3 rd, vec3 ro,vec3 col, float t) 
{   vec3 lightPos=lp;
    vec3 hit = ro + rd * t;
    vec3 norm = GetNormal(hit);
    
    vec3 light = lightPos - hit;
    float lightDist = max(length(light), .001);
    float atten = 1. / (1.0 + lightDist * 0.125 + lightDist * lightDist * .05);
    light /= lightDist;
    
    float occ = occlusion(hit, norm);
    float dif = clamp(dot(norm, light), 0.0, 1.0);
    dif = pow(dif, 4.) * 2.;
    float spe = pow(max(dot(reflect(-light, norm), -rd), 0.), 8.);
    vec3 color = col*(dif+.35 +vec3(.35,.45,.5)*spe) + vec3(.7,.9,1)*spe*spe;
    color*=occ;
    return color;
}

vec3 Getluz(vec3 p, vec3 ro, vec3 rd, vec3 nor , vec3 colobj ,vec3 plight_pos, float tdist)
{  float intensity=1.0;
     vec3 result;
    result = lightingv3( nor, p, plight_pos,  rd,ro, colobj, tdist);
    return result;
}

vec3 render_sky_color(vec3 rd)
{   float t = (rd.x + 1.0) / 2.0;
    vec3 col= vec3((1.0 - t) + t * 0.3, (1.0 - t) + t * 0.5, (1.0 - t) + t);
    vec3  sky = mix(vec3(.0, .1, .4)*col, vec3(.3, .6, .8), 1.0 - rd.y);
    return sky;
}

//https://www.shadertoy.com/view/4lcSRn   ///IQ
vec3 pattern( in vec2 uv )
{   vec3 col = vec3(0.4);
    col += 0.4*smoothstep(-0.01,0.02,cos(uv.x*0.5)*cos(uv.y*0.5)); 
    col *= smoothstep(-1.0,-0.98,cos(uv.x))*smoothstep(-1.0,-0.98,cos(uv.y));
    return col;
}

vec3 getMaterial( vec3 pp, float id_material)
{ vec3 col=vec3(1.0);
  vec3 p=pp;
  vec3 l1;
    
    if (id_material==7.0)
        {return pattern( p.xz );}
    if (id_material==8.0)
        {return pattern( p.xy );}
    if (id_material==9.0)
        {return pattern( p.zy );}
}

vec3 GetColorYMaterial(vec3 p,  vec3 n, vec3 ro,  vec3 rd, int id_color, float id_material)
{      vec3 colobj; 
    
    if( mObj.hitbln==false) return  render_sky_color(rd);
    
    if (id_color<100)
        { colobj=getColor(int( id_color)); }

    if (id_material>-1.0 && id_color==-1)
        { 
            colobj=vec3(0.5);
            colobj*=getMaterial(p, id_material); 
            return colobj;
        }
    return colobj;
}

vec3 linear2srgb(vec3 c) 
{ return mix(12.92 * c,1.055 * pow(c, vec3(1.0/1.8)) - 0.055, step(vec3(0.0031308), c)); }

vec3 exposureToneMapping(float exposure, vec3 hdrColor) 
{ return vec3(1.0) - exp(-hdrColor * exposure); }

vec3 ACESFilm(vec3 x)
{   float a,b,c,d,e;
    a = 2.51; b = 0.03; c = 2.43; 
    d = 0.59; e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}

vec3 Render(vec3 ro, vec3 rd)
{  vec3 col = vec3(0);
   TObj Obj;
   mObj.rd=rd;
   mObj.ro=ro;
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
        result=  Getluz( p,ro,rd, nor, colobj ,light_pos1,d)*light_color1;
        result+= Getluz( p,ro,rd, nor, colobj ,light_pos2,d)*light_color2;   
        col= result;
        col= (ACESFilm(col)+linear2srgb(col)+col+ exposureToneMapping(3.0, col))/4.0 ;
    }
    else if(d>MAX_DIST)
    col= render_sky_color(rd);
   return col;
}

void main(void)
{  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
   mObj.uv=uv;
    float t;
    t=mod(time*10.0,500.0);
    itime=t;
    //mObj.blnShadow=false;
    mObj.blnShadow=true;
        
     light_pos1= vec3(-10.0, 120.0, -10.0 ); light_color1=vec3( 1.0,1.0,1.0 );
     light_pos2= vec3(10.0, 20.0, -10.0 ); light_color2 =vec3( 1.0,1.0,1.0 ); 
   vec3 ro=vec3(-5.0,1.0,0.0+t);
   float h1= pathterrain(ro.x,ro.z);
   ro.y-=h1;
   vec3 rd=normalize( vec3(uv.x,uv.y,1.0));
   rd= rotate_y(rd, radians(90.0));
   rd= rotate_x(rd, radians(5.0));
   
    light_pos1+=ro;
    light_pos2+=ro;
    vec3 col= Render( ro,  rd);
    glFragColor = vec4(col,1.0);
}

