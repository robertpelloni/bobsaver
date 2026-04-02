#version 420

// original https://www.shadertoy.com/view/3lyXRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001
#define PI 3.14159265358979323846264

#define PI2 6.28318530717
#define TriplePI (3.0 * PI)
#define DoublePI (2.0 * PI)
#define HalfPI (PI / 2.0)

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

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdRoundCone( vec3 p, float r1, float r2, float h )
{
  vec2 q = vec2( length(p.xz), p.y );
    
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  float k = dot(q,vec2(-b,a));
    
  if( k < 0.0 ) return length(q) - r1;
  if( k > a*h ) return length(q-vec2(0.0,h)) - r2;
        
  return dot(q, vec2(a,b) ) - r1;
}

float dsCapsule(vec3 point_a, vec3 point_b, float r, vec3 point_p)//cylinder SDF
{
     vec3 ap = point_p - point_a;
    vec3 ab = point_b - point_a;
    float ratio = dot(ap, ab) / dot(ab , ab);
    ratio = clamp(ratio, 0.0, 1.0);
    vec3 point_c = point_a + ratio * ab;
    return length(point_c - point_p) - r;
}

float sdHex(vec2 p, float h) 
{
    vec3 k = vec3(-0.8660254, 0.57735, 0.5);
    p = abs(p);
    p -= 2.0 * min(dot(k.xz, p), 0.0) * k.xz;
    return length(p - vec2(clamp(p.x, -k.y * h, k.y * h), h)) * sign(p.y - h);
}

//---------------------------------------------------
float fbm(vec2 Oldp)
{
    float _scale = 0.58;
    vec2 p;
    p = Oldp * vec2(_scale);
    float _value = -0.7;//sin(time*0.5);
    float _frequency = 8.58;
    float _amplitude = 2.18;
    float _power = 0.3;
    vec2 i = floor(p * _frequency);
    vec2 f = fract(p * _frequency);
    vec2 t = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    
    vec2 a = i + vec2(0.0, 0.0);
    vec2 b = i + vec2(1.0, 0.0);
    vec2 c = i + vec2(0.0, 1.0);
    vec2 d = i + vec2(1.0, 1.0);
    
    a = -1.0 + 2.0 * fract(sin(vec2(dot(a, vec2(127.1, 311.7)), dot(a, vec2(269.5, 183.3)))) * 43758.5453123);
    b = -1.0 + 2.0 * fract(sin(vec2(dot(b, vec2(127.1, 311.7)), dot(b, vec2(269.5, 183.3)))) * 43758.5453123);
    c = -1.0 + 2.0 * fract(sin(vec2(dot(c, vec2(127.1, 311.7)), dot(c, vec2(269.5, 183.3)))) * 43758.5453123);
    d = -1.0 + 2.0 * fract(sin(vec2(dot(d, vec2(127.1, 311.7)), dot(d, vec2(269.5, 183.3)))) * 43758.5453123);
    
    float A = dot(a, f - vec2(0.0, 0.0));
    float B = dot(b, f - vec2(1.0, 0.0));
    float C = dot(c, f - vec2(0.0, 1.0));
    float D = dot(d, f - vec2(1.0, 1.0));
    
    float noise = (mix(mix(A, B, t.x), mix(C, D, t.x), t.y));
    _value += _amplitude * noise;
    _value = clamp(_value, -1.0, 1.0);
    return pow(_value * 0.5 + 0.5, _power);
}

//---------------------------------------------------
///por Iq
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

float map(vec3 p) {
  p.zx *= rotate(time*0.5);
  p.yx *= rotate(time * 0.5);

  float d;
    float sdt= sdTorus( p, vec2(1.5,1)  );
    d= sdt;
    
    
  float s = 1.0;
  for (int m = 0; m < 2; m++) {
    vec3 a = mod(p * s, 2.0) - 1.0;
    s *= 3.0;
    vec3 r = 1.0 - 3.0 * abs(a);
    float c = sdCross(r) / s;
    d = max(d, c);
  }

  return d;
                               
}

//------------------------------------------------

/*
//scene distance functions
float walls(vec3 p) {
    vec3 ap = abs(p);
    return WALLS_SIZE-max(ap.x,max(ap.y,ap.z));
}
*/

//scene distance functions
float walls(vec3 p) {
    vec3 ap = abs(p);
    return 20.0-max(ap.x,max(ap.y,ap.z));
}

float wallx(vec3 p)
 {
    vec3 ap = abs(p);
    return 15.0-max(ap.x,0.0);
}

float wally(vec3 p)
{
    vec3 ap = abs(p);
    return 15.0-max(ap.y,0.0);
}

float wallz(vec3 p)
{
    vec3 ap = abs(p);
    return 30.0-max(ap.z,0.0);
}

//----------------------------------------------
float GetDist(vec3 p  ) {    

     
    
    float d;
    float dif1;
    float dif2;
    
    d=999.9;
    float planeDist = p.y;
    
   vec3 pp;
    pp=p;
    
 
    
    vec2 res;
    res = vec2(9999, 0);
    
   

    
   /* 
   float sdw= walls(p);
   res=opU(res, vec2(sdw,8));
   */    
    
    
   float sdwx= wallx(p);
   float sdwy= wally(p);
   float sdwz= wallz(p);
   res=opU(res, vec2(sdwx,8));
   res=opU(res, vec2(sdwy,13));
   res=opU(res, vec2(sdwz,18));
    

   float sdf1=map(p-vec3(0.0,5.0,0.));
       
   res=opU(res, vec2(sdf1,11 ));
    
    
    d = res.x;
    mObj.dist = res.x;
    mObj.tipo = res.y;
        
    return d;
}

