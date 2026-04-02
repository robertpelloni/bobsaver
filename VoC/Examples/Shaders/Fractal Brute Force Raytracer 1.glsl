#version 420

//brute force raytracing code for testing new formulas out

//variables passed in from Visions Of Chaos
uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform int frames;

out vec4 glFragColor;

//unremark which formula/fractal you want to render
#define Mandelbulb
//#define Polynomial1
//#define Polynomial2
//#define TTA8
//#define TTA9Power2
//#define TTA10
//#define TTA11
//#define TTA12
//#define TTA13
//#define TTA13Radians
//#define TTA14
//#define TTA15
//#define TTA16
//#define TTA17
//#define TTA18
//#define TTA19
//#define TTA20Power8
//#define TTA20
//#define TTA21
//#define Riemann
//#define Msltoe
//#define Msltoe2
//#define Kali1
//#define Benesi1
//#define Benesi2
//#define Decker

//unremark which render method you want to use
//#define XYZtoRGB
//#define XYZtoRGBandDistance
//#define Distance
//#define dFd
#define Normal

//how many steps are made along each ray when looking for the fractal surface
#define RaySteps 1000000

//supersampling - 1=off
#define samplepixels 1

//rotations
#define xrot 140
#define yrot 0
#define zrot 0
//uncomment the following 3 lines to auto-rotate the fractal
//#define xrot (time*90)
//#define yrot (time*50)
//#define zrot (time*70)

//ambient occlusion
//unremark for no fake AO based on orbit traps
//the minorbit and maxorbit settings need to be set for each fractal type
#define AmbientOcclusion 

//specific settings for each of the fractal types supported
#ifdef Mandelbulb
    float Power=8.0;
    float Bailout=4.0;
    int maxiter=5;
    float CameraDistance=3.4;
    #define minorbit 0.7 //higher value make darker crevices
    #define maxorbit 1.0 //lower values make brighter surface
#endif
 
#ifdef Polynomial1
    float Power=8.0;
    float Bailout=4.0;
    int maxiter=5;
    float CameraDistance=3.4;
    #define minorbit 0.75 //higher value make darker crevices
    #define maxorbit 1.0 //lower values make brighter surface
#endif
 
#ifdef Polynomial2
    float Power=5.0;
    float Bailout=4.0;
    int maxiter=5;
    float CameraDistance=3.4;
    #define minorbit 0.75 //higher value make darker crevices
    #define maxorbit 1.0 //lower values make brighter surface
#endif
 
#ifdef TTA8
    float Power=3.0;
    float Bailout=4.0;
    int maxiter=5;
    float CameraDistance=4.0;
    #define minorbit 0.7 //higher value make darker crevices
    #define maxorbit 1.0 //lower values make brighter surface
#endif

#ifdef TTA9Power2
    float Power=2.0;
    float Bailout=10.0;
    int maxiter=10;
    float CameraDistance=6.0;
    #define minorbit 0.7 //higher value make darker crevices
    #define maxorbit 1.0 //lower values make brighter surface
#endif

#ifdef TTA10
    float Power=8.0;
    float Bailout=8.0;
    int maxiter=8;
    float CameraDistance=4.0;
    #define minorbit 0.6 //higher value make darker crevices
    #define maxorbit 0.8 //lower values make brighter surface
#endif

#ifdef TTA11
    float Power=8.0;
    float Bailout=8.0;
    int maxiter=6;
    float CameraDistance=4.0;
    #define minorbit 0.6 //higher value make darker crevices
    #define maxorbit 0.8 //lower values make brighter surface
#endif

#ifdef TTA12
    float Power=8.0;
    float Bailout=20.0;
    int maxiter=9;
    float CameraDistance=4.0;
    #define minorbit 0.6 //higher value make darker crevices
    #define maxorbit 0.8 //lower values make brighter surface
#endif

#ifdef TTA13
    float Power=8.0;
    float Bailout=16.0;
    int maxiter=8;
    float CameraDistance=4.6;
    #define minorbit 0.7 //higher value make darker crevices
    #define maxorbit 1.0 //lower values make brighter surface
#endif

#ifdef TTA13Radians
    float Power=8.0;
    float Bailout=16.0;
    int maxiter=8;
    float CameraDistance=4.4;
    #define minorbit 0.7 //higher value make darker crevices
    #define maxorbit 1.0 //lower values make brighter surface
#endif

#ifdef TTA14
    float Power=8.0;
    float Bailout=8.0;
    int maxiter=7;
    float CameraDistance=3.8;
    #define minorbit 0.6 //higher value make darker crevices
    #define maxorbit 0.8 //lower values make brighter surface
#endif

#ifdef TTA15
    float Power=8.0;
    float Bailout=18.0;
    int maxiter=9;
    float CameraDistance=3.8;
    #define minorbit 0.5 //higher value make darker crevices
    #define maxorbit 0.7 //lower values make brighter surface
#endif

#ifdef TTA16
    float Power=8.0;
    float Bailout=8.0;
    int maxiter=7;
    float CameraDistance=3.8;
    #define minorbit 0.7 //higher value make darker crevices
    #define maxorbit 1.0 //lower values make brighter surface
#endif

#ifdef TTA17
    float Power=8.0;
    float Bailout=8.0;
    int maxiter=6;
    float CameraDistance=3.8;
    #define minorbit 0.7 //higher value make darker crevices
    #define maxorbit 0.9 //lower values make brighter surface
#endif

#ifdef TTA18
    float Power=8.0;
    float Bailout=8.0;
    int maxiter=7;
    float CameraDistance=3.8;
    #define minorbit 0.6 //higher value make darker crevices
    #define maxorbit 0.8 //lower values make brighter surface
#endif

#ifdef TTA19
    float Power=4.0;
    float Bailout=8.0;
    int maxiter=7;
    float CameraDistance=3.8;
    #define minorbit 0.3 //higher value make darker crevices
    #define maxorbit 0.6 //lower values make brighter surface
#endif

#ifdef TTA20Power8
    float Power=8.0;
    float Bailout=20.0;
    int maxiter=25;
    float CameraDistance=3.4;
    #define minorbit 0.3 //higher value make darker crevices
    #define maxorbit 0.5 //lower values make brighter surface
#endif

#ifdef TTA20
    float Power=8.0;
    float Bailout=4.0;
    int maxiter=6;
    float CameraDistance=3.4;
    #define minorbit 0.6 //higher value make darker crevices
    #define maxorbit 0.8 //lower values make brighter surface
#endif

#ifdef TTA21
    float Power=8.0;
    float Bailout=10.0;
    int maxiter=25;
    float CameraDistance=4.2;
    #define minorbit 0.4 //higher value make darker crevices
    #define maxorbit 0.6 //lower values make brighter surface
#endif

#ifdef Riemann
    float Power=2.0;
    float Bailout=20.0;
    int maxiter=6;
    float CameraDistance=8.5;
    #define minorbit 1.4 //higher value make darker crevices
    #define maxorbit 1.6 //lower values make brighter surface
#endif

#ifdef Msltoe
    float Power=4.0;
    float Bailout=8.0;
    int maxiter=50;
    float CameraDistance=3.1;
    #define minorbit 0.1 //higher value make darker crevices
    #define maxorbit 0.2 //lower values make brighter surface
#endif
 
#ifdef Msltoe2
    float Power=8.0;
    float Bailout=8.0;
    int maxiter=20;
    float CameraDistance=3.1;
    #define minorbit 0.0 //higher value make darker crevices
    #define maxorbit 0.6 //lower values make brighter surface
#endif
 
#ifdef Kali1
    float Power=2.0;
    float Bailout=16.0;
    int maxiter=12;
    float CameraDistance=4.0;
    #define minorbit 0.3 //higher value make darker crevices
    #define maxorbit 0.6 //lower values make brighter surface
#endif
 
