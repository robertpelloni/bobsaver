#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/MddfR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// better filling variant of https://shadertoy.com/view/lsdBR7
// colored variant of https://shadertoy.com/view/MstBR7

// polylines must pass to corners and mid-side of brick.
// trying to release the last constraint here: https://www.shadertoy.com/view/lsdfR7

#define MM 0
float  CELL = 5.,                  // grid size vertically -> cell size
      RATIO = 2.,                  // brick length / brick width
      BEVEL = .2,                  // bevel width ( cell %  )
       GAP  = 0.;                  // inter brick gap ( cell % )

vec2  CYCLE = 0.*vec2(3,2);        // pattern repeat scale ( in #brick )

#define SHAPE 0                    // 0...6 : presets of shapes
#define ANIM  1                    // anim (for demo) 

#if SHAPE==0 
bool  BRICK = true;                // tiling or bricks
//bool  BRICK = false;             // tiling or bricks

// .---1---.---2---.
// |               |
// 3               3
// |               |
// .---2---.---1---.
// polylines must pass to corners and mid-side of brick.
vec2 polyline1[] = vec2[]( vec2(0,0), vec2(.25,.1), vec2(.75,-.1),vec2(1,0) );
vec2 polyline2[] = vec2[]( vec2(0,0), vec2(.25,.3), vec2(.5,.1), vec2(.3,0),vec2(.5,-.2), vec2(.75,-.3),vec2(1,0) );
vec2 polyline3[] = vec2[]( vec2(0,0), vec2(.1,-.25), vec2(0,-.4), vec2(-.5,-.5),vec2(-1.,-.3), vec2(-.8,-.2),vec2(-1.2,-.3), vec2(-.3,-.75),vec2(0,-1) );

#elif SHAPE==1

bool  BRICK = false;                // tiling or bricks
vec2 polyline1[] = vec2[]( vec2(0,0), vec2(.7,.3),vec2(1.3,-.3), vec2(2,0));
vec2 polyline2[1];
vec2 polyline3[] = vec2[]( vec2(0,0), vec2(-.3,-.6), vec2(0,-1));                          

#elif SHAPE==2

bool  BRICK = true;                // tiling or bricks
vec2 polyline1[] = vec2[]( vec2(0,0),vec2(.5,0),vec2(.43,-.33),vec2(.76,-.33),vec2(.7,0),vec2(1,0));
vec2 polyline2[] = vec2[]( vec2(0,0),vec2(.3,0),vec2(.23, .33),vec2(.56, .33),vec2(.5,0),vec2(1,0));
vec2 polyline3[] = vec2[]( vec2(0,0), vec2(0,-.4),vec2(-.33,-.33),vec2(-.33,-.66),vec2(0,-.6),vec2(0,-1));                          

#elif SHAPE==3

bool  BRICK = true;                // tiling or bricks
vec2 polyline1[] = vec2[]( vec2(0,0),vec2(.25,.2),vec2(.75,-.2),vec2(1,0));
vec2 polyline2[] = vec2[]( vec2(0,0),vec2(.25,.2),vec2(.75,-.2),vec2(1,0));
vec2 polyline3[] = vec2[]( vec2(0,0),vec2(.2,-.25),vec2(-.2,-.75),vec2(0,-1));

#elif SHAPE==4 

#define RATIO 1.
bool  BRICK = false;               // tiling or bricks
vec2 polyline1[] = vec2[]( vec2(0,0),vec2(.45,.25),vec2(.7,-.2),vec2(1,0));
vec2 polyline2[1];
vec2 polyline3[] = vec2[]( vec2(0,0),vec2(.25,-.45),vec2(-.2,-.7),vec2(0,-1));

#elif SHAPE==5 

bool  BRICK = true;               // tiling or bricks
vec2 polyline1[] = vec2[]( vec2(0,0),/*vec2(.2,.2), */vec2(.5,.3),vec2(1,0));
vec2 polyline2[] = vec2[]( vec2(0,0),/*vec2(.2,-.2),*/vec2(.5,-.3),vec2(1,0));
vec2 polyline3[] = vec2[]( vec2(0,0),vec2(-.4,-.5),vec2(0,-1));

#elif SHAPE==6 

bool  BRICK = true;               // tiling or bricks
vec2 polyline1[] = vec2[]( vec2(0,0),vec2(1,0));
vec2 polyline2[] = vec2[]( vec2(0,0),vec2(1,0));
vec2 polyline3[] = vec2[]( vec2(0,0),vec2(0,-.3),vec2(-.1,-.3),vec2(-.4,-.1),vec2(-.6,-.1),vec2(-.9,-.3),vec2(-1.,-.5),vec2(-.9,-.7),vec2(-.6,-.9),vec2(-.4,-.9),vec2(-.1,-.7),vec2(0,-.7),vec2(0,-1));

