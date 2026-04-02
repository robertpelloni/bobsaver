#version 420

// original https://www.shadertoy.com/view/XsjfDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SHOW_POINTS 1
#define SHOW_SEGMENTS 1
#define SHOW_DUAL_POINTS 1
#define SHOW_DUAL 1

#define PI 3.14159265359
        
vec2 polar( float k , float t )
{
  return k*vec2(cos(t),sin(t));
}

vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
vec2 cexp( vec2 z ) { return polar(exp(z.x) , z.y ); }
vec2 clog( vec2 z ) { return vec2( log(length(z)) , atan(z.y , z.x) ); }
vec2 cdiv( vec2 a, vec2 b )  { float d = dot(b,b); return vec2( dot(a,b), a.y*b.x - a.x*b.y ) / d; }

// segment.x is distance to closest point
// segment.y is barycentric coefficient for closest point
// segment.z is length of closest point on curve, on the curve, starting from A
// segment.a is approximate length of curve
vec4 segment( vec2 p, vec2 a, vec2 b )
{
  a -= p;
  b -= p;
  vec3 k = vec3( dot(a,a) , dot(b,b) , dot(a,b) );
  float t = (k.x - k.z)/( k.x + k.y - 2.*k.z );
  float len = length(b-a);
    
  if( t < 0. ){
      return vec4( sqrt(k.x) , 0. , 0. , len );
  } else if( t > 1. ){
      return vec4( sqrt(k.y) , 1. , len , len );
  } else {
      return vec4( length(a*(1.-t) + b*t) , t , t*len , len );
  }
}

// https://www.shadertoy.com/view/4djSRW
#define ITERATIONS 4

// *** Change these to suit your range of random numbers..