float RayMarch(vec3 ro, vec3 rd)
{
    float dO=0.2;
    //Determines size of shadow
    
    for(int i=0; i<MAX_STEPS; i++) 
    {
        vec3 p = ro + rd*dO;
        
        float dS = GetDist(p);
        
        dO += dS;
        if(dO>MAX_DIST || dS<SURF_DIST) 
        {
            //mObj.dist=dO;     
            gres2 = vec2(dO,dS); 
            break;
        }    
        
    }
    
    return dO;
}

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

float GetLight(vec3 p) {
    vec3 lightPos = vec3(0, 5, 6);
    //Determine movement of light ex. shadow and light direction and diffusion
    lightPos.xz += vec2(sin(time), cos(time)*2.);
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    
    float dif = clamp(dot(n, l), 0., 1.0);
    float d = RayMarch(p+n*SURF_DIST*2.0, l );
    if(d<length(lightPos-p)) dif *= .1;
    
    return dif;
}

float GetLightv2(vec3 p) {
    vec3 lightPos = vec3(0, 5, 6);
    //Determine movement of light ex. shadow and light direction and diffusion
    lightPos.xz += vec2(1, 2);
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

vec3 calcLuz(vec3 p, vec3 origin, vec3 l, vec3 n )
{
    
    vec3 idiffuse=vec3(0.8);
    vec3 ispecular=vec3(0.7);
    vec3 lightcolor=vec3(0.7,0.8,0.5);
    
    vec3 v = normalize(origin-p);
    vec3 h = normalize(l+v);
    float NdotL = saturate(dot(n,l));
    float NdotH = saturate(dot(n,h));
    vec3 diffuse = NdotL*idiffuse;
    vec3 spec = 0.18 * pow(NdotH,40.0) * ispecular;
    vec3 color;
    
    color = (diffuse+spec) * lightcolor;
    return  color;
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
    float x = mouse*resolution.xy.xy==vec2(0) ? -.2 :
        (mouse.y*resolution.xy.y / resolution.y * .5 - 0.25) * PI;
    float y = mouse*resolution.xy.xy==vec2(0) ? .0 :
        -(mouse.x*resolution.xy.x / resolution.x * 1.0 - .5) * PI;
    float z = 0.0;

    ro.zy *= r2(x);
    ro.zx *= r2(y);
    
    return ro;
}

//----------------------------------------------------

vec3 getSphereColor(int i)
{
    
    float m;
        
    if(i==0 )
    {
    
        return vec3(85./255., 205./255., 252./255.);
    }
    
    if(i== 1 )
    {
        //return vec3(247./255., 168./255.,  184./255.);
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
        //return vec3(85./255., 205./255., 252./255.);
        return vec3(0, 1, 1);
        } 
    if(i== 5 )
    {
        return vec3(85./255., 205./255., 252./255.);
        } 
    if(i== 6 )
    {
        //return vec3(247./255., 168./255.,  184./255.);
        return  vec3(0.5, 0.8, 0.9);
        } 
        
    if(i== 7 )
    {
        return vec3(1.0, 1.0, 1.0);
       } 
    if(i== 8 )
    {
       
        //return vec3(247./255., 168./255.,  184./255.); 
        //return vec3(55./255., 30./255.,  255./255.); 
        return vec3(0.425, 0.56, 0.9); 
       } 
    if(i== 9 )
    {
        //return vec3(85./255., 205./255., 252./255.); 
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
            float tmps;
            tmps=fbm(gres2);
            return  vec3(tmps );
        } 
     if(i== 18 )
    {
            return vec3(1.0,0.0,0.0);} 
     if(i== 19 )
    {      
         return vec3(0.0,1.0,0.0);
    } 
        
     
}

void main(void)
{
   vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    
   
     vec2 pp = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    float an = 10.*mouse.x*resolution.xy.x/resolution.x;
    float yt = time *0.2; // 5.*mouse*resolution.xy.y/resolution.y;
    float zoom = 2.15;
    
    vec3 ta = vec3(5.,1.95,-10.);
    //vec3 ro = vec3(5.+ time,15.5,20.+cos(time));
    vec3 ro = vec3(-2. ,5.5,6.0);
    
    ro = get_mouse(ro);
    
    vec3 ww = normalize( ta - ro); 
    vec3 uu = normalize( cross(ww,vec3(0.,1.,0.)));
    vec3 vv = normalize( cross(uu,ww));
    
    vec3 rd = normalize( pp.x*uu + pp.y*vv + 1.8*ww );
    
    float stime = time * 0.3;

 
    
    vec3 col = vec3(0);
    
    TObj Obj;
    
    mObj.uv=uv;
    mObj.rd=rd;
    mObj.ro=ro;
    
 

    

    float d = RayMarch(ro, rd);
    //mObj.dist =d;
    Obj=mObj;
    
  
    vec3 p = (ro + rd * d ); 
    glpRoRd=p;
    
    float dif = GetLight(p);
    mObj.dist =d;
    vec3 colobj;
    colobj=getSphereColor(int( Obj.tipo));
 

    col =  ( vec3(dif)+colobj)/1.5;
    glFragColor = vec4(col,1.0);

}
