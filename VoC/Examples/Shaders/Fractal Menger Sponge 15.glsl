#version 420

// original https://www.shadertoy.com/view/tdXyD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//por jorge2017a1---9-mar-2020

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001
#define PI 3.14159265358979323846264

#define PI2 6.28318530717
#define TriplePI (3.0 * PI)
#define DoublePI (2.0 * PI)
#define HalfPI (PI / 2.0)

#define EPSILON 0.02
#define WHITE 0.
#define BLACK 1.
#define FLOOR 2.

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
};
    

    
TObj mObj;
vec3 glpRoRd;
vec2 gres2;

//Torus function
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
//Sphere function
float sdSphere( vec3 p, float s1 )
{
   vec4 s = vec4(0, s1, 9, s1);
   return  length(p-s.xyz)-s.w;   
}
//Box function
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}
//Triprism function
float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}
//Cone function
float sdCone( vec3 p, vec2 c )
{
    // c must be normalized
    float q = length(p.xy);
    return dot(c,vec2(q,p.z));
}

float sdCylinder( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

///--------------------------------------------

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

vec3 rotate_y(vec3 v, float angle)
{
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        +ca, +.0, -sa,
        +.0,+1.0, +.0,
        +sa, +.0, +ca);
}

vec3 rotate_x(vec3 v, float angle)
{
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        +1.0, +.0, +.0,
        +.0, +ca, -sa,
        +.0, +sa, +ca);
}

vec3 rotate_z(vec3 v, float angle)
{
    float ca = cos(angle); 
    float sa = sin(angle);
    return v*mat3(
        +ca, -sa, +.0,
        +sa, +ca, +.0,
        +.0, +.0, +1.0);
}

///---------------------------------------------

//IQs noise
float noise(vec3 rp) {
    vec3 ip = floor(rp);
    rp -= ip; 
    vec3 s = vec3(7, 157, 113);
    vec4 h = vec4(0.0, s.yz, s.y + s.z) + dot(ip, s);
    rp = rp * rp * (3.0 - 2.0 * rp); 
    h = mix(fract(sin(h) * 43758.5), fract(sin(h + s.x) * 43758.5), rp.x);
    h.xy = mix(h.xz, h.yw, rp.y);
    return mix(h.x, h.y, rp.z); 
}
///----------------------
float floorTex(vec3 rp) {
    rp.x += time * -2.0;
    vec2 m = mod(rp.xz, 4.0) - 2.0;
    if (m.x * m.y > 0.0) {
        return 0.8 + noise(rp * 4.0) * 0.16;
    }
    return 0.2 + noise((rp + 0.3) * 3.0) * 0.1;
}
///-----------------------------------------
float random() 
{
    return fract(sin(dot(mObj.uv, vec2(12.9898, 78.233)) ) * 43758.5453);
}

// We use it for ray scattering.
vec3 randomUnitVector() 
{
    float theta = random() * PI2;
    float z = random() * 2.0 - 1.0;
    float a = sqrt(1.0 - z * z);
    vec3 vector = vec3(a * cos(theta), a * sin(theta), z);
    return vector * sqrt(random());
}
///-----------------------------------------

vec3 LightShading(vec3 N,vec3 L,vec3 V,vec3 color)
{
    vec3 diffuse = max(0.,dot(N,-L))*color;
    vec3 specular = pow(max(0.,dot(N,normalize(-L-V))),100.)*vec3(1.,1.,1.); 
    return diffuse + specular;
}

    
    
//-------------------------------------------------

// Create infinite copies of an object -  http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
vec2 opRep( in vec2 p, in float s )
{
    return mod(p+s*0.5,s)-s*0.5;
}

vec3 tex(vec2 uv)
{
    return vec3(fract(sin(dot(floor(uv*32.0),vec2(5.364,6.357)))*357.536));
}

//------------------------------------------

float maxcomp(vec2 p) {
  return max(p.x, p.y);
}