// *** Use this for integer stepped ranges, ie Value-Noise/Perlin noise functions.
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(1031, .1030, .0973, .1099)
//----------------------------------------------------------------------------------------
///  3 out, 2 in...
vec3 hash32(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

vec3 hash3point(vec2 p)
{
    //vec3 col = hash32(p);
    vec3 col = 
            hash32(p*1.25672+vec2(.2,.8))
          * hash32(vec2(p.y,p.x)/3.42464-vec2(.5,.0))
          - hash32(vec2(3.0+p.y,1.2))
    ;
    
    return pow(
        (abs(col)+max(col,0.0))/2.0
        , vec3(.6,.5,.4)
    );
}

float smoothFunction(float k)
{
    return 1.0 / ( 1.0 + k*k );
}

vec3 smoothFunction(vec3 k)
{
    return 1.0 / ( 1.0 + k*k );
}

float coeffDistPoint(vec2 uv,vec2 colPoint,float scale)
{    
    //float dist = length(uv - colPoint) * scale;
    //dist = pow(dist,0.25);
    //dist = 1.0 - smoothstep(0.0,1.0,dist);
    
    vec2 uv_ = (uv - colPoint)*scale*24.0;
    float dist = dot(uv_,uv_);
    return  1.0 / ( 1.0 + dist );
}

void mixColorPoint(vec2 uv,inout vec3 col,vec2 colPoint,float scale)
{
    col = mix(
        col , 
        hash3point(colPoint) ,
        coeffDistPoint(uv,colPoint,scale)
    );
}

vec3 mixColorLine(vec2 uv,vec3 currentCol,vec3 colLine,vec2 lineA,vec2 lineB,float scale)
{
    return mix(
        currentCol , 
        colLine ,
        1.0 - smoothstep(0.0,1.0,sqrt(sqrt( segment(uv,lineA,lineB).x * scale )))
    );
}

bool pointsOnSameSideOfLine(vec2 pointA,vec2 pointB,vec2 lineA, vec2 lineB)
{
    vec2 n = lineB - lineA;
    n = vec2(n.y,-n.x);
    return  dot(pointA-lineA,n)
          * dot(pointB-lineA,n)
    > 0.0;
}

float viewportMagnify = 1.0;
vec2 screenToViewport(vec2 uv)
{
    return (uv - resolution.xy/2.0 ) / min(resolution.x,resolution.y) * viewportMagnify;
}

vec2 viewportToScreen(vec2 uv,vec2 base)
{
    return (uv - base/4.0) / viewportMagnify * min(resolution.x,resolution.y) +  resolution.xy/2.0;
    //return (uv - resolution.xy/2.0 ) / min(resolution.x,resolution.y) * viewportMagnify;
}

// there is three kind of points
// in kisrhombille
// named here A,B,C
struct Equerre
{
    vec2 A; // Right angle  => 4 connections
    vec2 B; // Acute angle  => 12 connections
    vec2 C; // Obtuse angle => 6 connections
    
    vec2 D; // on AB
    vec2 E; // on BC
    
    float r;
    float ID;
};
    
// when decomposing an A,B,C triangle into thre subtriangles
// A & B stays respectively A & B points
// C becomes a B point
// D created is a C point
// E created is an A point
    
float det22(vec2 a,vec2 b)
{
    return a.x*b.y - a.y*b.x;
}

vec3 barycentricCoordinate(vec2 P,Equerre T)
{
    vec2 PA = P - T.A;
    vec2 PB = P - T.B;
    vec2 PC = P - T.C;
    
    vec3 r = vec3(
        det22(PB,PC),
        det22(PC,PA),
        det22(PA,PB)
    );
    
    return r / (r.x + r.y + r.z);
}
    
#define EQUERRE_COPY(T,Q) \
    T.A = Q.A; \
    T.B = Q.B; \
    T.C = Q.C;
    
#define EQUERRE_COMPUTE_DE(T) \
    T.D = (2.0 * T.A + T.B)/3.0; \
    T.E = (T.B + T.C)/2.0;
    
#define EQUERRE_GET1(T,Q) \
    T.A = Q.A; \
    T.B = Q.C; \
    T.C = Q.D;

#define EQUERRE_GET2(T,Q) \
    T.A = Q.E; \
    T.B = Q.B; \
    T.C = Q.D;

#define EQUERRE_GET3(T,Q) \
    T.A = Q.E; \
    T.B = Q.C; \
    T.C = Q.D;

#define EQUERRE_GET_NEIGHBOUR_AB(T,Q) \
    T.A = Q.A; \
    T.B = Q.B; \
    T.C = 2.0 * Q.A - Q.C;

#define EQUERRE_GET_NEIGHBOUR_AC(T,Q) \
    T.A = Q.A; \
    T.B = 2.0 * Q.A - Q.B; \
    T.C = Q.C;

#define EQUERRE_GET_NEIGHBOUR_BC(T,Q) \
    T.A = (3.0 * Q.C + Q.B)/2.0 - Q.A; \
    T.B = Q.B; \
    T.C = Q.C;

#define EQUERRE_COND1(X,T) \
    pointsOnSameSideOfLine(uv,T.A,T.D,T.C)
 
#define EQUERRE_COND2(X,T) \
    pointsOnSameSideOfLine(uv,T.B,T.D,T.E)

#define EQUERRE_CENTER(T) ((T.A+T.B+T.C)/3.0)
        
#define _AB_ (1)
#define _BC_ (2)
#define _CA_ (3)
        
#define _ALPHA_ _AB_
#define _BETA_  _BC_
#define _GAMMA_ _CA_
        
#define _REPLACE_(X,Y,Z,T) \
        if( Begin == X && End == Y && !operation ) { \
            Begin = Z; End = T; operation = true; \
        } else if( End == X && Begin == Y && !operation) { \
            End = Z; Begin = T; operation = true; \
        }

#define _SWAP_(X,Y) _REPLACE_(X,Y,Y,X)

#define _SWAP_KEEP_BETA_ \
    _REPLACE_(_BETA_,_ALPHA_,_BETA_,_GAMMA_) \
    _REPLACE_(_BETA_,_GAMMA_,_BETA_,_ALPHA_) \

#define _SWAP_KEEP_GAMMA_ \
    _REPLACE_(_GAMMA_,_ALPHA_,_GAMMA_,_BETA_) \
    _REPLACE_(_GAMMA_,_BETA_,_GAMMA_,_ALPHA_) \

        

// Base Triangle
Equerre Tri;

float k = 1. - sqrt(3.)*.5;

vec2 A,B,C,D,E,F,G,H;
bool AB,BC,CD,DA;

float logZoom = 0.;
float angleShift = 0.;

#define POINT_SPIRAL(n,m) (polar( pow(k,-(n + logZoom)/2.) , (n)/3.*PI + m*PI/2. - angleShift ))
// why nPI/3 and not nPI/6 ???????????????????????????

void ComputeSpiralPoints(float r)
{
    A = POINT_SPIRAL(r,0.);
    B = POINT_SPIRAL(r,1.);
    C = POINT_SPIRAL(r,2.);
    D = POINT_SPIRAL(r,3.);
    
    E = POINT_SPIRAL(r+1.,3.);
    F = POINT_SPIRAL(r+1.,0.);
    G = POINT_SPIRAL(r+1.,1.);
    H = POINT_SPIRAL(r+1.,2.);
}

bool FindEquerre(float r,vec2 uv)
{
    ComputeSpiralPoints(r);
    
    AB = !pointsOnSameSideOfLine(uv,C,A,B);
    BC = !pointsOnSameSideOfLine(uv,D,B,C);
    CD = !pointsOnSameSideOfLine(uv,A,C,D);
    DA = !pointsOnSameSideOfLine(uv,B,D,A);
    
    Tri.r = r;
    
    if(AB && !BC)
    {
        Tri.A = B;
        Tri.B = E;
        Tri.C = F;
        Tri.ID = r*4.+0.;
    }
    else if(BC && !CD)
    {
        Tri.A = C;
        Tri.B = F;
        Tri.C = G;
        Tri.ID = r*4.+1.;
    }
    else if(CD && !DA)
    {
        Tri.A = D;
        Tri.B = G;
        Tri.C = H;
        Tri.ID = r*4.+2.;
    }
    else if(DA && !AB)
    {
        Tri.A = A;
        Tri.B = H;
        Tri.C = E;
        Tri.ID = r*4.+3.;
    }
    else
    {
        //return AB || BC || CD || DA;
        return false;
    }
    
    return true;
}

vec2 deformation_pole = vec2(.3,.0);

vec2 deformation( vec2 uv )
{
    uv = cdiv( uv + deformation_pole , uv - deformation_pole );
    //uv = cdiv(vec2(1.,0.),uv);
    return uv;
    //return clog( uv + deformation_pole ) - clog( uv - deformation_pole );
    //return cexp( cdiv( uv + deformation_pole , clog( uv - deformation_pole ) ) );
}

vec2 deformation_inverse(vec2 def )
{
    return cdiv(2.*deformation_pole,def -  vec2(1.,0.)) + deformation_pole;
}

void main(void)
{
    glFragColor = vec4(1.0);
    
    int nbIterations = 1 + int(floor(pow((1.0 - cos(time*3.14/13.0))/2.0,0.5)*7.1));
    
    vec2 uv = screenToViewport(gl_FragCoord.xy );
    uv *= mat2(cos(time/6.+vec4(0.,1.6,-1.6,0.)));
    
    vec2 uv_s = deformation(uv);
    uv_s = cdiv(vec2(1.,0.),uv_s)+uv_s;
    
    viewportMagnify = 1.; 
    //uv_s *= viewportMagnify;
    
    
    angleShift = cos(time/7.5)*8.;
    logZoom = sin(time/4.)*13.;
    
    float r = floor( -log(dot(uv_s,uv_s))/log(k) - logZoom );
    
    
    if( !FindEquerre(r+1.,uv_s) )
    {
        // inside circle
        FindEquerre(r,uv_s);
    }
    
    glFragColor.rgb = hash3point(vec2(Tri.ID,Tri.ID*Tri.ID));
    
    /*Tri.A = deformation_inverse(Tri.A);
    Tri.B = deformation_inverse(Tri.B);
    Tri.C = deformation_inverse(Tri.C);
    uv_s = uv;*/

    float scale = 1./viewportMagnify/(1. + dot(uv_s,uv_s)*1.); // LOG correction
    vec3 EquerreColor = vec3(0.0,0.0,0.0);
    
    
    
    #if SHOW_SEGMENTS==1
        #define OPERATION1(x,y) glFragColor.rgb = mixColorLine(uv_s,glFragColor.rgb,EquerreColor,x,y,scale);
        OPERATION1(Tri.A,Tri.B);
        OPERATION1(Tri.B,Tri.C);
        OPERATION1(Tri.C,Tri.A);
    #endif
    
    
    scale /= 3.;
    vec2 TriCenterMix = (Tri.A + Tri.B + Tri.C)/3.;
    
    #if SHOW_DUAL_POINTS==1
        glFragColor.rgb *= 3.*(.5 + coeffDistPoint(uv_s,TriCenterMix,scale));
    #endif
    
    
    glFragColor.rgb = tanh(glFragColor.rgb *2./(1. + dot(uv_s,uv_s)/1e3 ) ); // LOG correction
}
