#version 420

// original https://www.shadertoy.com/view/tllyD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//por jorge2017a1-

///------------------------------------
struct TObj
{
    float tipo;
    float dist;
    vec3 normal;
    vec3 ro;
    vec3 rd;
    vec2 uv;
    vec3 color;
    vec3 p;
    vec3 rf;
};

    
TObj mObj;
vec3 glpRoRd;
vec2 gres2;
float itime;

///"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
mat2 r2d (in float degree)
{
    float rad = radians (degree);
    float c = cos (rad);
    float s = sin (rad);
    return mat2 (vec2 (c, s),vec2 (-s, c));
}

// using a slightly adapted implementation of iq's simplex noise from
// https://www.shadertoy.com/view/Msf3WH with hash(), noise() and fbm()
vec2 hash (in vec2 p)
{
    p = vec2 (dot (p, vec2 (127.1, 311.7)),
              dot (p, vec2 (269.5, 183.3)));

    return -1. + 2.*fract (sin (p)*43758.5453123);
}

float noise (in vec2 p)
{
    const float K1 = .366025404;
    const float K2 = .211324865;

    vec2 i = floor (p + (p.x + p.y)*K1);
    
    vec2 a = p - i + (i.x + i.y)*K2;
    vec2 o = step (a.yx, a.xy);    
    vec2 b = a - o + K2;
    vec2 c = a - 1. + 2.*K2;

    vec3 h = max (.5 - vec3 (dot (a, a), dot (b, b), dot (c, c) ), .0);

    vec3 n = h*h*h*h*vec3 (dot (a, hash (i + .0)),
                           dot (b, hash (i + o)),
                           dot (c, hash (i + 1.)));

    return dot (n, vec3 (70.));
}

float fbm (in vec2 p)
{
    mat2 rot = r2d (27.5);
    float d = noise (p); p *= rot;
    d += .5*noise (p); p *= rot;
    d += .25*noise (p); p *= rot;
    d += .125*noise (p); p *= rot;
    d += .0625*noise (p);
    d /= (1. + .5 + .25 + .125 + .0625);
    return .5 + .5*d;
}

float fbm2 (in vec2 p)
{

    float d = noise (p); 
    d /= (1. + .5 + .25 + .125 + .0625);
    return .5 + .5*d;
}

///"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

///-----------------------------------------
//----------------------------------------------------

vec3 getSphereColor(int i)
{
    
    float m;
        
if (i==0 ) { return vec3(0,0,0)/255.0; }
if (i==1 ) { return vec3(255.,255.,255.)/255.0; }
if (i==2 ) { return vec3(255,0,0)/255.0; }
if (i==3 ) { return vec3(0,255,0)/255.0; }
if (i==4 ) { return vec3(0,0,255)/255.0; }
if (i==5 ) { return vec3(255,255,0)/255.0; }
if (i==6 ) { return vec3(0,255,255)/255.0; }
if (i==7 ) { return vec3(255,0,255)/255.0; }
if (i==8 ) { return vec3(192,192,192)/255.0; }
if (i==9 ) { return vec3(128,128,128)/255.0; }
if (i==10 ) { return vec3(128,0,0)/255.0; }
if (i==11 ) { return vec3(128,128,0)/255.0; }
if (i==12 ) { return vec3(0,128,0)/255.0; }
if (i==13 ) { return vec3(128,0,128)/255.0; }
if (i==14 ) { return vec3(0,128,128)/255.0; }
if (i==15 ) { return vec3(0,0,128)/255.0; }
    
if (i==16 ) { return vec3(255, 204, 188)/255.0; }

      
    if(i== 139 )
    {
     
           vec3 p = glpRoRd;
           vec3 marbleP = p*2.0;
    
            marbleP.x += sin(p.y*0.5)*0.12;
            marbleP.z += sin(p.y*2.0)*0.1;
            marbleP.y += sin(p.x*5.0)*0.13;
            marbleP.y += sin(p.z*3.0)*0.14;

            marbleP.y += sin(p.x*1.3)*0.5;
            marbleP.y += sin(p.z*1.5)*0.6;

            marbleP.x += sin(p.y*10.0)*0.011;
            marbleP.z += sin(p.y*12.0)*0.013;
            marbleP.y += sin(p.x*15.0)*0.012;
            marbleP.y += sin(p.z*13.0)*0.015;

            marbleP.x *= 0.5;
            marbleP.z *= 0.8;
            marbleP.y *= 0.50;

            float marbleAmtA = abs(sin(marbleP.x)+sin(marbleP.y)+sin(marbleP.z))/3.0;
            marbleAmtA = pow(1.0-marbleAmtA,5.0);

            marbleP = p;

            marbleP.x += sin(p.y*21.0)*0.12;
            marbleP.z += sin(p.y*23.0)*0.1;
            marbleP.y += sin(p.x*22.0)*0.13;
            marbleP.y += sin(p.z*24.0)*0.14;

            marbleP.y += sin(p.x*1.2)*0.5;
            marbleP.y += sin(p.z*1.4)*0.6;

            marbleP.x += sin(p.y*150.0)*0.011;
            marbleP.z += sin(p.y*162.0)*0.013;
            marbleP.y += sin(p.x*145.0)*0.012;
            marbleP.y += sin(p.z*153.0)*0.015;

            marbleP.x *= 0.2;
            marbleP.z *= 0.3;
            marbleP.y *= 0.10;

            float marbleAmtB = abs(sin(marbleP.x)+sin(marbleP.y)+sin(marbleP.z))/3.0;
            marbleAmtB = pow(1.0-marbleAmtB,9.0);
            marbleAmtB = 1.0-(1.0-marbleAmtB*0.3);

            float marbleAmt = marbleAmtA + marbleAmtB;
            marbleAmt = clamp(marbleAmt,0.0,1.0);
            vec3 surfaceColor;
            
        
            surfaceColor = mix(vec3(0.4,0.4,0.6),vec3(0.50,0.1,0.2),marbleAmtA);
        
            return surfaceColor;    
        
            }  
    
    
   
   

}