#ifdef Benesi1
    float Power=2.0;
    float Bailout=20.0;
    int maxiter=6;
    float CameraDistance=3.2;
    #define minorbit 0.5 //higher value make darker crevices
    #define maxorbit 0.7 //lower values make brighter surface
#endif

#ifdef Benesi2
    float Power=2.0;
    float Bailout=10.0;
    int maxiter=6;
    float CameraDistance=4.0;
    #define minorbit 0.3 //higher value make darker crevices
    #define maxorbit 0.6 //lower values make brighter surface
#endif

#ifdef Decker
    float Power=8.0;
    float Bailout=40.0;
    int maxiter=15;
    float CameraDistance=2.9;
    #define minorbit 0.2 //higher value make darker crevices
    #define maxorbit 0.6 //lower values make brighter surface
#endif

//global variables
bool inside=false;
vec3 z,c,CameraPosition,RayDirection;
float smallestorbit,stepsize;
float PI=3.14159265;
float pidiv180=PI/180.0;

void Rotate2(in float Rx, in float Ry, in float Rz, in float x, in float y, in float z, out float Nx, out float Ny, out float Nz) {
    float TempX,TempY,TempZ,SinX,SinY,SinZ,CosX,CosY,CosZ,XRadAng,YRadAng,ZRadAng;
    XRadAng=Rx*pidiv180;
    YRadAng=Ry*pidiv180;
    ZRadAng=Rz*pidiv180;
    SinX=sin(XRadAng);
    SinY=sin(YRadAng);
    SinZ=sin(ZRadAng);
    CosX=cos(XRadAng);
    CosY=cos(YRadAng);
    CosZ=cos(ZRadAng);
    TempY=y*CosY-z*SinY;
    TempZ=y*SinY+z*CosY;
    TempX=x*CosX-TempZ*SinX;
    Nz=x*SinX+TempZ*CosX;
    Nx=TempX*CosZ-TempY*SinZ;
    Ny=TempX*SinZ+TempY*CosZ;
}

void Rotate(in float Rx, in float Ry, in float Rz, in float x, in float y, in float z, in float ox, in float oy, in float oz, out float Nx, out float Ny, out float Nz){
    Rotate2(Rx,Ry,Rz,x-ox,y-oy,z-oz,Nx,Ny,Nz);
    Nx=Nx+ox;
    Ny=Ny+oy;
    Nz=Nz+oz;
}

// returns the vector product of two vectors according to TTA8 maths ie
// ( a, b, c )( x , y, z ) = (ax - by - cz, ay + b|q| + ys2( by + cz )( x - |q| ), az + c|q| + zs2( by + cz )( x - |q| ) )    
vec3 TTA8product( vec3 m, vec3 n, float q, float s ){
    return vec3( m.x*n.x - m.y*n.y - m.z*n.z,
                 m.x*n.y + m.y*q + n.y*s*s*( m.y*n.y + m.z*n.z )*( m.x - q ),
                 m.x*n.z + m.z*q + n.z*s*s*( m.y*n.y + m.z*n.z )*( m.x - q ));
}