#endif

// std int hash, inspired from https://www.shadertoy.com/view/XlXcW4
vec3 hash3( uvec3 x )              // integer param
{
#   define scramble  x = ( (x>>8U) ^ x.yzx ) * 1103515245U // GLIB-C const
    scramble; scramble; scramble; 
    return vec3(x) / float(0xffffffffU);
}
vec3 hash3f(vec3 x) {              // float[0,1] param
    return hash3(uvec3( x * float(0xffffffffU) ) );
}

// distance to line
float line( vec2 p, vec2 a, vec2 b )
{
    p -= a; b -= a;
    float h = dot(p,b)/dot(b,b),   // projection index on line in [0,1]
         hs = clamp( h, 0., 1. ); 
    return length( p - b*hs );     // with round edges
  //return h==hs ? length( p - b*hs ) : 1e5; // without round edge
}

// signed distance to line
float sline( vec2 p, vec2 a, vec2 b , float s)
{
    p -= a; b -= a;
    float h = dot(p,b)/dot(b,b),   // projection index on line in [0,1]
         hs = clamp( h, 0., 1. ), l;
    p -= b*hs;                     // projection point on line
    l = length(p) * s* sign(p.x*b.y-p.y*b.x); // signed distance to line
    //return l;                   // with round edges
    return h==hs ? l : 1e5;       // without round edge
}

// distance to line + inside count
float lineC( vec2 p, vec2 a, vec2 b , inout int c)
{
    p -= a; b -= a;
    if ( p.y >= min(0.,b.y) && p.y < max(0.,b.y) 
        && b.y!=0. && b.x*p.y/b.y > p.x ) c++;
    float h = dot(p,b)/dot(b,b),    // projection index on line in [0,1]
         hs = clamp( h, 0., 1. ); 
    p -= b*hs;                      // projection point on line
    return length(p);               // with round edges
  //return h==hs ? length(p) : 1e5; // without round edge
}

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    vec2 R = resolution.xy; U /= R.y;          // normalized coordinates 
    O -= O;
    vec2 W = vec2(RATIO,1);                     // normalize in cells units
    U *= CELL/W;
#if !MM                                         // <- demo mode
     if (!BRICK && RATIO==2.) polyline1[polyline1.length()-1] = vec2(2,0);
    BEVEL = 1.5*CELL/R.y;                       // 1-pixel thick line
   #if ANIM                                     // animation
    for (int i=1; i<polyline1.length()-1; i++)
        polyline1[i] += .1*cos(time+float(i)+vec2(0,1.57));
    for (int i=1; i<polyline2.length()-1; i++)
        polyline2[i] += .1*cos(time+.3+float(i)+vec2(0,1.57));
    for (int i=1; i<polyline3.length()-1; i++)
        polyline3[i] += .05*cos(time+.6+float(i)+vec2(0,1.57));
   #endif
#endif
    float ofs = mod(floor(U.y),2.);
    if (BRICK) 
        U.x += .5*ofs;
    else ofs = 0.;
    vec2 S = W* (fract(U) - 1./2.);             // centered coords in a brick

    float d = 1e5,s,l, X = RATIO/2.;
    int c=0;
    
#define testline(O,T)                        \
        l =  lineC( S-O, _P, P , c) ;        \
        if ( l < d) d = l, D = T;
    
    vec2 P = polyline1[0], _P, D=vec2(0);
    float X0 = BRICK ? 0. : -X;
    for (int i=0; i < polyline1.length()-1; i++) {
        _P = P; P = polyline1[i+1];
        testline( vec2(-X, .5), vec2(  -ofs, 1) );
        testline( vec2(X0,-.5), vec2(float(BRICK)-ofs,-1) );
    }
    if (BRICK) {
    P = polyline2[0];
    for (int i=0; i < polyline2.length()-1; i++) {
        _P = P; P = polyline2[i+1];
        testline( vec2( 0, .5), vec2(1.-ofs, 1) );
        testline( vec2(-X,-.5), vec2(  -ofs,-1) );
    }}
    P = polyline3[0];
    for (int i=0; i < polyline3.length()-1; i++) {
        _P = P; P = polyline3[i+1];
        testline( vec2( X, .5), vec2( 1,0) );
        testline( vec2(-X, .5), vec2(-1,0) );
    }
    
    if ((c&1)==1) D = vec2(0);

    vec2 H = U+D+1.; // vec2 tile id
    H = CYCLE==vec2(0) ? H : mod(H,CYCLE);
    O += clamp ( (d-GAP)/BEVEL, 0., 1.); 
#if !MM    
    O.rgb *= hash3(uvec3(H,2));
#else  
 // O-=O;
    O.r =  hash3(uvec3(H,2)).r;
#endif    
    glFragColor=O;
}
