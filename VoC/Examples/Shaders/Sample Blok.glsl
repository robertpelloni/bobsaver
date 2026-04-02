#version 420

// original https://www.shadertoy.com/view/XtVGRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    "blok" by wjbgrafx
    
    based on :
        
    Raymarched Reflections   Uploaded by Shane in 2015-Nov-17
    https://www.shadertoy.com/view/4dt3zn
    
    Playing with symmetries - Torus       by @paulofalcao    
    http://glslsandbox.com/e#29755.0
    
    Raymarching Primitives - Created by inigo quilez - iq/2013
    https://www.shadertoy.com/view/Xds3zN

    HG_SDF : GLSL LIBRARY FOR BUILDING SIGNED DISTANCE BOUNDS
    http://mercury.sexy/hg_sdf
    
    Array and textureless GLSL 2D/3D/4D simplex noise functions.
    Ian McEwan, Ashima Arts.
    
    2D and 3D Procedural Textures in WebGL
    http://math.hws.edu/graphicsbook/demos/c7/procedural-textures.html
    
    pyramid function from "pyramids"    Uploaded by avix in 2014-Jan-16
    https://www.shadertoy.com/view/lsBGzG
*/
//==============================================================================

#define PI                      3.1415926535897932384626433832795
#define PHI                     1.618033988749895

#define FAR                     300.0
#define MAX_RAY_STEPS           90
#define MAX_REF_STEPS           50
#define MAX_SHADOW_STEPS        20

#define CAM_FOV_FACTOR          1.5
#define LOOK_AT                 vec3( 0.0, 4.0, 0.0 )
#define LIGHT_COLOR                vec3( 1.0 )
#define LIGHT_ATTEN                0.01

//------------------------------------------------------------------------------
// Function declarations
//----------------------
vec3 getRayDir( vec3 camPos, vec3 viewDir, vec2 pixelPos ) ;
vec2 trace( vec3 rayOrig, vec3 rayDir );
float traceRef( vec3 rayOrig, vec3 rayDir );
float softShadow( vec3 rayOrig, vec3 lightPos, float k );
vec3 getNormal( in vec3 p );
vec3 doColor( in vec3 sp, in vec3 rayDir, in vec3 surfNorm, in vec2 distID,
                                                            in vec3 lightPos );
float sdSphere( vec3 p, float s );
float sdEllipsoid( in vec3 p, in vec3 r );
float sdTorus( vec3 p, vec2 t );

vec2 rot( vec2 p, float r );
vec2 rotsim( vec2 p, float s );

float pMod1(inout float p, float size); 
float pReflect(inout vec3 p, vec3 planeNormal, float offset); 
vec2 pMirrorOctant (inout vec2 p, vec2 dist); 
float fPlane(vec3 p, vec3 n, float distanceFromOrigin);
float fOctahedron(vec3 p, float r, float e);
 
float pyramid( vec3 p, float h);  
float modPyramid( vec3 p, float h, float baseScale ); 
float modOctahedron( vec3 p, float height, float scale );
float modCutoutPyramid( vec3 p, float height, float scaleVal );

float snoise(vec3 v);

//==============================================================================
// MAP
// ---

