#version 420

// original https://www.shadertoy.com/view/ssySDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//por jorge2017a1=jorge2017a2 :)
#define MAX_STEPS 110
#define MAX_DIST 120.
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

float Hash21(vec2 p)
{   p=fract(p*vec2(234.34,435.345));
    p+=dot(p,p+34.26);
    return fract(p.x*p.y);
}

vec4 truchet( in vec2 uv )
{   uv= rotatev2(uv, radians(45.0));
    vec3 col=vec3(0.0);
    vec2 gv=fract(uv)-0.5;
    vec2 id=floor(uv);
    float n=Hash21(id); //rango 0.0 a 1.0
    float width=0.1;

    if(n<0.5) gv.x*=-1.0;

    //----------
    /// Tip Shane....9/jun/2021
    float d=abs(gv.x + gv.y)*.7071; // Diagonal line.
    gv = abs(gv) - .5; // Corners.
    d = min(d, abs(gv.x + gv.y)*.7071); 
    //----------
    float  mask= d-width;
    float r = pow(1.0-sqrt( d),1.5 );
    float g = pow(1.0-sqrt( d),1.5 );
    float b = 1.0*(r+g);
    col+=vec3(r,g-0.8,b-0.8)*mask;
    return vec4(col,mask);
}

vec3 GetDist(vec3 p  ) 
{    vec3 res= vec3(9999.0, -1.0,-1.0);  

    
    float planeDist1 = p.y+0.0;  //piso inf
    vec3 pp=p;
    res =opU3(res, vec3(planeDist1,-1.0,7.0));
    p.y= opRep1D(p.y,40.0) ;
   vec4 t1= truchet(p.xy*0.65);
    float  d1=sdBox( p, vec3(20.0,20.0,1.0) ); 
    float d2= sdBox( p-vec3(0.0,0.0,3.0), vec3(20.0,20.0,2.0)  );
    float inter1= intersectSDF( d1,t1.w);
    float uni=unionSDF(d2, inter1);
    res =opU3(res, vec3(uni,1.0,-1.0));
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

vec3 LightShading(vec3 Normal,vec3 toLight,vec3 toEye,vec3 color)
{
    vec3 toReflectedLight=reflect(-toLight, Normal);
    vec3 diffuse = max(0.,dot(Normal,-toLight))*color;
    float specularf=max(dot(toReflectedLight, toEye),0.0);
    specularf=pow(specularf, 100.0);
    vec3 specular =specularf*vec3(1.0);
    return diffuse + specular;
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
     float sh;
    
    if (mObj.blnShadow==true)
        {
         vec3 r = reflect(rd, norm);
        sh=GetShadow(p,lp);
        sh+= occlusion(hit, lp);
        sh+=occlusion(hit,r);
        sh/=2.0;
        }
    else
        {sh=0.5;}    
    
        
    float dif = clamp(dot(norm, light), 0.0, 1.0);
    dif = pow(dif, 4.) * 2.;
    float spe = pow(max(dot(reflect(-light, norm), -rd), 0.), 8.);
    vec3 color = col * (dif + .35  + vec3(.35, .45, .5) * spe) + vec3(.7, .9, 1) * spe * spe;
    vec3 l = normalize( p-lightPos);
    vec3 v = normalize( p-ro);
    
    vec3 col2=LightShading(norm,l,v,col);
    color=(color+col2)/2.0;
    return color*sh+ color*atten * occ;
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

vec3 GetColorYMaterial(vec3 p,  vec3 n, vec3 ro,  vec3 rd, int id_color, float id_material)
{      vec3 colobj; 
    
    if( mObj.hitbln==false) return  render_sky_color(rd);
    
    if (id_color<100)
        { colobj=getColor(int( id_color)); }
    
    return colobj;
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
    }
    else if(d>MAX_DIST)
    col= render_sky_color(rd);
   return col;
}

vec3 linear2srgb(vec3 c) {
    return mix(
        12.92 * c,1.055 * pow(c, vec3(1.0/1.8)) - 0.055,
        step(vec3(0.0031308), c));
}

vec3 exposureToneMapping(float exposure, vec3 hdrColor) 
{    return vec3(1.0) - exp(-hdrColor * exposure);  }

void main(void)
{  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
   mObj.uv=uv;
    float t;
    t=mod(time*3.0,360.0);
    itime=t;
    //mObj.blnShadow=false;
    mObj.blnShadow=true;
        
     light_pos1= vec3(10.0, 20.0, -5.0 ); light_color1=vec3( 0.5 );
     light_pos2= vec3( -20.0, 10.0, 30.0 ); light_color2 =vec3(1.0,0.0,0.0); 
 
   vec3 ro=vec3(0.0,5.0+t,-7.0);
   vec3 rd=normalize( vec3(uv.x,uv.y,1.0));
   rd= rotate_x(rd, radians(-30.0));
    light_pos1+=ro;
    light_pos2+=ro;
    
    vec3 col= Render( ro,  rd);
    col = linear2srgb(col);
    glFragColor = vec4(col,1.0);
}