float pow3(in float x, in float y) {
    float powval;
    powval=x;
    for (int i=0;i<int(y-1);i++) {
        powval*=x;
    }
    return powval;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is a wrapper function to get around the shortcomings of the glsl function pow(), which does not handle negative x.             //
//                                                                                                                                     //
// We assume the user types in at most six digits after the decimal point for the exponent y.                                          //
// The idea is to get the decimal part of y into the form p/q, where p and q are not both even. If they are, then we divide both by 2. //
// If p is odd and q is even then the result is not a real value.                                                                      //
// If both are odd then the decimal part of y generates a negative result.                                                             //
// If p is even and q is odd then the decimal part of y generates a positive result.                                                   //
// We also need to take into account the sign generated by the integer part of y.                                                      //
// This function correctly handles the following cases:                                                                                //
// (-2^)(-3) = -1/8, (-2^)(4) = 16, (-27)^(1/3) = -3, (-27)^(4/3) = 81, (-27)^(5/3) = -243, (-27)^(7/3) = -2463.                       //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
float pow2(in float x,in float y ) // raise x to the power y
{
    if ( x > 0.0 ) return pow( x, y );
    if ( x == 0.0 ) return 0.0;

    // x is negative
    float r;
    int yeven = 0;                // assume the integer part of y is odd
    int tmp, tmp2;
    int p, q;                        // numerator and denominator

    if ( y < 0 ) {
        tmp = int(floor(y)) + 1;    // the integer part of y, noting that floor( -1.1 ) = -2
    } else {
        tmp = int(floor(y));          // the integer part of y
    }
    tmp2 = 2*int(floor(float(tmp/2)));
    if ( tmp2 == tmp )  
        yeven = 1;               // the integer part of y is even
    
    if ( y == float( floor(y) ) ) // is y an integer?
    {   // yes
        if ( yeven == 1 )
            return pow( -x, y ); // y is an even integer so the result is positive
        else
    return -pow( -x, y ); // y is an odd integer so the result is negative
    }

    // y is not an integer, so let's look at the decimal part of y as p/q
    r = abs( y - tmp );           // the decimal part of y 
    p = int(floor( 1000000.0*r ));  // make the numerator into an integer - we assume y has at most 6 decimal places 
    q = 1000000;                 // denominator, initially even

    // We need to eliminate common factors of 2 until at least one of p and q is odd.
    for ( int i = 0; i < 7; i++ )  // the loop limit is just a sanity check, as 1,000,000 = 2^6*5^6
    {                                    // so that we should divide by 2 at most 6 times
            tmp = 2*int(floor(float( p/2)) );
    tmp2 = 2*int(floor( float(q/2)) );
        if ( tmp != p )        // is the numerator odd?
    {           // numerator is odd
        if ( tmp2 == q )     // is the denominator even?
            return 0.0;        // numerator is odd, denominator even, ie not a real number
        else
        {   // denominator is odd
            if ( yeven == 1 ) 
                return -pow( -x, y ); // both are odd, so the result is negative, integer part of y is even
            else
                return pow( -x, y );  // both are odd, so the result is positive due to the integer part being odd
        }
    }
    else 
    {           // numerator is even
        if ( tmp2 != q )
        {   // denominator is odd
                if ( yeven == 1 ) 
                return pow( -x, y );  // numerator is even, denominator odd, so the result is positive
            else
                return -pow( -x, y ); // numerator is even, denominator odd, but integer part of y is odd, so the result is negative
        }
        else
        {   // denominator is also even, so we halve both
            p = int(floor( float(p/2) ));
            q = int(floor( float(q/2) ));
        }
    }
    }
    return 0.0;       // if we get here then there is an error in the code
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is a wrapper function to get around the shortcomings of the glsl function pow(), which does not handle powers of negative numbers.               //
// If x is non-negative then we simply call pow(x, y). If x is negative then we work out the sign of the result and call pow(-x, y).                     //
// It is assumed that the exponent y, has at most 6 decimal places.                                                                                      //
//                                                                                                                                                       //
// The idea is to get the decimal part of y into the form p/q, where p and q are not both even. If they are, then we divide both by 2 until they aren't. //
// If both are odd then the decimal part of y generates a negative result.                                                                               //
// If p is even and q is odd then the decimal part of y generates a positive result.                                                                     //
// If p is odd and q is even then the result is not a real value.                                                                                        //
// The function correctly handles the following, which illustrate the above three cases:                                                                 //
// (-27)^(1/3) = -3, (-27)^(2/3) = 9, (-4)^(1/2) = 2i.                                                                                                   //
// (-1)^0.000064 is negative, (-1)^0.000128 is positive, (-1)^0.000063 is imaginary.                                                                     //
// We also need to take into account the sign generated by the integer part of y.                                                                        //
//                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
float pow4( float x, float y )   // raise x to the power y
{
    if ( x > 0.0 ) return pow( x, y );
    if ( x == 0.0 ) return 0.0;

    // x is negative
    float r;
    int yeven = 0;                // assume the integer part of y is odd
    int tmp, tmp2;
    int p, q;                     // numerator and denominator

    if ( y < 0 )
        tmp = int( floor(y) + 1 );// the integer part of y, noting that floor( -1.1 ) = -2
    else
        tmp = int( floor(y) );    // the integer part of y
    tmp2 = int( 2*floor( tmp/2.0 ));
    if ( tmp2 == tmp )  
        yeven = 1;                // the integer part of y is even
    
    if ( y == float( floor(y) ) ) // is y an integer?
    {   // yes
        if ( yeven == 1 )
            return pow( -x, y );  // y is an even integer so the result is positive
        else
          return -pow( -x, y ); // y is an odd integer so the result is negative
    }

    // y is not an integer, so let's look at the decimal part of y as p/q
    r = abs( y - tmp );           // the decimal part of y made positive
    p = int( floor( 1000000.0*r ));// make the numerator into an integer - we assume y has at most 6 decimal places 
    q = 1000000;                  // denominator, initially even

    // We need to eliminate common factors of 2 until at least one of p and q is odd.
    for ( int i = 0; i < 7; i++ ) // the loop limit is just a sanity check, as 1,000,000 = 2^6*5^6
    {                             // so that we should divide by 2 at most 6 times
      tmp = int( 2*floor( p/2.0 ));
    tmp2 = int( 2*floor( q/2.0 ));
        if ( tmp != p )             // is the numerator odd?
    {                           // numerator is odd
        if ( tmp2 == q )      // is the denominator even?
            return 0.0;       // numerator is odd, denominator even, ie not a real number
        else
        {                     // denominator is odd
            if ( yeven == 1 ) 
                return -pow( -x, y );// numerator and denominator odd, integer part of y is even, so the result is negative
            else
                return pow( -x, y );// numerator and denominator odd, integer part of y is odd, so the result is positive
        }
    }
    else 
    {                           // numerator is even
        if ( tmp2 != q )
        {                     // denominator is odd
                if ( yeven == 1 ) 
                return pow( -x, y );// numerator is even, denominator odd, integer part of y is even, so the result is positive
            else
                return -pow( -x, y );// numerator is even, denominator odd, integer part of y is odd, so the result is negative
        }
        else
        {                     // denominator is also even, so we halve both
            p = p/2;
            q = q/2;
        }
    }
    }
    return 0.0;                   // if we get here then there is an error in the code
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  

//performs one z=z^p+c iteration
void Iterate(inout vec3 z,in vec3 c) {
    vec3 tmpz;
    float h,r,r1,r2,s,f,g,a,b,m,n,th,ph,r2p,x1,y1,z1,cosph;
    float ma,mb,mc,md,rx,d,rz,a1,b1,c1;
    
    ///////////////////////////////////////////////////////////////////////////
    //Mandelbulb
    ///////////////////////////////////////////////////////////////////////////
    #ifdef Mandelbulb

        r=length(z);
        th=atan(z.y,z.x)*Power;
        ph=asin(z.z/r)*Power;
        r2p=pow(r,Power);
        z.x=r2p*cos(ph)*cos(th);
        z.y=r2p*cos(ph)*sin(th);
        z.z=r2p*sin(ph);
        z+=c;

    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //Polynomial1
    ///////////////////////////////////////////////////////////////////////////
    #ifdef Polynomial1

        r=length(z);
        th=atan(z.y,z.x)*Power;
        ph=asin(z.z/r)*Power;
        r2p=pow(r,Power);
        z.x=r2p*cos(ph)*cos(th)+z.x+c.x;
        z.y=r2p*cos(ph)*sin(th)+z.y+c.y;
        z.z=r2p*sin(ph)+z.z+c.z;

    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //Polynomial2
    ///////////////////////////////////////////////////////////////////////////
    #ifdef Polynomial2

        r=length(z);
        th=atan(z.y,z.x)*Power;
        ph=asin(z.z/r)*Power;
        r2p=pow(r,Power);
        z.x=r2p*cos(ph)*cos(th)-z.x+c.x;
        z.y=r2p*cos(ph)*sin(th)-z.y+c.y;
        z.z=r2p*sin(ph)-z.z+c.z;

    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //TTA8
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA8
        
        
        //TTA8
        if (z.y==0.0 && z.z==0.0) {
            z= vec3(pow4(z.x,Power),0,0);
        } else {
            r1=z.y*z.y+z.z*z.z;
            s=inversesqrt(r1);
            r=sqrt(z.x*z.x+r1);
            f=acos(z.x/r)*Power;
            r=pow4(r,Power);
            z=vec3(r*cos(f),r*z.y*s*sin(f),r*z.z*s*sin(f));
        }
        
        
        /*
        //explicit power 3 - remember to change Power variable
        if (z.y==0.0 && z.z==0.0) {
            z= vec3(pow4(z.x,Power),0,0);
        } else {
            z = vec3( z.x*( z.x*z.x - 3*z.y*z.y - 3*z.z*z.z ), z.y*( 3*z.x*z.x - z.y*z.y - z.z*z.z ), z.z*( 3*z.x*z.x - z.y*z.y - z.z*z.z ) );
        }
        */

        /*
        //explicit power 4 - remember to change Power variable
        if (z.y==0.0 && z.z==0.0) {
            z= vec3(pow4(z.x,Power),0,0);
        } else {
            //z=vec3(pow2(z.x,4)+pow2(z.y,4)+pow2(z.z,4)+2*z.y*z.y*z.z*z.z-6*z.x*z.x*z.y*z.y-6*z.x*z.x*z.z*z.z,4*z.x*z.y*(z.x*z.x-z.y*z.y-z.z*z.z),4*z.x*z.z*(z.x*z.x-z.y*z.y-z.z*z.z));
            z=vec3(z.x*z.x*z.x*z.x+z.y*z.y*z.y*z.y+z.z*z.z*z.z*z.z+2*z.y*z.y*z.z*z.z-6*z.x*z.x*z.y*z.y-6*z.x*z.x*z.z*z.z,4*z.x*z.y*(z.x*z.x-z.y*z.y-z.z*z.z),4*z.x*z.z*(z.x*z.x-z.y*z.y-z.z*z.z));
        }
        */
        
        /*
        //explicit power 8 - remember to change Power variable
        if (z.y==0.0 && z.z==0.0) {
            z= vec3(pow2(z.x,Power),0,0);
        } else {
            f = pow2(z.x,8) + pow2(z.y,8) + pow2(z.z,8) + 4*z.y*z.y*pow2(z.z,6) + 4*z.z*z.z*pow2(z.y,6) + 6*pow2(z.y,4)*pow2(z.z,4) 
            - 28*pow2(z.x,6)*z.y*z.y - 28*pow2(z.x,6)*z.z*z.z - 28*pow2(z.y,6)*z.x*z.x - 28*pow2(z.z,6)*z.x*z.x
            + 70*pow2(z.x,4)*pow2(z.z,4) + 70*pow2(z.x,4)*pow2(z.y,4) - 84*z.x*z.x*pow2(z.y,4)*z.z*z.z - 84*z.x*z.x*z.y*z.y*pow2(z.z,4) + 140*pow2(z.x,4)*z.y*z.y*z.z*z.z;
        
            g = 8*z.x*z.y*( pow2(z.x,6) - pow2(z.y,6) - pow2(z.z,6) - 3*z.y*z.y*pow2(z.z,4) - 3*pow2(z.y,4)*z.z*z.z 
            + 7*z.x*z.x*pow2(z.z,4) + 7*z.x*z.x*pow2(z.y,4) - 7*pow2(z.x,4)*z.y*z.y - 7*pow2(z.x,4)*z.z*z.z + 14*z.x*z.x*z.y*z.y*z.z*z.z );
        
            h = 8*z.x*z.z*( pow2(z.x,6) - pow2(z.y,6) - pow2(z.z,6) - 3*z.y*z.y*pow2(z.z,4) - 3*pow2(z.y,4)*z.z*z.z 
            + 7*z.x*z.x*pow2(z.z,4) + 7*z.x*z.x*pow2(z.y,4) - 7*pow2(z.x,4)*z.y*z.y - 7*pow2(z.x,4)*z.z*z.z + 14*z.x*z.x*z.y*z.y*z.z*z.z );
        
            z = vec3( f, g, h );
        }
        */
        
        
        
        
        z+=c;
    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //TTA9 - fixed power 2 only
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA9Power2
        //change these 9 variables for other fractals
        float qa=0.0; 
        float qb=1.0;
        float qc=0.0;
        float qd=1.0;
        float qe=0.0;
        float qf=0.0;
        float qg=0.0;
        float qh=1.0;
        float qi=0.0;
        tmpz.x=z.x*(qa*z.x*z.x+qb*z.y*z.y+qc*z.z*z.z);
        tmpz.y=z.y*(qd*z.x*z.z+qe*z.x*z.y+qf*z.y*z.z);
        tmpz.z=z.z*(qg*z.x*z.y+qh*z.y*z.z+qi*z.x*z.z);
        z=tmpz;
        z+=c;
    #endif

    ///////////////////////////////////////////////////////////////////////////
    //TTA10
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA10
        if (z.y==0.0 && z.z==0.0) { 
            z= vec3(pow4(z.x,Power),0,0); 
        } else { 
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power-1.0); 
            r=pow4(r,Power-1.0); 
            //change m and n for other fractal shapes
            m=0.0; 
            n=1.0;
            a=m*(z.x*s*sin(f)+cos(f));
            b=n*(z.x*s*cos(f)+sin(f));           
            z=vec3(r*(z.x*cos(f)-sin(f)/s),r*z.y*(z.x*s*sin(f)+cos(f)),r*z.z*(a+b));
        }
        z+=c;
    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //TTA11
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA11
        if (z.y==0.0 && z.z==0.0) { 
            z= vec3(pow(z.x,Power),0,0); 
        } else { 
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power-1.0); 
            r=pow(r,Power-1.0); 
            z=vec3(r*(z.x*cos(f)-sin(f)/s),r*z.y*z.x*s*sin(f),r*z.z*z.x*s*cos(f)); 
        }
        z+=c;
    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //TTA12
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA12
        if (z.y==0.0 && z.z==0.0) { 
            z= vec3(pow(z.x,Power),0,0); 
        } else { 
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power-1.0); 
            r=pow(r,Power-1.0); 
            //change a and b for other fractal shapes
            a=30;
            b=60;
            z=vec3(r*z.x*sin(f),r*z.y*z.x*s*sin(f+a),r*z.z*z.x*s*sin(f+b));
        }
        z+=c;
    #endif

    ///////////////////////////////////////////////////////////////////////////
    //TTA13
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA13
        if (z.y==0.0 && z.z==0.0) { 
            z= vec3(pow(z.x,Power),0,0); 
        } else { 
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power-1.0); 
            r=pow(r,Power-2.0); 
            //change a and b for other fractal shapes
            a=30;
            b=60;
            z=vec3(r*z.x*z.y*cos(f),r*z.y*z.z*sin(f+a),r*z.z*z.x*sin(f+b)); 
        }
        z+=c;
    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //TTA13 Radians
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA13Radians
        if (z.y==0.0 && z.z==0.0) { 
            z= vec3(pow4(z.x,Power),0,0); 
        } else { 
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power-1.0); 
            r=pow4(r,Power-2.0); 
            //change a and b for other fractal shapes
            a=30;
            b=60;
            //f=radians(f);
            a=radians(a);
            b=radians(b);
            z=vec3(r*z.x*z.y*cos(f),r*z.y*z.z*sin(f+a),r*z.z*z.x*sin(f+b)); 
        }
        z+=c;
    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //TTA14
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA14
        if (z.y==0.0 && z.z==0.0) { 
            z= vec3(pow4(z.x,Power),0,0); 
        } else { 
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power-1.0); 
            r=pow4(r,Power-1.0); 
            //change a for other fractal shapes
            a=45;
            z=vec3(r*(z.x*cos(f)-sin(f)/s),r*z.y*abs(sin(f+a))*(z.x*s*sin(f)+cos(f)),r*z.z*(z.x*s*sin(f)+cos(f))); 
        }
        z+=c;
    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //TTA15
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA15
        if (z.y==0.0 && z.z==0.0) { 
            z= vec3(pow2(z.x,Power),0,0); 
        } else { 
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power-1.0); 
            r=pow2(r,Power-1.0); 
            //change a for other fractal shapes
            a=45;
            z=vec3(r*cos(f),r*sin(f),r*sin(f+a));
        }
        z+=c;
    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //TTA16
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA16
        if (z.y==0.0 && z.z==0.0) { 
            z= vec3(pow2(z.x,Power),0,0); 
        } else { 
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power-1.0); 
            r=pow2(r,Power-1.0); 
            //change a for other fractal shapes
            a=0;
            z=vec3(r*cos(z.x),r*sin(z.y),r*sin(z.z+a)); 
        }
        z+=c;
    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //TTA17
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA17
        if (z.y==0.0 && z.z==0.0) { 
            z= vec3(pow2(z.x,Power),0,0); 
        } else { 
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power-1.0); 
            r=pow2(r,Power-1.0); 
            //change a for other fractal shapes
            //a = 0.5236 and 0.7854
            a=0.7854;
            z=vec3(r*cos(f),r*s*z.y*sin(f),r*s*z.z*sin(f+a));
        }
        z+=c;
    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //TTA18
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA18
        if (z.y==0.0 && z.z==0.0) { 
            z= vec3(pow2(z.x,Power),0,0); 
        } else { 
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power-1.0); 
            r=pow2(r,Power-1.0); 
            m=1/sqrt(z.x*z.x+z.y*z.y);
            //change a for other fractal shapes
            //a = 0.5236 and 0.7854
            a=0.7854;
            z=vec3(r*cos(f),r*s*z.y*sin(f),r*m*z.z*sin(f+a));
        }
        z+=c;
    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //TTA19
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA19
        if (z.y==0.0 && z.z==0.0) { 
            z= vec3(pow2(z.x,Power),0,0); 
        } else { 
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power-1.0); 
            r=pow(r,Power-1.0); 
            m=inversesqrt(z.x*z.x+z.y*z.y);
            n=inversesqrt(z.x*z.x+z.z*z.z);
            //change a for other fractal shapes
            //a = 0.5236 and 1.5708
            a=1.5708;
            z=vec3(r*s*z.x*cos(f),r*n*z.y*sin(f),r*m*z.z*sin(f+a));
        }
        z+=c;
    #endif

    ///////////////////////////////////////////////////////////////////////////
    //TTA20Power8
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA20Power8
        if (z.y==0.0 && z.z==0.0) { 
            z=vec3(pow2(z.x,Power),0,0); 
        } else { 
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power); 
            r=pow2(r,Power); 
            
            //the following are explicit power 8
            //make sure the Power variable is set to 8
            
            //version 1
            //h=8*(pow2(z.x,8)-4*pow2(z.x,7)*z.y+6*pow2(z.x,6)*z.z*z.z-28*pow2(z.x,5)*pow2(z.y,3)+70*pow2(z.x,4)*pow2(z.z,4)-28*pow2(z.x,3)*pow2(z.y,5)+6*z.x*z.x*pow2(z.z,6)-4*z.x*pow2(z.y,7)+pow2(z.z,8));
            //h=8*(z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.x-4*z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.y+6*z.x*z.x*z.x*z.x*z.x*z.x*z.z*z.z-28*z.x*z.x*z.x*z.x*z.x*z.y*z.y*z.y+70*z.x*z.x*z.x*z.x*z.z*z.z*z.z*z.z-28*z.x*z.x*z.x*z.y*z.y*z.y*z.y*z.y+6*z.x*z.x*z.z*z.z*z.z*z.z*z.z*z.z-4*z.x*z.y*z.y*z.y*z.y*z.y*z.y*z.y+z.z*z.z*z.z*z.z*z.z*z.z*z.z*z.z);

            //version 2
            //h=pow2(z.x,8)-pow2(z.x,7)*z.y+pow2(z.x,6)*z.z*z.z-pow2(z.x,5)*pow2(z.y,3)+pow2(z.x,4)*pow2(z.z,4)-pow2(z.x,3)*pow2(z.y,5)+z.x*z.x*pow2(z.z,6)-z.x*pow2(z.y,7)+pow2(z.z,8);
            //h=z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.x-z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.y+z.x*z.x*z.x*z.x*z.x*z.x*z.z*z.z-z.x*z.x*z.x*z.x*z.x*z.y*z.y*z.y+z.x*z.x*z.x*z.x*z.z*z.z*z.z*z.z-z.x*z.x*z.x*z.y*z.y*z.y*z.y*z.y+z.x*z.x*z.z*z.z*z.z*z.z*z.z*z.z-z.x*z.y*z.y*z.y*z.y*z.y*z.y*z.y+z.z*z.z*z.z*z.z*z.z*z.z*z.z*z.z;

            //version 3
            //h=pow2(z.x,8)-pow2(z.x,7)*z.y+pow2(z.x,6)*z.z*z.z-pow2(z.x,5)*pow2(z.y,3)+pow2(z.x,4)*pow2(z.z,4)-pow2(z.x,3)*pow2(z.y,5)+z.x*z.x*pow2(z.z,6)-z.x*pow2(z.y,7);
            //h=z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.x-z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.y+z.x*z.x*z.x*z.x*z.x*z.x*z.z*z.z-z.x*z.x*z.x*z.x*z.x*z.y*z.y*z.y+z.x*z.x*z.x*z.x*z.z*z.z*z.z*z.z-z.x*z.x*z.x*z.y*z.y*z.y*z.y*z.y+z.x*z.x*z.z*z.z*z.z*z.z*z.z*z.z-z.x*z.y*z.y*z.y*z.y*z.y*z.y*z.y;

            //version 4
            //h=pow2(z.x,8)-pow2(z.x,7)*z.y+pow2(z.x,6)*z.z*z.z-pow2(z.x,5)*pow2(z.y,3)+pow2(z.x,4)*pow2(z.z,4)-pow2(z.x,3)*pow2(z.y,5)+z.x*z.x*pow2(z.z,6)-pow2(z.y,8);
            //h=z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.x-z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.y+z.x*z.x*z.x*z.x*z.x*z.x*z.z*z.z-z.x*z.x*z.x*z.x*z.x*z.y*z.y*z.y+z.x*z.x*z.x*z.x*z.z*z.z*z.z*z.z-z.x*z.x*z.x*z.y*z.y*z.y*z.y*z.y+z.x*z.x*z.z*z.z*z.z*z.z*z.z*z.z-z.y*z.y*z.y*z.y*z.y*z.y*z.y*z.y;
            
            //version 5
            h=8*z.x*z.z*(pow2(z.x,6)-pow2(z.y,6)-pow2(z.z,6)-3*z.y*z.y*pow2(z.z,4)-3*pow2(z.y,4)*z.z*z.z+7*z.x*z.x*pow2(z.z,4)-7*z.x*z.x*pow2(z.y,4)+7*pow2(z.x,4)*z.y*z.y-7*pow2(z.x,4)*z.z*z.z+14*z.x*z.x*z.y*z.y*z.z*z.z);
            //h=8*z.x*z.z*(z.x*z.x*z.x*z.x*z.x*z.x-z.y*z.y*z.y*z.y*z.y*z.y-z.z*z.z*z.z*z.z*z.z*z.z-3*z.y*z.y*z.z*z.z*z.z*z.z-3*z.y*z.y*z.y*z.y*z.z*z.z+7*z.x*z.x*z.z*z.z*z.z*z.z-7*z.x*z.x*z.y*z.y*z.y*z.y+7*z.x*z.x*z.x*z.x*z.y*z.y-7*z.x*z.x*z.x*z.x*z.z*z.z+14*z.x*z.x*z.y*z.y*z.z*z.z);
            
            z=vec3(r*cos(f),r*s*z.y*sin(f),h);
        
        }
        //z=abs(z);
        z+=c;
    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //TTA20
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA20
        if (z.y==0.0 && z.z==0.0) { 
            z=vec3(pow(z.x,Power),0,0); 
        } else { 
            
            //get the dodgy 8th power
            
            r1=z.y*z.y+z.z*z.z; 
            s=inversesqrt(r1); 
            r=sqrt(z.x*z.x+r1); 
            f=acos(z.x/r)*(Power); 
            r=pow(r,Power); 
                    
            //version 1
            //h=8*(pow2(z.x,8)-4*pow2(z.x,7)*z.y+6*pow2(z.x,6)*z.z*z.z-28*pow2(z.x,5)*pow2(z.y,3)+70*pow2(z.x,4)*pow2(z.z,4)-28*pow2(z.x,3)*pow2(z.y,5)+6*z.x*z.x*pow2(z.z,6)-4*z.x*pow2(z.y,7)+pow2(z.z,8));
            //h=8*(z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.x-4*z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.y+6*z.x*z.x*z.x*z.x*z.x*z.x*z.z*z.z-28*z.x*z.x*z.x*z.x*z.x*z.y*z.y*z.y+70*z.x*z.x*z.x*z.x*z.z*z.z*z.z*z.z-28*z.x*z.x*z.x*z.y*z.y*z.y*z.y*z.y+6*z.x*z.x*z.z*z.z*z.z*z.z*z.z*z.z-4*z.x*z.y*z.y*z.y*z.y*z.y*z.y*z.y+z.z*z.z*z.z*z.z*z.z*z.z*z.z*z.z);

            //version 2
            //h=pow2(z.x,8)-pow2(z.x,7)*z.y+pow2(z.x,6)*z.z*z.z-pow2(z.x,5)*pow2(z.y,3)+pow2(z.x,4)*pow2(z.z,4)-pow2(z.x,3)*pow2(z.y,5)+z.x*z.x*pow2(z.z,6)-z.x*pow2(z.y,7)+pow2(z.z,8);
            //h=z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.x-z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.y+z.x*z.x*z.x*z.x*z.x*z.x*z.z*z.z-z.x*z.x*z.x*z.x*z.x*z.y*z.y*z.y+z.x*z.x*z.x*z.x*z.z*z.z*z.z*z.z-z.x*z.x*z.x*z.y*z.y*z.y*z.y*z.y+z.x*z.x*z.z*z.z*z.z*z.z*z.z*z.z-z.x*z.y*z.y*z.y*z.y*z.y*z.y*z.y+z.z*z.z*z.z*z.z*z.z*z.z*z.z*z.z;

            //version 3
            //h=pow2(z.x,8)-pow2(z.x,7)*z.y+pow2(z.x,6)*z.z*z.z-pow2(z.x,5)*pow2(z.y,3)+pow2(z.x,4)*pow2(z.z,4)-pow2(z.x,3)*pow2(z.y,5)+z.x*z.x*pow2(z.z,6)-z.x*pow2(z.y,7);
            //h=z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.x-z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.y+z.x*z.x*z.x*z.x*z.x*z.x*z.z*z.z-z.x*z.x*z.x*z.x*z.x*z.y*z.y*z.y+z.x*z.x*z.x*z.x*z.z*z.z*z.z*z.z-z.x*z.x*z.x*z.y*z.y*z.y*z.y*z.y+z.x*z.x*z.z*z.z*z.z*z.z*z.z*z.z-z.x*z.y*z.y*z.y*z.y*z.y*z.y*z.y;

            //version 4
            //h=pow2(z.x,8)-pow2(z.x,7)*z.y+pow2(z.x,6)*z.z*z.z-pow2(z.x,5)*pow2(z.y,3)+pow2(z.x,4)*pow2(z.z,4)-pow2(z.x,3)*pow2(z.y,5)+z.x*z.x*pow2(z.z,6)-pow2(z.y,8);
            //h=z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.x-z.x*z.x*z.x*z.x*z.x*z.x*z.x*z.y+z.x*z.x*z.x*z.x*z.x*z.x*z.z*z.z-z.x*z.x*z.x*z.x*z.x*z.y*z.y*z.y+z.x*z.x*z.x*z.x*z.z*z.z*z.z*z.z-z.x*z.x*z.x*z.y*z.y*z.y*z.y*z.y+z.x*z.x*z.z*z.z*z.z*z.z*z.z*z.z-z.y*z.y*z.y*z.y*z.y*z.y*z.y*z.y;
            
            //version 5
            //h=8*z.x*z.z*(pow2(z.x,6)-pow2(z.y,6)-pow2(z.z,6)-3*z.y*z.y*pow2(z.z,4)-3*pow2(z.y,4)*z.z*z.z+7*z.x*z.x*pow2(z.z,4)-7*z.x*z.x*pow2(z.y,4)+7*pow2(z.x,4)*z.y*z.y-7*pow2(z.x,4)*z.z*z.z+14*z.x*z.x*z.y*z.y*z.z*z.z);
            h=8*z.x*z.z*(z.x*z.x*z.x*z.x*z.x*z.x-z.y*z.y*z.y*z.y*z.y*z.y-z.z*z.z*z.z*z.z*z.z*z.z-3*z.y*z.y*z.z*z.z*z.z*z.z-3*z.y*z.y*z.y*z.y*z.z*z.z+7*z.x*z.x*z.z*z.z*z.z*z.z-7*z.x*z.x*z.y*z.y*z.y*z.y+7*z.x*z.x*z.x*z.x*z.y*z.y-7*z.x*z.x*z.x*z.x*z.z*z.z+14*z.x*z.x*z.y*z.y*z.z*z.z);
            
            vec3 dodgyz=vec3(r*cos(f),r*s*z.y*sin(f),h);
            
            // get the correct Power-8
            r1=z.y*z.y+z.z*z.z;
            s=inversesqrt(r1);
            r=sqrt(z.x*z.x+r1);
            r1=r;
            f=acos(z.x/r)*(Power-8.0);
            r=pow(r,(Power-8.0));
            vec3 correctz=vec3(r*cos(f),r*s*z.y*sin(f),r*s*z.z*sin(f)); // get the correct (p-8)th power
            // combine the dodgy 8th power with the correct (p-8) power to get a dodgy p-th power
            z=TTA8product(dodgyz,correctz,r1,s);
        }
        z+=c;
    #endif

    ///////////////////////////////////////////////////////////////////////////
    //TTA21
    ///////////////////////////////////////////////////////////////////////////
    #ifdef TTA21
        Power=8; //power 8 only, initially
        if (z.y==0.0 && z.z==0.0) {
            z=vec3(pow4(z.x,Power),0.0,0.0);
        } else {
            z=vec3( pow4(z.x,7.0)*(z.y-z.z)+pow4(z.x,3.0)*z.y*z.y*pow4(z.z,3.0)-pow4(z.y,7.0),
                    pow4(z.y,5.0)*(3.0*z.x+5.0*pow4(z.z,4.0)-pow4(z.x,4.0))/z.z+pow4(z.z,4.0),
                    pow4(z.z,8.0)-pow4(z.z,5.0)*z.x*z.x*z.y-pow4(z.x,8.0));
            //z=z/c;
        }
        z+=c;
    #endif

    
    
    ///////////////////////////////////////////////////////////////////////////
    //Riemann - http://www.fractalforums.com/new-theories-and-research/revisiting-the-riemann-sphere-%28again%29/
    ///////////////////////////////////////////////////////////////////////////
    #ifdef Riemann
        r = sqrt(z.x*z.x+z.y*z.y+z.z*z.z);
        r1 = 1.0/r;
        z=z*r1;
        x1 = z.x/(1.0-z.z);
        y1 = z.y/(1.0-z.z);
        z1 = (r-1.5)*(1.0+x1*x1+y1*y1);
        x1 = x1 - floor(x1+0.5);
        y1 = y1 - floor(y1+0.5);
        z.x=4.0*x1;
        z.y=4.0*y1;
        z.z=z1;
    #endif

    ///////////////////////////////////////////////////////////////////////////
    //Msltoe - http://www.fractalforums.com/new-theories-and-research/juliabulbs-by-bending/
    ///////////////////////////////////////////////////////////////////////////
    #ifdef Msltoe
        //3 components of the triplex C
        ma=-0.8;
        mb=-0.15;
        mc=0.0;
        
        if (z.z>0.0) {
            md=1.0;
        } else { 
            md=-1.0;
        }
        z.z=abs(z.z);
        r=sqrt(z.z*z.z+z.y*z.y);
        z1 = (z.z*z.z-z.y*z.y)*r;
        y1 = (2.0*z.y*z.z)*r;
        z.z = z1+z.z; 
        z.y = y1+z.y;
        z.z = (z.z)*md;
  
        r = z.x*z.x+z.y*z.y+z.z*z.z;
        x1=(z.x*z.x-z.y*z.y)*(1.0-z.z*z.z/r);
        y1=(2.0*z.x*z.y)*(1-z.z*z.z/r);
        z1=-2.0*z.z*sqrt(z.x*z.x+z.y*z.y+0.25*z.z*z.z);
        z.x = x1+ma; 
        z.y = y1+mb;
        z.z = z1+mc;
   #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //Msltoe2 - http://www.fractalforums.com/theory/alternate-co-ordinate-systems/msg11688/#msg11688
    ///////////////////////////////////////////////////////////////////////////
    #ifdef Msltoe2
        r=z.x*z.x+z.y*z.y+z.z*z.z;
        r1=sqrt(r);
        z.x/=r1;
        z.y/=r1;
        z.z/=r1;
        if ((z.x==0)&&(z.z==0)) {
            th=0;
            ph = 0;
        } else {
            rx=z.x/(z.y-1);
            th=8*atan(2*rx,rx*rx-1);
            rz=z.z/(z.y-1);
            ph=8*atan(2*rz,rz*rz-1);
        }
        rx=sin(th)/(1+cos(th));
        rz=sin(ph)/(1+cos(ph));
        d=2/(rx*rx+rz*rz+1);
        a1=rx*d;
        b1=(rx*rx+rz*rz-1)*0.5*d;
        c1=rz*d;
        z.x=a+a1*r*r*r*r;
        z.y=b+b1*r*r*r*r;
        z.z=c+c1*r*r*r*r;
   #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //Kali1 - http://www.fractalforums.com/theory/mandelbulb-variant/
    ///////////////////////////////////////////////////////////////////////////
    #ifdef Kali1
        r=length(z);
        th=acos(z.z/r);
        ph=atan(z.y,z.x);
        th=th*Power;
        z=r*vec3(sin(th)*cos(ph),sin(ph)*sin(th),cos(th));
        //z=abs(z);
        th=acos(z.z/r);
        ph=atan(z.y,z.x);
        ph=ph*Power;
        float zr = pow(r,Power);
        z=zr*vec3(sin(th)*cos(ph), sin(ph)*sin(th), cos(th));        
        //z=abs(z);
        z+=c;
    #endif
    
    ///////////////////////////////////////////////////////////////////////////
    //Benesi1 - http://www.fractalforums.com/3d-fractal-generation/rendering-3d-fractals-without-distance-estimators/msg54192/#msg54192
    ///////////////////////////////////////////////////////////////////////////
    #ifdef Benesi1
        float sr23=sqrt(2./3.);
        float sr13=sqrt(1./3.);
        float nx=z.x*sr23-z.z*sr13;
        float sz=z.x*sr13 + z.z*sr23;
        float sx=nx;
        float sr12=sqrt(.5);
        nx=sx*sr12-z.y*sr12;             
        float sy=sx*sr12+z.y*sr12;
        sx=nx*nx;
        sy=sy*sy;
        float ny=sy;
        sz=sz*sz;
        r2=sx+sy+sz;
        if (r2!=0.) {                                       
            nx=(sx+r2)*(9.*sx-sy-sz)/(9.*sx+sy+sz)-.5;
            ny=(sy+r2)*(9.*sy-sx-sz)/(9.*sy+sx+sz)-.5;
            sz=(sz+r2)*(9.*sz-sx-sy)/(9.*sz+sx+sy)-.5;
        }
        sx=nx;
        sy=ny;
        nx=sx*sr12+sy*sr12;
        sy=-sx*sr12+sy*sr12; 
        sx=nx;
        nx=sx*sr23+sz*sr13;
        sz=-sx*sr13+sz*sr23;                //some things can be cleaned up
        sx=nx;
        float sx2=sx*sx;
        float sy2=sy*sy;                // will be switching code around later       
        float sz2=sz*sz;
        nx=sx2-sy2-sz2;
        float r3=2.*abs(sx)/sqrt(sy2+sz2);
        float nz=r3*(sy2-sz2);
        ny=r3*2.*sy*sz;
        z= vec3(nx,ny,nz);
    #endif

    ///////////////////////////////////////////////////////////////////////////
    //Benesi2 - http://www.fractalforums.com/3d-fractal-generation/rendering-3d-fractals-without-distance-estimators/msg54249/#msg54249
    ///////////////////////////////////////////////////////////////////////////
    #ifdef Benesi2
        //change magPower and manPower for other fractal shapes
        float magPower=2.0;
        float manPower=2.0;
    
        float sr23=sqrt(2./3.);
        float sr13=sqrt(1./3.);
        float nx=z.x*sr23-z.z*sr13;
        float sz=z.x*sr13 + z.z*sr23;   // sz rotated
        float sx=nx;
        float sr12=sqrt(.5);
        nx=sx*sr12-z.y*sr12;               //nx
        float sy=sx*sr12+z.y*sr12;  //sy rotated
        sx=nx;

        float rxyz=pow((sx*sx+sy*sy+sz*sz),magPower*.5);

        r1=sqrt(sy*sy+sz*sz);    
        float victor=atan(r1,abs(sx*Power))*magPower;        // Is it faster to use
        nx=(sx*sx+rxyz)*cos(victor)-.5;                // multiple variables 

        r1=sqrt(sx*sx+sz*sz);                        // for these to split
        victor=atan(r1,abs(sy*Power))*magPower;        // processes???
        float ny=(sy*sy+rxyz)*cos(victor)-.5;

        r1=sqrt(sx*sx+sy*sy);
        victor=atan(r1,abs(sz*Power))*magPower;
        sz=(sz*sz+rxyz)*cos(victor)-.5;

        sx=nx;
        sy=ny;

        nx=sx*sr12+sy*sr12;
        sy=-sx*sr12+sy*sr12; 
        sx=nx;
        nx=sx*sr23+sz*sr13;
        sz=-sx*sr13+sz*sr23;                //some things can be cleaned up
        sx=nx;

        rxyz=pow((sx*sx+sy*sy+sz*sz),manPower/2.);
        r1=sqrt(sy*sy+sz*sz);
        victor=atan(r1,sx)*manPower;
        float phi=atan(sz,sy)*manPower;
        sx=rxyz*cos(victor);
        r1=rxyz*sin(victor);
        sz=r1*cos(phi);
        sy=r1*sin(phi);
        z= vec3(sx,sy,sz);
    #endif

    ///////////////////////////////////////////////////////////////////////////
    //Decker http://www.fractalforums.com/mandelbulb-implementation/please-try-this-new-3d-mandelbrot-formula-animations-included/msg57037/#msg57037
    ///////////////////////////////////////////////////////////////////////////
    #ifdef Decker
        r=length(z);
        th=Power*acos(z.x/length(z.xy))*sign(z.y);
        ph=-Power*acos(z.x/length(z.xz))*sign(z.z);
        z=pow(r,Power-1.0)*vec3(r*vec3(cos(th)*cos(ph),sin(th),-cos(th)*sin(ph)));
        z+=c;
    #endif

}