///--------------------------------------------

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001

#define PI 3.14159265358979323846264

#define PI2 6.28318530717
#define TriplePI (3.0 * PI)
#define DoublePI (2.0 * PI)
#define HalfPI (PI / 2.0)

vec3 light_pos1   ;
vec3 light_color1 ;
vec3 light_pos2   ;
vec3 light_color2 ;

float intersectSDF(float distA, float distB) {
    return max(distA, distB);
}

float unionSDF(float distA, float distB) 
{
    return min(distA, distB);
}

float differenceSDF(float distA, float distB) 
{
    return max(distA, -distB);
}

vec2 opU(vec2 d1, vec2 d2 ) {
  vec2 resp;
    if (d1.x < d2.x){ 
        resp = d1;
    }
    else
    {
        resp = d2;
    }
     
   return resp; 
}

///-----------------------------------------

vec3 LightShading(vec3 N,vec3 L,vec3 V,vec3 color)
{
    vec3 diffuse = max(0.,dot(N,-L))*color;
    vec3 specular = pow(max(0.,dot(N,normalize(-L-V))),100.)*vec3(1.,1.,1.); 
    return diffuse + specular;
}

//-------------------------------------------------

float GetDist(vec3 p  ) 
{    

    float d, dif1, dif2;
    vec2 res;
    vec3 pp, p2,p3;
    
    
    pp=p;
    //p.xyz=pp.zyx;    
   
    pp=p;
    p2=p;
    p3=p;
    
 
    float planeDist1 = p.y+10.5;  //piso inf
    float planeDist2 = 30.0-p.y;  //piso sup
    float planeDist3 = p.x+30.0; //pared izq
    float planeDist4 = 30.0-p.x;  //pared der
    float planeDist5 = -p.z+40.0;  //pared atras
    float planeDist6 = p.z+40.0;  //pared atras
   
    
    res = vec2(9999, 0);
    
  
     
    
    float thickness = .25;
    float haze = 2.5;
    float d1 = 1.0-abs ((p.z*haze)*thickness / (p.z + fbm2 (p.xz + 1.25*time)));
  
    res =opU(res, vec2(d1,2.0 ));
    
    //res =opU(res, vec2(1.0,0 ));
    
    d = res.x;
    mObj.dist = res.x;
    mObj.tipo = res.y;
    
    return d;
}

//---------actualizacion por Shane---28-may-2020    ...gracias
float RayMarch(vec3 ro, vec3 rd) 
{
    
    // The extra distance might force a near-plane hit, so
    // it's set back to zero.
    float dO = 0.; 
    //Determines size of shadow
    for(int i=0; i<MAX_STEPS; i++) 
    {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
        
        dO += dS;
        
    }
    
    return dO;
}

//---------------------------------------------------

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    //Texture of white and black in image
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

float GetLightPar(vec3 p, vec3 plig) {
    vec3 lightPos = plig;
    //Determine movement of light ex. shadow and light direction and diffusion
    //lightPos.xz += vec2(1, 2);
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    float d = RayMarch(p+n*SURF_DIST*2., l );
    if(d<length(lightPos-p)) dif *= .1;
    
    return dif;
}

float saturate(float f)
{
    return clamp(f,0.0,1.0);
}

//----------------------------------------------------

// Single rotation function - return matrix
mat2 r2(float a){ 
  float c = cos(a); float s = sin(a); 
  return mat2(c, s, -s, c); 
}
//--------------------

// mouse*resolution.xy pos function - take in a vec3 like ro
// simple pan and tilt and return that vec3
vec3 get_mouse(vec3 ro) 
{
    float x = -.2;
    float y = .0;
    float z = 0.0;

    ro.zy *= r2(x);
    ro.zx *= r2(y);
    
    return ro;
}