vec2 map( vec3 p )
{  
    float dist = 3.0;
    pReflect( p, normalize( vec3( 1.0, -1.0, 0.0 ) ), dist );
    pReflect( p, normalize( vec3( -1.0, -1.0, 0.0 ) ), dist );

    pMod1( p.z, 20.0 );
    vec3 p2 = p;

    p2.xz = rot( p2.xz, time * 0.19 );
    p2.xz = rotsim( p2.xz, 3.0 );
    p2.z -= 6.0;

    pMirrorOctant( p.yz, vec2( 6.0 ) );

    float objID = 1.0;          
    vec2 obj1 = vec2( fPlane( p, vec3( 0.0, 1.0, 0.0 ), 5.0 ), objID );
    
    objID = 2.0;    
    vec2 obj2 = 
    vec2( modCutoutPyramid( p2 - vec3( 0.0, -5.0, 0.0 ), 7.0, 1.45 ), objID );
                                                                       
    p2.xz = rot( p2.xz, time * -0.73 );

    objID = 3.0;
    float d1 = fOctahedron( p2 - vec3( 0.0, -1.8, 0.0 ), 1.6, 10.0 ),
          d2 = sdEllipsoid( p2 - vec3( 0.0, -1.8, 0.0 ), vec3( 1.55, 1.55, 
                                                                       4.75 ) );
    vec2 obj3 = vec2(max( d1, -d2 ), objID );
          
    p2.xz = rot( p2.xz, time * 1.23 );

    objID = 4.0;
    vec2 obj4 = vec2( modOctahedron( p2 - vec3( 0.0, -1.8, 0.0 ), 1.4, 1.1 ), 
                                                                       objID );    
    objID = 5.0;
    vec2 obj5 = vec2( sdTorus( p2 - vec3( 0.0, -4.7, 0.0 ), vec2( 3.9, 0.25 ) ),
                                                                      objID );    
    objID = 1.0;
    vec2 obj6 = vec2( sdSphere( p2 - vec3( 1.6, 0.9, 1.6 ), 0.5 ), objID );
                                                                          
    vec2 obj7 = vec2( sdSphere( p2 - vec3( -1.6, 0.9, -1.6 ), 0.5 ), objID );
    
    vec2 obj8 = vec2( sdSphere( p2 - vec3( 1.6, 0.9, -1.6 ), 0.5 ), objID );
                                                                          
    vec2 obj9 = vec2( sdSphere( p2 - vec3( -1.6, 0.9, 1.6 ), 0.5 ), objID );
    
    vec2 closest = obj1;
    closest = closest.s < obj2.s ? closest : obj2;
    closest = closest.s < obj3.s ? closest : obj3;
    closest = closest.s < obj4.s ? closest : obj4;
    closest = closest.s < obj5.s ? closest : obj5;
    closest = closest.s < obj6.s ? closest : obj6;
    closest = closest.s < obj7.s ? closest : obj7;
    closest = closest.s < obj8.s ? closest : obj8;
    closest = closest.s < obj9.s ? closest : obj9;

    return closest;
}

// end map()

//------------------------------------------------------------------------------

// GET OBJECT COLOR
// ----------------

vec3 getObjectColor( vec3 p, vec2 distID, vec3 rayDir )
{    
    vec3 clr = vec3( 1.0 );
    float objNum = distID.t;
    
    if( objNum == 1.0 )
    {
        clr = vec3( 0.7, 0.8, 1.0 );
    }
    else if( objNum == 2.0 )
    {
        float timeVal = 0.3 * sin( time * 0.13 );
        clr = vec3( 0.45 + timeVal, 0.55 + timeVal, 0.7 + timeVal ); 
        
        vec3 pos = distID.s * rayDir;
        pos.z += time * 3.0; 
        
        float scale = 0.5,
              complexity = 2.0,
              mixVal = 0.875;

        // 2D and 3D Procedural Textures in WebGL
        // http://math.hws.edu/graphicsbook/demos/c7/procedural-textures.html
        // wjb modified Perlin Noise 3D 
        // Blotches of objClr surrounded by very thin squiggly black lines
        // on white background - texture 21
        vec3 v = pos * scale;
        float value = exp( inversesqrt( pow( snoise( v ), 2.0 ) * complexity ) ); 
        value = 0.75 + value * 0.25;
        vec3 color = vec3( 1.0 - value );  // inverted              
        clr = mix( color, clr, mixVal ); 
    }
    else if ( objNum == 3.0 )
    {
        float timeVal = 0.3 * sin( time * 0.17 );
        clr = vec3( 0.45 + timeVal, 0.55 + timeVal, 0.7 + timeVal );
    }
    else if ( objNum == 4.0 )    
    {
        float timeVal = 0.3 * sin( time * 0.23 );
        clr = vec3( 0.65 + timeVal, 0.7 + timeVal, 0.5 + timeVal ); 
    }
    else if( objNum == 5.0 )
    {
        float timeVal = 0.3 * sin( time * 0.29 );
        clr = vec3( 0.7 + timeVal, 0.65 + timeVal, 0.5 + timeVal ); 
    }
        
    return clr;
}

