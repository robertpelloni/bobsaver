#version 420

// original https://www.shadertoy.com/view/ltBBzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// inspired by http://www.ianislallemand.com/projects/design/generative-tilings

//#define S(v) smoothstep(3., 0., abs(v)/fwidth(v))
#define s(v) smoothstep(e, 0., v)                    // draw AA region v<0
#define S(v) s(abs(v))                               // draw AA line v=0
#define l(x,y,a,b) dot( vec2(x,y), normalize(vec2(a,b)) ) // line equation
#define L(x,y,a,b) S(l(x,y,a,b))                     // draw line equation
//#define P(x,y,a,b) s(l(x,y,a,b))                   // draw region under line
#define P(x,y,a,b) step(l(x,y,a,b),0.)               // draw region under line

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    U *= 10./resolution.y;
    float h = (sqrt(3.)+1.)/2., 
          c = sqrt(3.)-1., r=h+c/2., // NB: r = sqrt(3)
          e =  15./resolution.y, b, i,v;
    vec2 T = mod(U, r+r)-r, V = abs(T);              // first tile in bricks
                                                     // center = 1 supertile, corners = 1/4 neighboor supertiles

    O.r = P( V.x, V.y-h, -(c/2.-h), r );             // id 0-7 in supertile
    O.g = P( V.x-c/2., V.y, -sqrt(3.), 1 );
    i = step(.5,O.r) + 2.*step(.5,O.g);
    O.b = float(    (i==1. && T.y>0.)                // <><> not antialiased
                 || (i==3. && T.x>0.)                // -> re#def P()
                 || (i==0. && T.x>0.)
                 || (i==2. && T.y>0.)  );

    U = floor(U/(r+r))* 2.;                          // supertile id
    if (O.r==0.) U += sign(T);
    //O = vec4(U,0,0)/4.;

    i = (O.r + 2.*O.g + 4.*O.b) + 8.*(U.x + 12.*U.y); // tile id
  //i = (O.r + 2.*O.g + 4.*O.b)*8.1 +(U.x + 12.*U.y); 
  //i = O.r + 1.7*O.g + 4.3*O.b + 8.7* (U.x + 12.7*U.y);
    O = .6 + .6 * cos( i  + vec4(0,23,21,0)  );      // -> color
    O *= .4+.6*fract(1234.*sin(43.*i));

    b = float(  S(V.x)   * step(h,V.y)               // tiles border
              + S(r-V.x) * step(V.y,c/2.) 
              + L( V.x, V.y-h, -(c/2.-h), r )
              + S(V.y)   * step(V.x,c/2.)
              + S(r-V.y)  * step (r-V.x,c/2.)
              + L( V.x-c/2., V.y, -sqrt(3.), 1 )
             );
    O *= 1.-b;                                      // draw border           
    glFragColor=O;
}

/*  O = vec4(   ( V.x < e && V.y > h ) 
             || ( V.x > r-e &&  V.y < c/2. )
             || abs((V.y-h)*r-(c/2.-h)*V.x) < e
             || ( V.x < c/2. && V.y < e )
             || ( V.x > r-c/2. && V.y > r-e )
             || abs(V.y - (V.x-c/2.)*sqrt(3.)) < e
            );
*/
