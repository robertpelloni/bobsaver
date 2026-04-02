#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ttXcRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of jorge2017a1 https://shadertoy.com/view/WlfyR2
// Fork of IQ https://www.shadertoy.com/view/4df3Rn
//   See here for more information on smooth iteration count:
//   http://iquilezles.org/www/articles/mset_smooth/mset_smooth.htm
// mouse.x controls the threshold to grey,    and mouse.y how the transition span.
     
#define N 1   // antialiasing oversampling = NxN
#define linstep(a,b,x) clamp( (x-(a))/(b-(a)),0.,1.)

float mandelbrot( vec2 c , out vec2 z,out vec2 _z )
{
#if 1 // --- optimizations : 
    float c2 = 16.* dot(c, c);
    // skip computation inside M1 - http://iquilezles.org/www/articles/mset_1bulb/mset1bulb.htm
    if( c2*c2 - 6.*c2 + 32.*c.x < 3. ) return 0.;
    // skip computation inside M2 - http://iquilezles.org/www/articles/mset_2bulb/mset2bulb.htm
    if( c2 + 32.*c.x + 16.  < 1. ) return 0.;
#endif

    float B = 256., l = 0.;
    z  = vec2(0);
    for( int i=0; i<512; i++, l++ ) {
       _z = z;
        z = mat2(z,-z.y,z.x) * z  + c;
        if( dot(z,z) >  B*B ) break;
    }
    if( l > 511. ) return 0.;
    
    return l -= log2(log2(length(z))/log2(B));  // smooth iteration count  
}

void main(void) //WARNING - variables void ( out vec4 O, vec2 U ) need changing to glFragColor and gl_FragCoord.xy
{
    vec4 O=glFragColor;
    float t = time, l,lc=0.,l0,AA=1.,a,_a,ac=0.,sac=0.,
       zoom = pow( .62 + .38*cos(.07*t) ,8.);   
    vec2 R = resolution.xy, z, _z,
         M = vec2(-3.75,2.25);

    // --- compute Mandelbrot
    
    int k = N*N/2;                              // NxN = subsampling. 
    for (int k=0; k<N*N; k++) {                 // oversampling
        vec2 sp = vec2(k%N,k/N)/float(N)-.5,    // subpixel pos
              p = ( 2.* (gl_FragCoord.xy+sp) - R ) / R.y,
              c =   vec2(-.745,.186) 
                  + zoom * p * mat2( cos( .15*(1.-zoom)*t + vec4(0,11,33,0) )) ;
          l = mandelbrot(c, z,_z);
          a = atan(z.y,z.x);  _a = atan(_z.y,_z.x); 
        ac +=          mix(_a,a,fract(l)); 
       sac += sin( 6.* mix(_a,a,fract(l)) ); 
        lc += l;
    } l = lc / float(N*N); ac /= float(N*N), sac /= float(N*N);
    
    l0=l;
    if (l0==0.) { O = vec4(.5,0,0,1); return; }
    l = 6.*ac;
    AA = linstep(M.x+M.y,M.x-M.y,log2(fwidth(l0)/float(N)));
    l = sin(l); O = vec4( sqrt( .5- clamp(l/fwidth(l),-.5,.5)* AA ) ); 
    O = vec4( sqrt( .5- sac* AA ) ); 
    glFragColor = O;
}