float sdCross(vec3 p) {
  float da = maxcomp(abs(p.xy));
  float db = maxcomp(abs(p.yz));
  float dc = maxcomp(abs(p.xz));
  return min(da, min(db, dc)) - 1.0;
}

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

//0000000000000000000000000000000000000000000000000000000

float hash( in vec2 p ) 
{
    return fract(sin(p.x*15.32+p.y*35.78) * 43758.23);
}

vec2 hash2(vec2 p)
{
    return vec2(hash(p*.754),hash(1.5743*p.yx+4.5891))-.5;
}

vec2 noise2(vec2 x)
{
    vec2 add = vec2(1.0, 0.0);
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix( hash2(p),          hash2(p + add.xy),f.x),
                    mix( hash2(p + add.yx), hash2(p + add.xx),f.x),f.y);
    
}

//-------------------------------------

vec3 vectorField(in vec3 p) {
    return vec3(-p.y * sin(time / 3.0), 
                -p.z * sin(time / 5.0), 
                 p.x * cos(time / 7.0));
}

#define EULER_ITERS 2
#define LAMBDA 0.05
vec3 euler(in vec3 p){
    float lambda = mix(0.0, 8.0 * LAMBDA, 0.5 + 0.5 * sin(time / 11.0));
    for (int i = 0; i < EULER_ITERS; i++) {
        p = p + lambda * vectorField(p);
    }
    return p;
}

//referencia
//https://www.shadertoy.com/view/MddGRj
#define MENGER_ITERS 5
float mengerSponge(in vec3 p) 
{
    
    float d = sdBox(p, vec3(1.0));
    float scale = 1.0;
    
    for (int i = 0; i < MENGER_ITERS; i++) {
        vec3 a = mod(p * scale, 2.0) - 1.0;
        scale *= 3.0;
        vec3 r = abs(1.0 - 3.0 * abs(a));
       // r = euler(r);
        
        float da = max(r.x, r.y);
        float db = max(r.y, r.z);
        float dc = max(r.z, r.x);
        
        float c = (min(da, min(db, dc)) - 1.0) / scale;
        d = max(d, c);
    }
    
    return d;
}

//------------------------------------------
vec2 GetDist(vec3 p  ) 
{    
    
      float d;
    float dif1;
    float dif2;
    
    d=999.9;
    float planeDist = p.y;
    
   vec3 pp;
    pp=p;
    vec2 res;
    res = vec2(9999, 0);
    
    
    p.z = mod( p.z,1.0)-0.5;
    float mg1= mengerSponge(p);
    
    res=opU(res, vec2(mg1,20 ));
    
    
    d = res.x;
    mObj.dist = res.x;
    mObj.tipo = res.y;
   
    return res;
}

vec2 RayMarch(vec3 ro, vec3 rd)
{
    float t_near=0.0;
    //Determines size of shadow
    
    for(int i=0; i<MAX_STEPS; i++) 
    {
        vec3 p = ro + rd*t_near;
        
        vec2 dist = GetDist(p);
        
        t_near += dist.x;
        if(t_near>MAX_DIST ) 
        {
            
            
            return vec2(-1., -1);
            
        }else if(dist.x < SURF_DIST){
            
            return vec2(t_near, dist.y); 
        }    
        
    }
    
    
     return vec2(-1., -1);
}

vec3 GetNormal(vec3 p) {
    vec2 d = GetDist(p);
    float dist;
    //Texture of white and black in image
    vec2 e = vec2(.001, 0);
    
    dist=d.x;
    
    vec3 n;
    n = dist -vec3(
        GetDist(p-e.xyy).x,
        GetDist(p-e.yxy).x,
        GetDist(p-e.yyx).x);
    
    return normalize(n);
}

float GetLightPar(vec3 p, vec3 plig) {
    vec3 lightPos = plig;
    //Determine movement of light ex. shadow and light direction and diffusion
    //lightPos.xz += vec2(1, 2);
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    vec2 d = RayMarch(p+n*SURF_DIST*2., l );
    if(d.x<length(lightPos-p)) dif *= .1;
    
    return dif;
}

