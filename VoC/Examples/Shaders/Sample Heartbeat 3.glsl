#version 420

// original https://www.shadertoy.com/view/wtKyzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

        /////////////////////////////////////////////////////////////////
       //                                                            ////
      //  "simple marcher"                                          // //
     //                                                            //  //
    //  scene description goes here                               //   //
   //  scene description goes here                               //    //   
  //  scene description goes here                               //     //
 //                                                            //     //
////////////////////////////////////////////////////////////////     // 
//                                                            //    //
// Creative Commons Attribution-NonCommercial-ShareAlike      //   //
// 3.0 Unported License                                       //  //
//                                                            // //
// by Val "valalalalala" GvM 💃 2021                        ////
//                                                            ///
////////////////////////////////////////////////////////////////

float hash21( vec2 id ) {
    vec3 v = fract( id.xyx * vec3( .1991, .234, .133 ) );
    v += dot( v, v.yzx + vec3( 8.12, 2.34, 9.23 ) );
    return fract( v.x * ( v.y + v.z ) );
}

vec2 hearty( vec2 uv, float blur ) {
    float fatness = 1.33 - blur * .22;
    float up = -.1; 
    float roundness = .7 + .3 * blur;
    float steepness = .5 - .3 * blur;

    uv.x /= fatness;
    float y = steepness * ( pow( abs( uv.x ), roundness ) + up );
    uv.y -= y;
    return uv;
}

vec2 hearty( vec2 uv ) {
    return hearty( uv, .0 );
}

float heart( vec2 uv, float blur ) {
    float r = .22;    
    float d = length( hearty( uv, blur ) ); 
    blur *= r * 1.33;
    d = smoothstep( r + blur,r - blur - .1, d );
    return d;
}

float hearts( vec2 uv, float time ) {
    float t = cos(time * .33);
    vec2 trig = vec2( cos( t ), sin( t ) );
    uv *= mat2( trig.x, -trig.y, trig.y, trig.x );
    uv += 7. * cos(time * .01);
    
    float scale = 3.2 + 3. * sin(time*.1);
    
    // this has to happen before the fract! see bos 09
    uv.x += step(1., mod(uv.y*scale,2.0)) * 0.5;
    
    vec2 st = fract( uv * scale ) - .5;
    vec2 id = floor( uv * scale );
    
    float q = hash21( id );
    t = 4. * sin( 2. * time * q + q ) + q;
    trig = vec2( cos( t ), sin( t ) );   
    st *= mat2( trig.x, -trig.y, trig.y, trig.x );

    float blur = pow(cos(time * 2.),2.);
    
    return heart( st, blur );
}

///////////////////////////////////////////////////////////////////
// scene controls
#define RED vec3(1.,.1,.1)

// sometimes less is more...
#define GONZO_

////////////////////////////////////////////////////////////////
// handy constants

#define ZED   .0
#define PI    3.141592653589793 
#define PI2   6.283185307179586

////////////////////////////////////////////////////////////////
// ray marching

#define STEPS 99
#define CLOSE .001
#define FAR   99.
#define EPZ   vec2( ZED, CLOSE )

////////////////////////////////////////////////////////////////

#define FROM_SCREEN(uv)  ( ( 2. * uv - resolution.xy ) / resolution.y )
#define MAP_11_01(v)     ( v * .5 + .5 )

#define TRIG(a)    vec2( cos( a  * PI2 ), sin( a * PI2 ) )
#define MAX3(v)    max( v.x, max( v.y, v.z ) )
#define SUM3(v)    ( v.x + v.y + v.z )
#define MODO(v,f)  ( mod( v + .5 * f, f ) - .5 * f )

////////////////////////////////////////////////////////////////

mat2 rotate2d( float angle ) {
    vec2 t = TRIG( angle );
    return mat2( t.x, -t.y, t.y, t.x ); //c-ssc
}

////////////////////////////////////////////////////////////////

float lubDub() {
    float t = time * 4.;
    return abs(cos(t));
    
    float a = abs( cos( t ) );
    float l = 2.5;
    float m = -4.;
    float b = -abs( sin( t * l + m ) );
    float c = max( .0, a + b - .22 ) * 2.;
    return min( c, 1. );
}

