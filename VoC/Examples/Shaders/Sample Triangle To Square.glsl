#version 420

// original https://www.shadertoy.com/view/3dGfD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// v1 shader turned ghost ! https://www.shadertoy.com/view/WsGBD1

#define cross2(a,b) ( (a).x*(b).y - (b).x*(a).y )

// --- return bilinear coordinates of U in quad
// ( some special cases might not fixed, but enough for use in this shader )
vec2 Q(vec2 U, vec2 P00, vec2 P10, vec2 P01, vec2 P11) {
    vec2  bu = P10-P00, bv = P01-P00, c = P00-U,  a = P11-P01 -bu;
    float dv = -cross2(a,bv),
          av = cross2(a,bu), cv = cross2(a,c);  // v = av/d . u + cv/d

    if (dot(a,a)<1e-3)                          // parallelogram
        return - inverse(mat2(bu,bv)) * c;         
/*  if ( abs(dv) < 3e-2 ) {                     // trapeze
        U.x = -cv/av, 
        U.y = -( bu.y*U.x + c.y ) / ( bv.y + a.y*U.x ); 
        return U; 
    } // or swap yx in a, bu, bv, c
*/  av /= dv, cv /= dv;
    float  A = a.x*av, B = bu.x + a.x*cv + bv.x*av, C = bv.x*cv + c.x,
           D = B*B - 4.*A*C;
    if ( abs(A) < 1e-3 )                        // linear case
        U.x = -C/B; 
    else {
        if ( D < 0. ) return vec2(-1.);         // shouldnt be.
        U.x = ( -B + sign(B)*sqrt(D) ) *.5 / A; // bilinear coordinates
    }
    U.y = av * U.x + cv;
    return U;
}

// --- not normalized signed distance to quad
float sdQ(vec2 U, vec2 P00, vec2 P10, vec2 P01, vec2 P11) {
    U = Q( U, P00, P10, P01, P11);
    U = abs(U-.5)-.5;
    return max(U.x,U.y);  
}

#define S(a)   smoothstep( 1.5, 0., (a)/min(.1,fwidth(a)) )
//#define S(a)  ( v = (a)/fwidth(a), a < .1 ? smoothstep( 1.5, 0., v ) : 0. ) // .2+.2*sin(30.*(v)) )
#define CS(a)   vec2( cos(a), sin(a) )
#define rot(a)  mat2(cos( a + vec4(0,11,33,0)))

void main(void) //WARNING - variables void ( out vec4 O, vec2 u ) // ======================= need changing to glFragColor and gl_FragCoord.xy
{
    vec4 O = glFragColor;
    vec2 R = resolution.xy,
         U = 1.5* ( 2.*gl_FragCoord.xy - R ) /R.y + vec2(.6,.2);
         
    
#if 0 // test bilinear mapping 
    vec2 M = 1.5*mouse*resolution.xy.xy/R.y-.1;
    U = Q( U, vec2(0), vec2(1,0), vec2(.2,.8), vec2(M) ); // quad
  //U = Q( U, vec2(0), vec2(0)  , vec2(.2,.8), vec2(M) ); // triangle
    U = abs(U-.5); O *= max(U.x,U.y) < .5 ? 2. : .5;
    return;
#endif 
    
    float t = 3.142*(.5-.5*cos(time)), v,
          s = 1.52,
          z = .387, w = s/2.-z, a = .718, x = .5/tan(a), y = 1.-x;
    O-=O;
#define P(I,J,K)  O += S( sdQ( U, vec2(0), I, J, I+K ) )
  
    U *= rot(t);
    P( vec2(z,0), s/2.*CS(1.05), y*CS(a) );
    U.x -= z;
    U *= rot(-t);
    P( vec2(0), vec2(s/2.,0), x*CS(a) );
    U.x -= s/2.;
    U *= rot(-t);
    P( vec2(w,0),  .5*CS(1.57+a), s/2.*CS(2.1) );
    U.x -= w;
    U *= rot(2.1);
    U.x -= s/2.;
    U *= rot(-t);
    P( vec2(s/2.,0),  x*CS(1.05+a), s/2.*CS(2.1) );

    glFragColor = O;
}
