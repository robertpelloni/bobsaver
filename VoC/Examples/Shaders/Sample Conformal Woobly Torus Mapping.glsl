#version 420

// original https://www.shadertoy.com/view/ssdGzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//variant of https://shadertoy.com/view/sdd3R4

float  R0 = 20., R1 = 10.,                                    // large and small radii
        k = 2., // .9                                         // tile multiplier
        S = .4;
  #define T 0.
//#define T time
#define hue(v)  ( .6 + .6 * cos( v  + vec4(0,23,21,0)  ) )    // hue
#define rot(a)    mat2( cos(a+vec4(0,11,33,0)) )              // rotation                  
#define SQR(x)  ( (x)*(x) )

#define f(x)  DX * sqrt( 1. + SQR( S*6.*R1/R0*cos(6.*x+T) ) )  \
                 / mix( 1.,sin(6.*x+T), S );

float intX( float a ) {                                       // --- antiderivative of large circumference
    a = mod(a,6.2832);   // if you know a close form ( or good approx ), welcome ! :-)
 // return  2.808*a + .32  *(cos(6.*a) -1.); // fitting for S = .4, N=6  https://www.desmos.com/calculator/uepjhnpyap
 // return  1.85 *a + .129 *(cos(6.*a) -1.); //             S = .3 
 // return  1.40 *a + .057 *(cos(6.*a) -1.); //             S = .2 
 // return  1.143*a + .002 *(cos(6.*a) -1.); //             S = .1 
 // return  2.516*a + .45  *(cos(6.*a) -1.); //             S = .4, N=4 
    float x, s = 0., DX = 0.01;  // indeed, approx above better than DX=.01
    for( x = 0.; x < a; x += DX )
        s += f(x);
    return s += ( a - (x-DX) )/DX * f(x) ;                    // smooth integral
}

float a,b,r1,d; vec3 M;

float map(vec3 q) {                                           // --- shape
    q.yz *= rot( .5+6.*M.y),                                  // rotations
    q.xz *= rot( 2.-6.*M.x),
    a = atan(q.z,q.x),
    b = atan(q.y,d),
    r1 = R1* mix( 1., sin(6.*a+T) , S);
    return min( 9., length(vec2(d=length(q.xz)-R0,q.y)) - r1 ); // abs for inside + outside
}

vec3 normal( vec3 p ) { // --- smart gradient  https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
    float h = 1e-4; 
    vec2 k = vec2(1,-1);
    return normalize( k.xyy* map( p + k.xyy*h ) + 
                      k.yyx* map( p + k.yyx*h ) + 
                      k.yxy* map( p + k.yxy*h ) + 
                      k.xxx* map( p + k.xxx*h ) );
}

void main(void) { //WARNING - variables void (out vec4 O, vec2 U) {    // =================================== need changing to glFragColor and gl_FragCoord.xy
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;

    float t=9.;

    vec3  R = vec3(resolution.xy,1.0),
          D = normalize(vec3( U+U, -3.5*R.y ) - R ),          // ray direction
          p = 90./R, q;                                       // marching point along ray 
       // M =  mouse*resolution.xy.xyz/R -.5;
          M = vec3(8,4,0)/1e2*cos(time+vec3(0,11,0));
     
    for ( O=vec4(0) ; O.x < 1. && t > .01 ; O+=.01 )
        t = map(p), // also set a,b,r1,d
        p += .5*t*D;                                          // step forward = dist to obj          

    O = O.x > 1. ? vec4(0.) : exp(-3.*O/4.);                  // luminance (depth + pseudo-shading )
    if ( U.x < R.x/2. ) {                                     // left: conformal mapping
        a = intX(a); 
        float  r = R1/R0,
               ir = sqrt(1.-r*r);                   // antiderivative of 1/circonf(b) 
        b = .996*  2./ir* atan( (r-1.)/ir* tan(b/2.) );        
    } 
    
    if (O.x>0.) {
        O = hue( mod(floor(k*R0*a/6.283),floor(k*R0*intX(-1e-5)/6.283)) 
                + 17.*mod(round(k*R1*b/6.283), floor(k*R1)) ); // colored tiles 
        a = sin(k*R0*a/2.), b = cos(k*R1*b/2.);
        O *= sqrt( min(abs(a)/fwidth(a),1.) * min( abs(b)/fwidth(b),1.) );// tiles borders
        O *= .3 + .7*max(0.,dot(normal(p),vec3(.58))); // shading
    }
    if (int(U)==int(R/2.) ) O++;                              // vertical separator

    glFragColor = O;
}
