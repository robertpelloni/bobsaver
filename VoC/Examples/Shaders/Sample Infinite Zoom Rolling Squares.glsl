#version 420

// original https://www.shadertoy.com/view/fl2Bzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a+vec4(0,pi/2.,-pi/2.,0)))

void main(void) //WARNING - variables void ( out vec4 O, vec2 u ) need changing to glFragColor and gl_FragCoord.xy
{ 
    float d = 9., r = 2./5., Z = 4.*(2.-.8*r),                // r: margin Z: fractal scale
         pi = 3.1415927, l=1., N = 8.,                        // N : fractal depth
          z = 1., a = pow(3.,z)-1.,                           // z = speed of zoom
          T = fract(time/30./z/z), t = 2.*pi*log(1.+a*T)/log(1.+a);// [0,2pi] with speed slowing as we zoom, so as to loop
    vec2  R = resolution.xy, D,
          U = ( 2.*gl_FragCoord.xy - R ) / R.y / Z, A;
 // if (u.x<10.) { O = vec4(u.y/R.y < t/(2.*pi),0,0,0); return; }   // test cycle
    
    // --- follow target location ( to offset camera there )
    vec2 P = vec2(0),L, D0 = vec2(1,0); D=D0;
    for(float i=0.; i<N; i++) {
        D  = D0 *=  rot(-t);                                  // rotate    
        if (sin(t)<0.) D=-D;                                  // frame change after each corner
        if (cos(t)*sin(t)<0.) D = vec2(-D.y,D.x); 
        P -= (1.-r)*vec2(-D.y,D.x)/l;                         // offset
        t *= 3.;   l *= Z;                                    // zoom
        P += 2.*floor( mod(t*2./pi,3.) - 1. ) *D/l;           // cycloïd-translate cube
        L = 1.41* cos( mod(t, pi/2.) + pi/4. + vec2(0,pi/2.) )/l;
        P -= L.x*D +L.y*vec2(-D.y,D.x);
     }
    t /= pow(3.,N);                                           // restore t
    
    // --- zoom and center on target
 // U *= pow(Z,-z*T);
    U *= pow(Z,-z*t/(2.*pi));
    U += P;

    // --- implicit draw of squares
    for(float i=0.; i<N; i++) {
        U *= rot(t);                                          // rotate
        A = abs(U); d = min(d, abs( max(A.x,A.y) -1.+r/2. )); // draw square
                                                              // --- iterate:
        D = vec2(1,0); a=0.;                                  // frame change after each corner
        if (sin(t)<0.) D=-D, a-=2.;
        if (cos(t)*sin(t)<0.) D = vec2(-D.y,D.x), a--;
        
        U += (1.-r)*vec2(-D.y,D.x), U *= Z;                   // offset & zoom
        t *= 3.;                                              // smaller is faster
        U -= 2.*floor( mod(t*2./pi,3.) - 1. ) *D;             // cycloïd-translate cube
        U += 1.41* cos( mod(t, pi/2.) + pi/4. + vec2(0,pi/2.) +pi/2.*a );
    }
    
   glFragColor = vec4( smoothstep( .8,-.8, (d-r/2.)/fwidth(d) )); // draw
   
}