float getDistance( vec3 p ) {

    #ifdef GONZO
        // this is all problematic.. may revisit it sometime....
        float scale = 10.;

        vec3 q = p + .5 * scale;
        vec3 f = mod(q,scale)  - .5 * scale;
        vec3 i = floor( q / scale );
    
        float proxy = length(f);
        if ( proxy > 2. ) return proxy;
    
        // offset x every other row
        float e = step( 1., mod( i.y, 2. ) ) * 2. - 1.;
        #if 1
            f.xy *= rotate2d( SUM3( i ) * .33 + time * .3 );
        #else
            // dance my pretties! dance!
            float o = .1 * abs( cos( time ) );
            f.x += e * scale * o;
            f.xy *= rotate2d(  SUM3( i ) * .33 + time * .3 );
            f.x += e * scale * o;
            f.z += e * scale * .25;
        #endif
    #else
        float proxy = length(p);
        if ( proxy > 4. ) return proxy;
    
        vec3 f = p;
        f.xz *= rotate2d( time * .13 );
    #endif
    
    /////////////////////////////////////////////////////////////
    
    f.xy = hearty( f.xy, - .4 );
    f.y+=.33;
    f.z *= ( 2. - ( f.y + 1. ) * .5 ) * 4.4;

    float radius = .66;
    float dub = abs(cos( (time+ f.y*.2 ) * 2.)) * .33;
    radius += dub;
    
    float d = length( f ) - radius;
    return d * .1;   // sort of suprisingly small fudge factor needed
}

////////////////////////////////////////////////////////////////

float march( vec3 a, vec3 ab ) {
    float d = .0;
    for ( int i = 0 ; i < STEPS ; i++ ) {
        vec3 b = a + d * ab;
        float n = getDistance( b );
        d += n;
        if ( abs( n ) < CLOSE || d > FAR ) break;
    }
    return d;
}

vec3 getDistances( vec3 a, vec3 b, vec3 c ) {
    return vec3( getDistance( a ), getDistance( b ), getDistance( c ) );
}

vec3 getNormal( vec3 p ) {
    return normalize( getDistance( p ) - 
        getDistances( p - EPZ.yxx, p - EPZ.xyx, p - EPZ.xxy )
    );
}

////////////////////////////////////////////////////////////////

// zab,xZup,yXz | zxy:ab,zup,xz
mat3 makeCamera( vec3 a, vec3 b, float roll ) {
    vec3 up = vec3( TRIG( roll ).yx, ZED );
    vec3 z = normalize( b - a );
    vec3 x = normalize( cross( z, up ) );
    vec3 y = normalize( cross( x, z ) );
    return mat3( x, y, z );
}

vec2 getMouse() {
    //return true||mouse*resolution.xy.z > .0
    //    ? FROM_SCREEN( mouse*resolution.xy.xy )
    //    : vec2( .44 * cos( time * .44 ), .33 )
    //;  
    return vec2(0.0);
}

////////////////////////////////////////////////////////////////

vec3 texaco( vec2 uv ) {
    return 2. * RED * ( .2 + hearts( uv, time * .5 ) );
}

vec3 colorHit( vec3 p ) {
    vec3 n = getNormal( p );
    //float q = max(n.x,max(n.y,n.z));
    float l = max( .2, pow( MAP_11_01( MAX3(n) ), 2. ) );
    
    n = pow( abs(n), vec3( 4. ) );
    n /= SUM3( n ); // pseudo normalize
    
    vec3 tX = texaco( MAP_11_01( p.yz ) );
    vec3 tY = texaco( MAP_11_01( p.xz ) );
    vec3 tZ = texaco( MAP_11_01( p.xy ) );

    return l * ( n.x * tX + n.y * tY + n.z * tZ );
}

vec3 colorMiss( in vec2 uv ) {
    return .4 * texaco( MAP_11_01( uv * .5 ) );
}

void main(void) {
    vec2 uv = FROM_SCREEN( gl_FragCoord.xy );
    float view = 4.;
    float zoom = 2.;

    ////
    
    vec2 m = getMouse();  
    vec2 t = view * TRIG( m.x );
    
    vec3 a = vec3( t.x, .0 * view * TRIG( m.y ).y, t.y );       
    vec3 b = vec3( ZED );
    vec3 ab = normalize( makeCamera( a, b, .0 ) * vec3( uv, zoom ) );

    ////

    float d = march( a, ab );
    float hit = step( d, FAR );

    vec3 p = hit * ( a + ab * d );
    vec3 color = mix( colorMiss( uv ), colorHit( p ), hit );
    
    float foginess = pow( d / FAR, .33 ) * hit;
    vec3 fog = vec3( .22, .11, .4 );
    color = mix( color, fog, foginess );
    
    glFragColor = vec4( color, 1. );
}