// phong shading
vec3 p_shadingv2( vec3 v, vec3 n, vec3 eye, vec3 plight_pos1,  vec3 plight_color1 )
{
    // ...add lights here...
   //col2= p_shadingv2( p, nor, ro, light_pos1, light_color1 )*colobj;
  
    
    
    float shininess = 1.25;
    
    
    vec3 final = vec3( 0.0 );
    
    vec3 ev = normalize( v - eye );
    vec3 ref_ev = reflect( ev, n );
    
    // light 0
    //{
    
        vec3 vl = normalize( plight_pos1 - v );
    
        float diffuse  = max( 0.0, dot( vl, n ) );
        float specular = max( 0.0, dot( vl, ref_ev ) );
        specular = pow( specular, shininess );
        
        
        final += plight_color1 * ( diffuse + specular );
        //final += (plight_color1* diffuse + plight_color1*specular );
    //}
    
    
    
    

    return (final);
}

// phong shading
vec3 p_shadingv3( vec3 pos, vec3 normal, vec3 ro, vec3 rd, vec3 plight_pos1,  vec3 plight_color1 )
{
    // ...add lights here...
  
    float shininess = 1.25;
    
    
    vec3 final = vec3( 0.0 );
    
    vec3 ev = normalize( pos - ro );
    vec3 ref_ev = reflect( ev, normal );
    
    
        vec3 vl = normalize( plight_pos1 - pos );
    
        float diffuse  = max( 0.0, dot( vl, normal ) );
        float specular = max( 0.0, dot( vl, ref_ev ) );
        specular = pow( specular, shininess );
        
        
        final += plight_color1 * ( diffuse + specular );
        
    
    
    vec3 color = vec3(1.0);
    color = color * 0.75 + 0.25;
   
    color *= normal * .25 + .75;
    
    
    float ambient2 = 0.1;
    float diffuse2 = 0.5 * -dot(normal,rd);
    float specular2 = 1.0 * max(0.0, -dot(rd, reflect(rd,normal)));
    
    color *= vec3(ambient2 + diffuse2 + pow(specular2,5.0));

    color *= smoothstep(12.0,6.0,length(pos));
    
    
   
    return (final+color)/2.0;
}

vec3 srgb(float r, float g, float b) {
    return vec3(r*r,g*g,b*b);
}

//https://www.shadertoy.com/view/4llSWf

vec3 Shade(vec3 position, vec3 normal, vec3 direction, vec3 camera)
{
   // position *= scale;
    vec3 color = vec3(1.0);
    
    color = color * 0.75 + 0.25;
    
    color *= normal * .25 + .75;
    
    
    float ambient = 0.1;
    float diffuse = 0.5 * -dot(normal,direction);
    float specular = 1.0 * max(0.0, -dot(direction, reflect(direction,normal)));
    
    color *= vec3(ambient + diffuse + pow(specular,5.0));

    color *= smoothstep(12.0,6.0,length(position));
    
    return color;
}

///---------------------------------------------
void main(void)
{
   vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float t;
    t=time*5.0;
   
    
 
 light_pos1   = vec3(-20.0, 12.0, -15.0 ); 
 light_color1 = vec3( 1.0 );

 light_pos2   = vec3( 0.0, 15.0, 0.0 );
 light_color2 = vec3( 1.0, 1.0, 1.0 );
 //light_color2 = vec3( 0.65, 0.5, 1.0 );

   
    
    vec3 ro = vec3(0.0,9.0,-12.0+8.0*cos(time*2.0));
    
     
    ro = get_mouse(ro);
    vec3 rd = normalize( vec3(uv,1.0));
  
    
    
    vec3 col = vec3(0);
    
    TObj Obj;
    
    mObj.uv=uv;
    mObj.rd=rd;
    mObj.ro=ro;

     
    
    float d = RayMarch(ro, rd);
    Obj=mObj;
    
  
    vec3 p = (ro + rd * d ); 
    glpRoRd=p;
    mObj.p=p;
    
    float dif=0.8;
  
    
    mObj.dist =d;
    vec3 colobj;
    
    vec3 nor= GetNormal( p);
    
  
    
    
    colobj=getSphereColor(int( Obj.tipo));
    if (Obj.tipo!=16.0 && Obj.tipo!=1.0)
    colobj=colobj*getSphereColor(139);
    
    
  float dif1=1.0;
   
    
    /*
     float dif1= GetLightPar(p,light_pos1);
    dif1+= GetLightPar(p,light_pos2);
     dif1= (dif1 )/2.0;
    */
    
    
    vec3 col2;

   col2= p_shadingv3( p, nor, ro,rd, light_pos1, light_color1 )*colobj;
   col2+= p_shadingv3( p, nor, ro,rd, light_pos2, light_color2 )*colobj;
 
  
    col=(col2)*dif1;
  
    col = pow(col, vec3(1.0/2.2));  
    
    glFragColor = vec4(col,1.0);

}