// end getObjectColor()

//------------------------------------------------------------------------------

// MAIN IMAGE
// ----------

void main(void)
{
    // Adjust aspect ratio, normalize coords, center origin in x-axis.    
    vec2 uv = ( -resolution.xy + 2.0 * gl_FragCoord.xy ) / resolution.y;
    
    // cam position moves into tunnel and up/down, side to side
    vec3 camPos = vec3( 2.0 * sin( time * 0.43 ), 
                  4.0 + 2.0 * sin( time * 0.51 ), 
                                   time * 3.0 );                               
    vec3 lookAt = camPos + vec3( 0.0, 0.0, camPos.z + 10.0 );
    vec3 rayDir = getRayDir( camPos, normalize( lookAt - camPos ), uv );   
    vec3 rayOrig = camPos;   
    vec3 lightPos = vec3( 0.0, 0.0, 
         camPos.z + 10.0 + 30.0 * sin( ( 20.0 + time ) * 
                                                   ( 0.04 * log( time ) ) ) );
    vec3 sceneColor = vec3( 0.0 );
    float timeVal = 0.3 * sin( time * 0.31 );
    vec3 skyClr  = vec3( 0.4 + timeVal, 0.5 + timeVal, 0.7 + timeVal ); 
                        
    // FIRST PASS.
    //------------
    vec2 distID = trace( rayOrig, rayDir );
    float totalDist = distID.s;
    
    if ( totalDist >= FAR )
    {
        sceneColor = skyClr;
    }
    else
    {
        // Fog based off of distance from the camera. 
        float fog = smoothstep( ( camPos.z + FAR ) * 0.4, 0.0, totalDist ); 
        
        // Advancing the ray origin to the new hit point.
        rayOrig += rayDir * totalDist;
        
        // Retrieving the normal at the hit point.
        vec3 surfNorm = getNormal( rayOrig );
        
        // Retrieving the color at the hit point.
        sceneColor = doColor( rayOrig, rayDir, surfNorm, distID, lightPos );
        
        float k = 24.0;
        float shadow = softShadow( rayOrig, lightPos, k );
       
        // SECOND PASS - REFLECTED RAY
        //----------------------------
        rayDir = reflect( rayDir, surfNorm );
        totalDist = traceRef( rayOrig +  rayDir * 0.01, rayDir );
        rayOrig += rayDir * totalDist;
        
        // Retrieving the normal at the reflected hit point.
        surfNorm = getNormal( rayOrig );
        
        // Coloring the reflected hit point, then adding a portion of it to the 
        // final scene color. Factor is percent of reflected color to add.
        sceneColor += doColor( rayOrig, rayDir, surfNorm, distID, lightPos ) 
                                                                        * 0.35;        
        // APPLYING SHADOWS
        //-----------------
        sceneColor *= shadow;
        sceneColor *= fog;
        sceneColor = mix( sceneColor, skyClr, 1.0 - fog );
        
    } // end else totalDist < FAR
    
    glFragColor = vec4(clamp(sceneColor, 0.0, 1.0), 1.0);
    
}
//------------------------------------------------------------------------------

// TRACE
// -----

// Standard raymarching routine.
vec2 trace( vec3 rayOrig, vec3 rayDir )
{   
    float totalDist = 0.0;
    vec2 distID = vec2( 0.0 );
    
    for ( int i = 0; i < MAX_RAY_STEPS; i++ )
    {
        distID = map( rayOrig + rayDir * totalDist );
        float dist = distID.s;
        
        if( abs( dist ) < 0.0025 || totalDist > FAR ) 
        {
            break;
        }
        
        totalDist += dist * 0.75;  // Using more accuracy, in the first pass.
    }
    
    return vec2( totalDist, distID.t );
}

// end trace()

//------------------------------------------------------------------------------

