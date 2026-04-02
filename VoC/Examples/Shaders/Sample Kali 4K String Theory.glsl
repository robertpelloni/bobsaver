#version 420

// original https://www.shadertoy.com/view/tsScDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "String Theory" by LIA 

// 4kb intro released at Revision Online 2020
// Code by Kali. Music by Uctumi.

// In these hard times we must strengthen the strings that keep us attached to each other.

#define T        time
#define s(a,b,c) smoothstep(a,b,c)
#define R(a)     mat2( cos( a - vec4(0,33,11,0) ))
#define L        length
#define v        vec3

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec4 O = glFragColor;

    vec2 U = u / resolution.xy,        
          V = fract( (U+T) * vec2(23.342, 85.742) );     // uvh
          V += dot(V,V+23.45);
    float h = .5, H = fract(V.x * V.y),                  // hash*.5
          s = s(91., 1e2, T),                              // spl
          x = 1. - U.x * s - U.y * (1. + s),                     // [INJECT]
          f = s(115., 121., T),                            // fad
          t = -1.13 + T * .1 * (1. + f * .13),
          t2 = mod(T, 1.1968), g = 0., d = H * .3,                // td
          c = 3.1416,                                    // ( c = temporary local variable )
          r = 9.9 - 6.5 * s(.4,.9,sin(t+3.55+s*1.3));   // rad
    t < .0  ? t *= h : t; 
    c = mod(t/c, 3.);                                    // tl 
    c = s(.7, .75, c) + s(1.93, 2., c) + s(2.9, 3., c);        // tr
    c = mod( x + c, 3.) -h;                              // sel
    v S = step(-h, -v( c, abs(c-vec2(1,2))) );           // st*
    c = s(109.,112.,T),                                  // fin
        
    U.x += sin(U.y*5.+T*3.) *c*.1;
    U -= h;
    U.x *= 1.77; U *= 1. - (- s(48., 52., T) * 1.3 + s(52., 57., T) * 2. - s(57., 62., T) + s) * .4;
    s > .01 ? t += t : t;
    c > h   ? (S-=S, S.z++) : t;
 
    c = 1. + cos(t+t);
    v  C = v( 0, h - c * h + S.y * h, -6.5 +(2.7 - step(0.01,s) * h) *c -S.z * 1.5 ), p,        // ro
       D = v( U * R( sin(t * 4.) * h ) , .45); D /= L(D);       // dir
    mat2 r1 = R(t * (2.15 -s * .15) + .3),                         // rot*
         r2 = R(1. + s * .1),
         r4 = R(t * (1. - S.y * 2.));
    
    int i=0, j;
    for (; i++ < 130; ) {
        p = C +  d * D; 
        c = L(p) - r;                                    // sph
        p.xz *= r1;
        p.xy *= r2;
        p.yz *= R(s(47., 62., T) * -6.);
        p.yz *= R(S.z * T* 1.5 * step(s,.01));
        for ( j=0; j++ < 30; )
          ( p.x *= 1. - (S.x + S.z) / h) < 0. ? p.xy = -p.xy : u,
            p *= 1.17, p.x -=1.45 - S.z * .3,
            p.xz *= r4,
            p.yz *= R(1.);

        v l = v( L(max(v(0),abs(p)-2.)), L(p)-2., L(p.xz)-2. );
        c = max( c*S.y, dot(l, S) * .008 ); // pow(1.17, -30.) );
        if ( c < .002 && S.x > -S.y || d > 8. ) break;
        g +=   exp(-.04*d*d) * (S.x + S.z) * s(0., 1., d+S.z)
             + sin( d * .3 - t2*2.125 ) * S.y;
        d += max( .01, abs(c) )*.2; 
    }
    
    c = sin( t2*5.25*(2.-step(T,20.))*S.z +2.5*S.z* clamp(t,0.,1.) )
    * (h+S.z) * step(T,110.5) * (S.x+S.z);
    O.rgb =  mat3( 1.7,.7,h, h,.7,1.7, .7,1.7,h ) * S 
           * g*g/1e4 * ++c;
    
    if (d > 8.) {
        p = D + v( .3 , .4 , C.z*.1 +D.y );
        for( i=0; i++ < 8; )
            p = abs(p)/dot(p,p)-.75;
 
        O.rgb += dot(p,p)/2e2 *normalize(1.+abs(p));
    }
    U = mod(u,4.);
    O *= min(1.,T*.1) * (1.-s(120.,121.,T)) * (.7 + H * .3 ) *U.x*U.y/4.;

    glFragColor=O;
}