//iterate the formula to determine if the passed point is inside the fractal
bool isinside(vec3 c){
    float lengthz;
    int itercount;
    z=c;
    
    for(int i=0;(i<maxiter);i++) {
        
        itercount=i;
        
        Iterate(z,c);
        
        #ifdef AmbientOcclusion
            if (length(z)<smallestorbit) smallestorbit=length(z);
        #endif

        lengthz=length(z);
        
        
        if (lengthz>Bailout) break;
    }
    
    if (itercount==maxiter-1) {
        inside=true;
        return true;
    } else {
        inside=false;
        return false;
    }
}
  
//walks the ray and sets dist to how far the fractal surface is
void BruteForceDistance(inout vec3 dist,in float startdistance){
    float s=0.0;
    float f=startdistance;
    float DEdist,r;
    
smallestorbit=10000;

    //step along the ray - break when inside the fractal
    for(int i=0;i<RaySteps;i++){
    
        f+=s;
        c=CameraPosition+RayDirection*f;

        if (isinside(c)==true) break;
        
        s+=stepsize;

        if (length(c)>Bailout) break; else dist=c-CameraPosition;

    }
}
  
void main(void){
    int xsamp,ysamp;
    float xstep,ystep,rtot,gtot,btot,mx,my,lastdistance,p2dist,p3dist,p4dist,p5dist,p6dist,p7dist;
    vec2 vPos;
    vec3 dist,CameraUpVector,CameraRotation,ViewPlaneNormal,u,v,vcv,scrCoord,SurfaceNormal,p1,p2,p3,p4,p5,p6,p7;
    vec3 N,T,B,L,rO,rD,Ntmp,n,n1,n2;
    float thisr,thisg,thisb,aspect,beta,alpha,amin,amax,bmin,bmax,awidth,bheight,xp,yp,fov,DiffuseFactor;
    vec3 eye,lookat,up,lightpos,lightpos2,diffuse,VectorToLight,E,NdotL;

    lightpos=vec3(5.0,-25.0,-15.0);
    lightpos2=-lightpos;
    
    lookat=vec3(0.0,0.0,0.0);
    eye=vec3(0.0,0.0,1.0)*CameraDistance;
    up=vec3(0.0,1.0,0.0);
    fov=35.0;
        
    //construct the basis
    N=normalize(lookat-eye);
    T=normalize(up);
    B=cross(N,T);
    aspect=resolution.x/resolution.y;
    beta=tan(fov*pidiv180)/2.0;
    alpha=beta*aspect;
    amin=-alpha;
    amax=alpha;
    bmin=-beta;
    bmax=beta;
    awidth=amax-amin;
    bheight=bmax-bmin;
    xstep=awidth/resolution.x;
    ystep=bheight/resolution.y;
    
    rtot=0;
    gtot=0;
    btot=0;
    

    for (xsamp=0;xsamp<samplepixels;xsamp++) {
        for (ysamp=0;ysamp<samplepixels;ysamp++) {
            
            //x and y locations
            //these are the coordinates the ray will go through in 3d space
            xp=(gl_FragCoord.x/resolution.x)*awidth-abs(amin)+(xstep*float(xsamp)/float(samplepixels))-xstep*0.5;
            yp=bheight-(gl_FragCoord.y/resolution.y)*bheight-abs(bmin)+(ystep*float(ysamp)/float(samplepixels))-ystep*0.5;

            //set ray direction vector
            rD=normalize(xp*T+yp*B+N);
            //ray origin - starts from the eye location
            rO=eye;
            //rotations
            Rotate(xrot,yrot,zrot,rO.x,rO.y,rO.z,0.0,0.0,0.0,rO.x,rO.y,rO.z);
            Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
            //light rotates with camera
            Rotate(xrot,yrot,zrot,lightpos.x,lightpos.y,lightpos.z,0.0,0.0,0.0,lightpos.x,lightpos.y,lightpos.z);
            
            CameraPosition=rO;
            RayDirection=rD;

            //older method based on user defined RaySteps
            stepsize=(max(Bailout,CameraDistance)*2.0/RaySteps);
            
            //new method that auto-calculates optimal precision step size
            //stepsize=(max(Bailout,CameraDistance)*2.0/1000000/pow(10.0,float(refinementsteps))/pow(10.0,float(samplepixels)));
            
            
            BruteForceDistance(dist,0);
            lastdistance=length(dist);
            
            if (inside==true){
                
            //Normal based color
                #ifdef Normal
                
                    p1=c;

                    //epsilon value
                    vec3 eps=vec3(0.001,0,0);

                    lastdistance=length(c-rO);
    
                    rD=normalize(xp*T+yp*B+N);
                    rD.x-=float(eps);
                    rO=eye;
                    Rotate(xrot,yrot,zrot,rO.x,rO.y,rO.z,0.0,0.0,0.0,rO.x,rO.y,rO.z);
                    Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
                    CameraPosition=rO;
                    RayDirection=rD;
                    BruteForceDistance(dist,lastdistance*0.95);
                    p2=c;
                
                    rD=normalize(xp*T+yp*B+N);
                    rD.x+=float(eps);
                    rO=eye;
                    Rotate(xrot,yrot,zrot,rO.x,rO.y,rO.z,0.0,0.0,0.0,rO.x,rO.y,rO.z);
                    Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
                    CameraPosition=rO;
                    RayDirection=rD;
                    BruteForceDistance(dist,lastdistance*0.95);
                    p3=c;

                    rD=normalize(xp*T+yp*B+N);
                    rD.y-=float(eps);
                    rO=eye;
                    Rotate(xrot,yrot,zrot,rO.x,rO.y,rO.z,0.0,0.0,0.0,rO.x,rO.y,rO.z);
                    Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
                    CameraPosition=rO;
                    RayDirection=rD;
                    BruteForceDistance(dist,lastdistance*0.95);
                    p4=c;
                
                    rD=normalize(xp*T+yp*B+N);
                    rD.y+=float(eps);
                    rO=eye;
                    Rotate(xrot,yrot,zrot,rO.x,rO.y,rO.z,0.0,0.0,0.0,rO.x,rO.y,rO.z);
                    Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
                    CameraPosition=rO;
                    RayDirection=rD;
                    BruteForceDistance(dist,lastdistance*0.95);
                    p5=c;

                    rD=normalize(xp*T+yp*B+N);
                    rD.z-=float(eps);
                    rO=eye;
                    Rotate(xrot,yrot,zrot,rO.x,rO.y,rO.z,0.0,0.0,0.0,rO.x,rO.y,rO.z);
                    Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
                    CameraPosition=rO;
                    RayDirection=rD;
                    BruteForceDistance(dist,lastdistance*0.95);
                    p6=c;
                
                    rD=normalize(xp*T+yp*B+N);
                    rD.z+=float(eps);
                    rO=eye;
                    Rotate(xrot,yrot,zrot,rO.x,rO.y,rO.z,0.0,0.0,0.0,rO.x,rO.y,rO.z);
                    Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);
                    CameraPosition=rO;
                    RayDirection=rD;
                    BruteForceDistance(dist,lastdistance*0.95);
                    p7=c;

                    vec3 grad;
                    grad.x=(p3.x*p3.x+p3.y*p3.y+p3.z*p3.z)-(p2.x*p2.x+p2.y*p2.y+p2.z*p2.z);
                    grad.y=(p5.x*p5.x+p5.y*p5.y+p5.z*p5.z)-(p4.x*p4.x+p4.y*p4.y+p4.z*p4.z);
                    grad.z=(p7.x*p7.x+p7.y*p7.y+p7.z*p7.z)-(p6.x*p6.x+p6.y*p6.y+p6.z*p6.z);
                    n=normalize(grad);
                    
                    diffuse.x=0.5;
                    diffuse.y=0.5;
                    diffuse.z=0.5;

                    //uncomment next 4 lines to shade the surface color based on the XYZ positions
                    //diffuse.x=float(abs(p1.x));
                    //diffuse.y=float(abs(p1.y));
                    //diffuse.z=float(abs(p1.z));
                    //diffuse/=3.0;

                    //uncomment next 4 lines to shade the surface color based on normal's XYZ components
                    //diffuse.x=float(abs(n.x));
                    //diffuse.y=float(abs(n.y));
                    //diffuse.z=float(abs(n.z));
                    //diffuse/=3.0;

                    //the vector to the first light
                    VectorToLight=normalize(lightpos-p1);
                    //the vector to the eye
                    E=normalize(eye-p1);
                    //the cosine of the angle between light and normal
                    NdotL=n*VectorToLight;
                    DiffuseFactor=NdotL.x+NdotL.y+NdotL.z;
                    //vec3 Reflected=lightpos-2.0*DiffuseFactor*n;
                    // compute the illumination using the Phong equation
                    //0.2 is ambient light - without it shadows are black
                    diffuse=diffuse*max(DiffuseFactor,0.1)*2.0; //scale the light intensity
                    rtot+=diffuse.x;
                    gtot+=diffuse.y;
                    btot+=diffuse.z;
                    
                    //the vector to the second light
                    VectorToLight=normalize(lightpos2-p1);
                    //the vector to the eye
                    E=normalize(eye-p1);
                    //the cosine of the angle between light and normal
                    NdotL=n*VectorToLight;
                    DiffuseFactor=NdotL.x+NdotL.y+NdotL.z;
                    //vec3 Reflected=lightpos-2.0*DiffuseFactor*n;
                    // compute the illumination using the Phong equation
                    //0.2 is ambient light - without it shadows are black
                    diffuse=diffuse*max(DiffuseFactor,0.1)*2.0; //scale the light intensity
                    rtot+=diffuse.x;
                    gtot+=diffuse.y;
                    btot+=diffuse.z;
                    
                                        
                #endif

                //XYZ to RGB mappping
                #ifdef XYZtoRGB
                    rtot+=float(abs(c.x));
                    gtot+=float(abs(c.y));
                    btot+=float(abs(c.z));
                #endif
                
                //XYZ color and distance shading
                #ifdef XYZtoRGBandDistance
                    rtot+=(1.0-abs(length(dist)/Bailout))-float(abs(c.x)/2);
                    gtot+=(1.0-abs(length(dist)/Bailout))-float(abs(c.y)/2);
                    btot+=(1.0-abs(length(dist)/Bailout))-float(abs(c.z)/2);
                #endif

                //distance shading
                #ifdef Distance
                    rtot+=(1.0-abs(length(dist)/Bailout));
                    gtot+=(1.0-abs(length(dist)/Bailout));
                    btot+=(1.0-abs(length(dist)/Bailout));
                #endif

                //normal based - causes 2x2 pixels
                #ifdef dFd
                    vec3 n=normalize(cross(dFdx(c),dFdy(c)));
                    rtot+=n.x;
                    gtot+=n.y;
                    btot+=n.z;
                #endif
                
            } else {
                //background color
                rtot+=0.1;
                gtot+=0.1;
                btot+=0.1;
            }
        }
    }
               
                #ifdef AmbientOcclusion
                    if (smallestorbit<minorbit) smallestorbit=minorbit;
                    if (smallestorbit>maxorbit) smallestorbit=maxorbit;
                    smallestorbit=(smallestorbit-minorbit)/(maxorbit-minorbit);
                    rtot*=smallestorbit;
                    gtot*=smallestorbit;
                    btot*=smallestorbit;
                #endif

    rtot=rtot/(samplepixels*samplepixels);
    gtot=gtot/(samplepixels*samplepixels);
    btot=btot/(samplepixels*samplepixels);

    glFragColor=vec4(rtot,gtot,btot,1.0);
    
}