// TRACE REFLECTIONS
// -----------------

// Second pass, which is the first, and only, reflected bounce. Virtually the 
// same as above, but with fewer iterations and less accuracy.

// The reason for a second, virtually identical equation is that raymarching is 
// usually a pretty expensive exercise, so since the reflected ray doesn't 
// require as much detail, you can relax things a bit - in the hope of speeding 
// things up a little.

float traceRef( vec3 rayOrig, vec3 rayDir )
{    
    float totalDist = 0.0;
    
    for ( int i = 0; i < MAX_REF_STEPS; i++ )
    {
        float dist = map( rayOrig + rayDir * totalDist ).s;
        
        if( abs( dist ) < 0.0025 || totalDist > FAR ) 
        {
            break;
        }
        
        totalDist += dist;
    }
    
    return totalDist;
}

// end traceRef()

//------------------------------------------------------------------------------

// SOFT SHADOW
// -----------

// The value "k" is just a fade-off factor that enables you to control how soft  
// you want the shadows to be. Smaller values give a softer penumbra, and larger
// values give a more hard edged shadow.

float softShadow( vec3 rayOrig, vec3 lightPos, float k )
{
    vec3 rayDir = ( lightPos - rayOrig ); // Unnormalized direction ray.

    float shade = 1.0;
    float dist = 0.01;    
    float end = max( length( rayDir ), 0.001 );
    float stepDist = end / float( MAX_SHADOW_STEPS );
    
    rayDir /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow 
    // things down. Obviously, the lowest number to give a decent shadow is the 
    // best one to choose. 
    for ( int i = 0; i < MAX_SHADOW_STEPS; i++ )
    {
        float h = map( rayOrig + rayDir * dist ).s;

        //shade = min( shade, k * h / dist );
        // Subtle difference. Thanks to IQ for this tidbit.
        shade = min( shade, smoothstep( 0.0, 1.0, k * h / dist)); 

        // So many options here, and none are perfect: dist += min( h, 0.2 ),etc
        dist += min( h, stepDist * 2.0 ); 
        
        // Early exits from accumulative distance function calls tend to be a 
        // good thing.
        if ( h < 0.001 || dist > end ) 
        {
            break; 
        }
    }

    // I've added 0.5 to the final shade value, which lightens the shadow a bit. 
    // It's a preference thing. Really dark shadows look too brutal to me.
    return min( max( shade, 0.0 ) + 0.5, 1.0 ); 
}

// end softShadow()

//------------------------------------------------------------------------------

// GET NORMAL
// ----------

// Tetrahedral normal, to save a couple of "map" calls. Courtesy of IQ.

vec3 getNormal( in vec3 p )
{
    // Note the slightly increased sampling distance, to alleviate
    // artifacts due to hit point inaccuracies.
    vec2 e = vec2( 0.005, -0.005 ); 
    return normalize( e.xyy * map( p + e.xyy ).s + 
                      e.yyx * map( p + e.yyx ).s + 
                      e.yxy * map( p + e.yxy ).s + 
                      e.xxx * map( p + e.xxx ).s );

}

// end getNormal()

//------------------------------------------------------------------------------

// DO COLOR
// --------

vec3 doColor( in vec3 sp, in vec3 rayDir, in vec3 surfNorm, in vec2 distID,
                                                             in vec3 lightPos )
{    
    // Light direction vector.
    //vec3 lDir = LIGHT_POS - sp; 
    vec3 lDir = lightPos - sp; 

    // Light to surface distance.
    float lDist = max( length( lDir ), 0.001 ); 

    // Normalizing the light vector.
    lDir /= lDist; 
    
    // Attenuating the light, based on distance.
    //float atten = 1.0 / ( 1.0 + lDist * 0.25 + lDist * lDist * 0.05 );
    float atten = 1.0 / ( lDist * lDist * LIGHT_ATTEN );
    
    // Standard diffuse term.
    float diff = max( dot( surfNorm, lDir ), 0.0 );
    
    // Standard specular term.
    float spec = 
            pow( max( dot( reflect( -lDir, surfNorm ), -rayDir ), 0.0 ), 8.0 );
    
    // wjb added rayDir as argument in order to allow texturing of objects.
    vec3 objCol = getObjectColor( sp, distID, rayDir );
    
    // Combining the above terms to produce the final scene color.
    vec3 sceneCol = ( objCol * ( diff + 0.15 ) + LIGHT_COLOR * spec * 2.0 ) * 
                                                                         atten;
  
    return sceneCol;   
}