#define offset1 4.7
#define offset2 4.6
//----------------------------------------------------

// Single rotation function - return matrix
mat2 r2(float a){ 
  float c = cos(a); float s = sin(a); 
  return mat2(c, s, -s, c); 
}
//--------------------

// mouse*resolution.xy pos function - take in a vec3 like ro
// simple pan and tilt and return that vec3
vec3 get_mouse(vec3 ro) {
    float x = -.2;
    float y = .0;
    float z = 0.0;

    ro.zy *= r2(x);
    ro.zx *= r2(y);
    
    return ro;
}

//----------------------------------------------------

//--------------------------------------------------------

vec3 course(float a)
{
    return vec3(
        cos(a),
        sin(2.0*a),
        0.15*sin(a)
    );
}

//--------------------------------------------------------

vec3 getSphereColor(int i)
{
    
    float m;
        
    if(i==0 )
    {
    
        
        return vec3(0.0);
    }
    
    if(i== 1 )
    {
        
        return vec3(1, 0.5, 0);
        } 
    if(i== 2 )
    {
        return vec3(1.0, 1.0, 1.0);
        } 
    if(i== 3 )
    {
        return vec3(247./255., 168./255.,  184./255.); 
       } 
    if(i== 4 )
    {
        
        return vec3(0, 1, 1);
        } 
    if(i== 5 )
    {
        return vec3(85./255., 205./255., 252./255.);
        } 
    if(i== 6 )
    {
        
        return  vec3(0.5, 0.8, 0.9);
        } 
        
    if(i== 7 )
    {
        return vec3(1.0, 1.0, 1.0);
       } 
    if(i== 8 )
    {
       
        
        return vec3(0.425, 0.56, 0.9); 
       } 
    if(i== 9 )
    {
        
        return vec3(0.5, 0.6, 0.6); 
     } 
    if(i== 10 )
    {
        return vec3(0.0, 1.0, 0.0);
    } 
    
    if(i== 11 )
    {
        return vec3(0.25, 0.25, 0.25);
    } 
    
    if(i== 12 )
    {
        vec3 tmp;
        tmp =glpRoRd;
        
        tmp=rotate_x(tmp,90.0);
        
        return  vec3(0.8, 1.0, 0.4) * floorTex(tmp); 
        } 
     if(i== 13 )
    {
        float d = 0.0;
            // checkerboard function that returns 0 or 1
            d = mod(floor(glpRoRd.x)+floor(glpRoRd.z),2.0);
            // vary between red (0) and yellow (1)
        return vec3(0.8 + 0.1*d, 0.3 + 0.55*d, 0.15 - 0.1*d)*0.8;
        } 
     if(i== 14 )
    {
            // checkerboard hack
            vec2 cb = floor(glpRoRd.xz);
            float cb2 = mod(cb.x + cb.y, 2.0);
            return vec3(0.4 + 0.1*cb2, 0.3 + 0.85*cb2, 0.35 - 0.3*cb2)*0.8;
        } 
     if(i== 15 )
    {
            return vec3(1.0,0.0,1.);
       } 
     if(i== 16 )
    {
            return vec3(1.0,1.0,0.0);
     } 
     if(i== 17 )
    {
        /*
            float tmps;
            tmps=fbm(gres2);
            return  vec3(tmps );
         */
        } 
     if(i== 18 )
    {
            return vec3(1.0,0.0,0.0);} 
     if(i== 19 )
    {      
         return vec3(0.0,1.0,0.0);
    } 
     
    
    if(i== 20 )
    {
     
        vec3 p = glpRoRd;
           vec3 marbleP = p;

            marbleP.x += sin(p.y*20.0)*0.12;
            marbleP.z += sin(p.y*22.0)*0.1;
            marbleP.y += sin(p.x*25.0)*0.13;
            marbleP.y += sin(p.z*23.0)*0.14;

            marbleP.y += sin(p.x*1.3)*0.5;
            marbleP.y += sin(p.z*1.5)*0.6;

            marbleP.x += sin(p.y*150.0)*0.011;
            marbleP.z += sin(p.y*162.0)*0.013;
            marbleP.y += sin(p.x*145.0)*0.012;
            marbleP.y += sin(p.z*153.0)*0.015;

            marbleP.x *= 20.0;
            marbleP.z *= 20.0;
            marbleP.y *= 10.0;

            float marbleAmtA = abs(sin(marbleP.x)+sin(marbleP.y)+sin(marbleP.z))/3.0;
            marbleAmtA = pow(1.0-marbleAmtA,5.0);
            
         vec3 surfaceColor;
            surfaceColor = mix(vec3(0.1,0.8,0.5),vec3(0.50,0.1,0.2),marbleAmtA);
        
            return surfaceColor;
     } 
    
    
    
    if(i== 21 )
    {
     
        vec3 p = glpRoRd;
           vec3 marbleP = p;
    
            

            marbleP.x += sin(p.y*20.0)*0.12;
            marbleP.z += sin(p.y*22.0)*0.1;
            marbleP.y += sin(p.x*25.0)*0.13;
            marbleP.y += sin(p.z*23.0)*0.14;

            marbleP.y += sin(p.x*1.3)*0.5;
            marbleP.y += sin(p.z*1.5)*0.6;

            marbleP.x += sin(p.y*150.0)*0.011;
            marbleP.z += sin(p.y*162.0)*0.013;
            marbleP.y += sin(p.x*145.0)*0.012;
            marbleP.y += sin(p.z*153.0)*0.015;

            marbleP.x *= 20.0;
            marbleP.z *= 20.0;
            marbleP.y *= 10.0;

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

            marbleP.x *= 22.0;
            marbleP.z *= 23.0;
            marbleP.y *= 11.0;

            float marbleAmtB = abs(sin(marbleP.x)+sin(marbleP.y)+sin(marbleP.z))/3.0;
            marbleAmtB = pow(1.0-marbleAmtB,9.0);
            marbleAmtB = 1.0-(1.0-marbleAmtB*0.3);

            float marbleAmt = marbleAmtA + marbleAmtB;
            marbleAmt = clamp(marbleAmt,0.0,1.0);
            vec3 surfaceColor;
            
        
            surfaceColor = mix(vec3(0.4,0.4,0.6),vec3(0.50,0.1,0.2),marbleAmtA);
        
            return surfaceColor;    
        
            }  
    
    
    if(i== 22 )
    {
        /*
       return triangleBaryCentre(glpRoRd.xy);    
*/
    } 
    
    
     if(i== 23)
    {
    
        
        return  vec3(0.425, 0.16, 0.6);    
            
    } 
    
    
    
    if(i== 24 )
    {
     
        vec3 p = glpRoRd;
           vec3 marbleP = p;
    
            

            marbleP.x += sin(p.y*20.0)*0.12;
            marbleP.z += sin(p.y*22.0)*0.1;
            marbleP.y += sin(p.x*25.0)*0.13;
            marbleP.y += sin(p.z*23.0)*0.14;

            marbleP.y += sin(p.x*1.3)*0.5;
            marbleP.y += sin(p.z*1.5)*0.6;

            marbleP.x += sin(p.y*150.0)*1.11;
            marbleP.z += sin(p.y*162.0)*1.13;
            marbleP.y += sin(p.x*145.0)*2.12;
            marbleP.y += sin(p.z*153.0)*2.15;

            marbleP.x *= 30.0;
            marbleP.z *= 20.0;
            marbleP.y *= 10.0;

            float marbleAmtA = abs(sin(marbleP.x)+sin(marbleP.y)+sin(marbleP.z))/4.0;
            marbleAmtA = pow(1.0-marbleAmtA,5.0);

            marbleP = p;

            marbleP.x += sin(p.y*21.0)*2.12;
            marbleP.z += sin(p.y*23.0)*2.1;
            marbleP.y += sin(p.x*22.0)*0.13;
            marbleP.y += sin(p.z*24.0)*0.14;

            marbleP.y += sin(p.x*1.2)*0.5;
            marbleP.y += sin(p.z*1.4)*0.6;

            marbleP.x += sin(p.y*150.0)*0.11;
            marbleP.z += sin(p.y*162.0)*0.13;
            marbleP.y += sin(p.x*145.0)*0.12;
            marbleP.y += sin(p.z*153.0)*0.15;

            marbleP.x *= 22.0;
            marbleP.z *= 23.0;
            marbleP.y *= 11.0;

            float marbleAmtB = abs(sin(marbleP.x)+sin(marbleP.y)+sin(marbleP.z))/2.0;
            marbleAmtB = pow(1.0-marbleAmtB,9.0);
            marbleAmtB = 1.0-(1.0-marbleAmtB*0.8);

            float marbleAmt = marbleAmtA + marbleAmtB;
            marbleAmt = clamp(marbleAmt,0.0,1.0);
            vec3 surfaceColor;
            
        
            surfaceColor = mix(vec3(0.1,0.3,0.7),vec3(0.50,0.1,0.2),marbleAmtA);
        
            return surfaceColor;    
        
            }  

    
    if(i== 25 )
    {
        /*
        float c = thunderbolt(mObj.uv+.02);
        c=exp(-5.*c);
        vec3 col;
        col=clamp(1.7*vec3(0.8,.7,.9)*c,0.,1.);
        return col;
*/
    }      
    
    
  
    if(i== 27 )
    {
        
        float i0 = 1.0;
          float i1 = 1.0;
          float i2 = 1.0;
          float i4 = 0.0;
        
      for (int s = 0; s < 8; s++) {
    vec2 r;
    r = vec2(cos(mObj.uv.y * i0 - i4 + time / i1), sin(mObj.uv.x * i0 - i4 + time / i1)) / i2;
    r += vec2(-r.y, r.x) * 0.3;
    mObj.uv.xy += r;

    i0 *= 1.93;
    i1 *= 1.15;
    i2 *= 1.7;
    i4 += 0.05 + 0.1 * time * i1;
      }
        
        float r = sin(mObj.uv.x - time+2.0) * 0.25 + 0.5;
          float b = sin(mObj.uv.y + time*2.0+2.0) * 0.5 + 0.5;
          float g = sin((mObj.uv.x + mObj.uv.y + sin(1.0 * 0.5)) * 0.5) * 0.5 + 0.5;
        vec3 col= vec3(r,g,b);
        return col;
    }      
    
    
  
        
}

