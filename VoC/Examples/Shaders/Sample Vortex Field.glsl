#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/lljczz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define vort(p) vec2( -(p).y, (p).x ) / dot(p,p)      // field around a vortex
#define srnd(p) ( 2.* fract( 4e4* sin( 1e3* mat2(1,7.1,-5.1,2.3) * (p) )) -1. )

void main(void)
{
   vec2 U=gl_FragCoord.xy;
   #define JIT true                                      // jittering on or off
   float n = 20.,                                     // number of cells = 2n x 2n.Rx/Ry
        dt = 1./60.;                                  // is indeed dt * vortex strenght
    vec2 R = resolution.xy,
         u = (U+U-R)/R.y,                             // normalized coordinates
         M = mouse*resolution.xy.xy,                               // mouse control or autodemo
         m = length(M)>10. ? (M+M-R)/R.y : vec2(sin(time),.2*cos(time/3.71)),
         p = floor(u*n+.5) / n;                       // cell center (NB: we should deffered /n )
    vec4 O=glFragColor;
    O-=O;

    
 int N = 3;                                           // odd. Neighborhood size = NxN   
 for( int i=0; i<N*N; i++)                            // allows overflow to neighbor cell
 {
    vec2 P = p + vec2( i%N -N/2, i/N -N/2 ) / n;      // cell coordinate in neighborhood
    if (JIT) P += .2* srnd( round(P*n) ) / n ;        // jittering (round: for precision issues)
    vec2 X = u-P,                                     // local coordinate
         V =  vort(P-m) - vort(P+m);                  // field at P caused by vortex pair at +- m
    
    float l = length(V),
         r1 = dt * l, r2 = 2./R.y;                    // ellipse radii ~ ( |V|dt , 1 pixel )
    V /= l;
    mat2 Q = mat2( V / r1, vec2(-V.y,V.x) / r2 ) ;    // ellipse equation: lenght(Q.X) = const
                                                      // main axis = V
    O += smoothstep(2., 0., length(X*Q) ) ;           // display ellipse (use dot(l,l) for sharper)
  //O += max(0., 1. - .5* length(X*Q) ) ;           
 }

    glFragColor=O;

}