// end doColor()

//------------------------------------------------------------------------------

// GET RAY DIRECTION
// -----------------

vec3 getRayDir( vec3 camPos, vec3 viewDir, vec2 pixelPos ) 
{
    vec3 camRight = normalize( cross( viewDir, vec3( 0.0, 1.0, 0.0 ) ) );
    vec3 camUp = normalize( cross( camRight, viewDir ) );
    
    return normalize( pixelPos.x * camRight + pixelPos.y * camUp + 
                                                    CAM_FOV_FACTOR * viewDir );
}

// end getRayDir()

//------------------------------------------------------------------------------

// From "Raymarching Primitives" - // Created by inigo quilez - iq/2013
// https://www.shadertoy.com/view/Xds3zN

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdEllipsoid( in vec3 p, in vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

// Horizontal torus lying in xz plane at y = 0; t = vec2( lg. diam, sm. diam )
float sdTorus( vec3 p, vec2 t )
{
  return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

//------------------------------------------------------------------------------

// From Playing with symmetries - Torus       by @paulofalcao    
// http://glslsandbox.com/e#29755.0

// Rotation around z-axis when vec2 p.xy;
// Rotation around y-axis when vec2 p.xz;
// Rotation around x-axis when vec2 p.yz.
vec2 rot(vec2 p,float r)
{
   vec2 ret;
   ret.x=p.x*cos(r)-p.y*sin(r);
   ret.y=p.x*sin(r)+p.y*cos(r);
   return ret;
}

// When vec2 p.xy, rotational symmetry about z-axis;
// when vec2 p.xz, rotational symmetry about y-axis
// when vec2 p.yz, rotational symmetry about x-axis
vec2 rotsim(vec2 p,float s)
{
   vec2 ret=p;
   ret=rot(p,-PI/(s*2.0));
   ret=rot(p,floor(atan(ret.x,ret.y)/PI*s)*(PI/s));
   return ret;
}

//------------------------------------------------------------------------------
// HG_SDF : GLSL LIBRARY FOR BUILDING SIGNED DISTANCE BOUNDS
// http://mercury.sexy/hg_sdf

// Sign function that doesn't return 0
float sgn(float x) 
{
    return (x<0.)?-1.:1.;
}

vec2 sgn(vec2 v) 
{                           
    return vec2((v.x<0.)?-1.:1., (v.y<0.)?-1.:1.);
}

// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
float pMod1(inout float p, float size) 
{
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

// Reflect space at a plane
float pReflect(inout vec3 p, vec3 planeNormal, float offset) 
{
    float t = dot(p, planeNormal)+offset;
    if (t < 0.) {
        p = p - (2.*t)*planeNormal;
    }
    return sgn(t);    
}

// Mirror at an axis-aligned plane which is at a specified distance <dist> 
// from the origin.
float pMirror (inout float p, float dist) 
{
    float s = sgn(p); 
    p = abs(p)-dist;
    return s;
}

// Mirror in both dimensions and at the diagonal, yielding one eighth of the space.
// translate by dist before mirroring.
vec2 pMirrorOctant (inout vec2 p, vec2 dist) 
{
    vec2 s = sgn(p);    
    pMirror(p.x, dist.x);
    pMirror(p.y, dist.y);
    if (p.y > p.x)
        p.xy = p.yx;
    return s;
}

// Plane with normal n (n is normalized) at some distance from the origin
float fPlane(vec3 p, vec3 n, float distanceFromOrigin) {
    return dot(p, n) + distanceFromOrigin;
}

//------------------------------------------------------------------------------

// https://www.shadertoy.com/view/lsBGzG
// Pyramid with base on xz-plane at y=0.0, h = height, width, and depth
float pyramid( vec3 p, float h) 
{
    vec3 q=abs(p);
    return max(-p.y, (q.x+q.y+q.z-h)/3.0 );
}

//------------------------------------------------------------------------------

// Modified from pyramid(), above.
// Pyramid with base on xz-plane at y=0.0, h = height, s = scaling factor for
// length of an edge of the square pyramid base, where edge length = s * h, 
// i.e., h = 2.0, s = 0.5, base edge = 1.0; or h = 2.0, s = 2.0, base edge = 4.0
// s MUST BE >= 0.5
                        
float modPyramid( vec3 p, float h, float s ) 
{
    vec3 q = abs( p );
    float scale = 1.0 / s;
    return max( -p.y, ( q.x * scale + q.y + q.z * scale - h ) / 3.0 );
}

//------------------------------------------------------------------------------
// wjb : This should replace cutoutPyramid, as it allows adjustment of size of
// cutout.
float modCutoutPyramid( vec3 p, float height, float scaleVal )
{
    vec3 p2 = p;
    p2.xz = rot( p2.xz, PI * 0.25 );
    
    float d1 = pyramid( p2, height ),
          d2 = modPyramid( p - vec3( 0.0, 0.1, 0.0 ),  
                                           height * ( scaleVal / 1.5 ), 1.35 );
    return max( d1, -d2 );
}
//------------------------------------------------------------------------------
// wjb: Joining two modPyramids to form an octahedron with variable base length.
// scale MUST BE >= 0.5

float modOctahedron( vec3 p, float height, float scale )
{
    float d1 = modPyramid( p, height, scale );
    p.yz = rot( p.yz, PI );
    float d2 = modPyramid( p, height, scale );
    return min( d1, d2 );        
}
//------------------------------------------------------------------------------

//
// "Generalized Distance Functions" by Akleman and Chen.
// see the Paper at https://www.viz.tamu.edu/faculty/ergun/research/implicitmodeling/papers/sm99.pdf
//
// This set of constants is used to construct a large variety of geometric primitives.
// Indices are shifted by 1 compared to the paper because we start counting at Zero.
// Some of those are slow whenever a driver decides to not unroll the loop,
// which seems to happen for fIcosahedron und fTruncatedIcosahedron on nvidia 350.12 at least.
// Specialized implementations can well be faster in all cases.
//
// wjb note - This is the code from first version, newer version crashes Nvidia
// Macro based version for GLSL 1.2 / ES 2.0

#define GDFVector0 vec3(1, 0, 0)
#define GDFVector1 vec3(0, 1, 0)
#define GDFVector2 vec3(0, 0, 1)

#define GDFVector3 normalize(vec3(1, 1, 1 ))
#define GDFVector4 normalize(vec3(-1, 1, 1))
#define GDFVector5 normalize(vec3(1, -1, 1))
#define GDFVector6 normalize(vec3(1, 1, -1))

#define GDFVector7 normalize(vec3(0, 1, PHI+1.))
#define GDFVector8 normalize(vec3(0, -1, PHI+1.))
#define GDFVector9 normalize(vec3(PHI+1., 0, 1))
#define GDFVector10 normalize(vec3(-PHI-1., 0, 1))
#define GDFVector11 normalize(vec3(1, PHI+1., 0))
#define GDFVector12 normalize(vec3(-1, PHI+1., 0))

#define GDFVector13 normalize(vec3(0, PHI, 1))
#define GDFVector14 normalize(vec3(0, -PHI, 1))
#define GDFVector15 normalize(vec3(1, 0, PHI))
#define GDFVector16 normalize(vec3(-1, 0, PHI))
#define GDFVector17 normalize(vec3(PHI, 1, 0))
#define GDFVector18 normalize(vec3(-PHI, 1, 0))

#define fGDFBegin float d = 0.;

// Version with variable exponent.
// This is slow and does not produce correct distances, but allows for bulging 
// of objects.
#define fGDFExp(v) d += pow(abs(dot(p, v)), e);

// Version with without exponent, creates objects with sharp edges and flat faces
#define fGDF(v) d = max(d, abs(dot(p, v)));

#define fGDFExpEnd return pow(d, 1./e) - r;
#define fGDFEnd return d - r;

// Primitives follow:

float fOctahedron(vec3 p, float r, float e) {
    fGDFBegin
    fGDFExp(GDFVector3) fGDFExp(GDFVector4) fGDFExp(GDFVector5) fGDFExp(GDFVector6)
    fGDFExpEnd
}

float fDodecahedron(vec3 p, float r, float e) {
    fGDFBegin
    fGDFExp(GDFVector13) fGDFExp(GDFVector14) fGDFExp(GDFVector15) fGDFExp(GDFVector16)
    fGDFExp(GDFVector17) fGDFExp(GDFVector18)
    fGDFExpEnd
}

float fIcosahedron(vec3 p, float r, float e) {
    fGDFBegin
    fGDFExp(GDFVector3) fGDFExp(GDFVector4) fGDFExp(GDFVector5) fGDFExp(GDFVector6)
    fGDFExp(GDFVector7) fGDFExp(GDFVector8) fGDFExp(GDFVector9) fGDFExp(GDFVector10)
    fGDFExp(GDFVector11) fGDFExp(GDFVector12)
    fGDFExpEnd
}

float fTruncatedOctahedron(vec3 p, float r, float e) {
    fGDFBegin
    fGDFExp(GDFVector0) fGDFExp(GDFVector1) fGDFExp(GDFVector2) fGDFExp(GDFVector3)
    fGDFExp(GDFVector4) fGDFExp(GDFVector5) fGDFExp(GDFVector6)
    fGDFExpEnd
}

float fTruncatedIcosahedron(vec3 p, float r, float e) {
    fGDFBegin
    fGDFExp(GDFVector3) fGDFExp(GDFVector4) fGDFExp(GDFVector5) fGDFExp(GDFVector6)
    fGDFExp(GDFVector7) fGDFExp(GDFVector8) fGDFExp(GDFVector9) fGDFExp(GDFVector10)
    fGDFExp(GDFVector11) fGDFExp(GDFVector12) fGDFExp(GDFVector13) fGDFExp(GDFVector14)
    fGDFExp(GDFVector15) fGDFExp(GDFVector16) fGDFExp(GDFVector17) fGDFExp(GDFVector18)
    fGDFExpEnd
}

float fOctahedron(vec3 p, float r) {
    fGDFBegin
    fGDF(GDFVector3) fGDF(GDFVector4) fGDF(GDFVector5) fGDF(GDFVector6)
    fGDFEnd
}

float fDodecahedron(vec3 p, float r) {
    fGDFBegin
    fGDF(GDFVector13) fGDF(GDFVector14) fGDF(GDFVector15) fGDF(GDFVector16)
    fGDF(GDFVector17) fGDF(GDFVector18)
    fGDFEnd
}

float fIcosahedron(vec3 p, float r) {
    fGDFBegin
    fGDF(GDFVector3) fGDF(GDFVector4) fGDF(GDFVector5) fGDF(GDFVector6)
    fGDF(GDFVector7) fGDF(GDFVector8) fGDF(GDFVector9) fGDF(GDFVector10)
    fGDF(GDFVector11) fGDF(GDFVector12)
    fGDFEnd
}

float fTruncatedOctahedron(vec3 p, float r) {
    fGDFBegin
    fGDF(GDFVector0) fGDF(GDFVector1) fGDF(GDFVector2) fGDF(GDFVector3)
    fGDF(GDFVector4) fGDF(GDFVector5) fGDF(GDFVector6)
    fGDFEnd
}

float fTruncatedIcosahedron(vec3 p, float r) {
    fGDFBegin
    fGDF(GDFVector3) fGDF(GDFVector4) fGDF(GDFVector5) fGDF(GDFVector6)
    fGDF(GDFVector7) fGDF(GDFVector8) fGDF(GDFVector9) fGDF(GDFVector10)
    fGDF(GDFVector11) fGDF(GDFVector12) fGDF(GDFVector13) fGDF(GDFVector14)
    fGDF(GDFVector15) fGDF(GDFVector16) fGDF(GDFVector17) fGDF(GDFVector18)
    fGDFEnd
}

//------------------------------------------------------------------------------
//
    // FOLLOWING CODE was OBTAINED FROM https://github.com/ashima/webgl-noise
    // This is the code for 3D and 2D Perlin noise, using simplex method.
    //
    
    //------------------------------- 3D Noise ---------------------------------
    // Description : Array and textureless GLSL 2D/3D/4D simplex 
    //               noise functions.
    //      Author : Ian McEwan, Ashima Arts.
    //  Maintainer : ijm
    //     Lastmod : 20110822 (ijm)
    //     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
    //               Distributed under the MIT License. See LICENSE file.
    //               https://github.com/ashima/webgl-noise
    // 
    
    vec3 mod289(vec3 x) {
      return x - floor(x * (1.0 / 289.0)) * 289.0;
    }
    
    vec4 mod289(vec4 x) {
      return x - floor(x * (1.0 / 289.0)) * 289.0;
    }
    
    vec4 permute(vec4 x) {
         return mod289(((x*34.0)+1.0)*x);
    }
    
    vec4 taylorInvSqrt(vec4 r)
    {
      return 1.79284291400159 - 0.85373472095314 * r;
    }
    
    float snoise(vec3 v)
      { 
        const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
        const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);
      
      // First corner
        vec3 i  = floor(v + dot(v, C.yyy) );
        vec3 x0 =   v - i + dot(i, C.xxx) ;
      
      // Other corners
        vec3 g = step(x0.yzx, x0.xyz);
        vec3 l = 1.0 - g;
        vec3 i1 = min( g.xyz, l.zxy );
        vec3 i2 = max( g.xyz, l.zxy );
      
        //   x0 = x0 - 0.0 + 0.0 * C.xxx;
        //   x1 = x0 - i1  + 1.0 * C.xxx;
        //   x2 = x0 - i2  + 2.0 * C.xxx;
        //   x3 = x0 - 1.0 + 3.0 * C.xxx;
        vec3 x1 = x0 - i1 + C.xxx;
        vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
        vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y
      
      // Permutations
        i = mod289(i); 
        vec4 p = permute( permute( permute( 
                   i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
                 + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
                 + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));
      
      // Gradients: 7x7 points over a square, mapped onto an octahedron.
      // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
        float n_ = 0.142857142857; // 1.0/7.0
        vec3  ns = n_ * D.wyz - D.xzx;
      
        vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)
      
        vec4 x_ = floor(j * ns.z);
        vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)
      
        vec4 x = x_ *ns.x + ns.yyyy;
        vec4 y = y_ *ns.x + ns.yyyy;
        vec4 h = 1.0 - abs(x) - abs(y);
      
        vec4 b0 = vec4( x.xy, y.xy );
        vec4 b1 = vec4( x.zw, y.zw );
      
        //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
        //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
        vec4 s0 = floor(b0)*2.0 + 1.0;
        vec4 s1 = floor(b1)*2.0 + 1.0;
        vec4 sh = -step(h, vec4(0.0));
      
        vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
        vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
      
        vec3 p0 = vec3(a0.xy,h.x);
        vec3 p1 = vec3(a0.zw,h.y);
        vec3 p2 = vec3(a1.xy,h.z);
        vec3 p3 = vec3(a1.zw,h.w);
      
      //Normalise gradients
        vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), 
                                                                  dot(p3,p3)));
        p0 *= norm.x;
        p1 *= norm.y;
        p2 *= norm.z;
        p3 *= norm.w;
      
      // Mix final noise value
        vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 
                                                                           0.0);
        m = m * m;
        return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                      dot(p2,x2), dot(p3,x3) ) );
      }

//------------------------------------------------------------------------------