void main(void)
{
   vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    
    vec3 ro = vec3(0.0 ,0.0+2.5*cos(time)*0.05 ,1.0+time*0.25);
    vec3 rd =normalize(vec3(uv,1.0) );

    
    vec3 col = vec3(0);
    
    TObj Obj;
    
    mObj.uv=uv;
    mObj.rd=rd;
    mObj.ro=ro;

    vec3 rLuz=vec3(0.5, 3.5, 4.5);
    vec3 rl2=vec3(0.5, 20.5, 20.5);
    
    vec2 d = RayMarch(ro, rd);
    Obj=mObj;
    
    
    if(d.x == -1.){
        col = getSphereColor(int( d.y)) * (1. - (uv.y));
    }
    else
    {
      
  
    vec3 p = (ro + rd * d.x ); 
    glpRoRd=p;
    
 
    float dif=0.35;
   
    
    mObj.dist =d.x;
    vec3 colobj;
  
    colobj=getSphereColor(int( d.y));
    
    vec3 nor= GetNormal( p);
   
    float intensity = 1.0;
     vec3 V = normalize(p - ro);
     vec3 L = rd;
     vec3 normal = nor;
     vec3 refl = 2.*dot(normal,-rd)*normal + rd;
     vec3 result = LightShading(normal,L,V, colobj)*intensity;
      col= result*dif*2.1;
      col = pow(col, vec3(1.0/2.2));  
     
    }   
        
    glFragColor = vec4(col,1.0);

}
