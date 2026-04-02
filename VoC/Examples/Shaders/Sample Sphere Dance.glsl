#version 420

// original https://www.shadertoy.com/view/MtyGzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 test_sphere( vec4 sphere, vec3 ray ) {
    
    vec3 r2s = ray * dot( sphere.xyz, ray );
    vec3 near2s = r2s - sphere.xyz;
    
    vec4 rgbz = vec4( 0, 0, 0, 0 );
    
    if( length( near2s ) < sphere.w ) {
        vec3 r0s = r2s - ray * sqrt(  pow( sphere.w, 2. ) - pow( length( near2s ), 2. )  );
        float l1 = 0.2-0.8*dot( ray, normalize( r0s - sphere.xyz ) );
        vec3 c = vec3( 1, 0, 0 ) * pow( l1, 1.5 ) * ( 1.0 - smoothstep( 100., 180., sphere.z ) );
        rgbz = vec4( c, length( r0s ) );
    }
    
    return rgbz;
}

   
void main(void)
{
    float t = time;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 ar = vec2( 1, resolution.y / resolution.x );
    
    vec3 pos = vec3( 0, 0, -120 );
    vec3 ray = normalize( vec3( ( uv - .5 ) * ar, 1 ) );
    
    vec3 v = normalize( vec3( cos( 0.7*t ), sin ( 1.2*t ), cos( 2.0*t ) ) );
    float t2 = t + 0.05;
    vec3 dv = normalize( ( normalize( vec3( cos( 0.7*t2 ), sin ( 1.2*t2 ), cos( 2.0*t2 ) ) ) - v ) / 0.05 );
    mat3 obj2cam = mat3( v, dv, cross( v, dv ) );

    vec3 spheres[8];
    spheres[0] = vec3( -1,  1, -1 );
    spheres[1] = vec3( -1,  1,  1 );
    spheres[2] = vec3(  1,  1, -1 );
    spheres[3] = vec3(  1,  1,  1 );
    spheres[4] = vec3( -1, -1, -1 );
    spheres[5] = vec3( -1, -1,  1 );
    spheres[6] = vec3(  1, -1, -1 );
    spheres[7] = vec3(  1, -1,  1 );
    
    vec4 rgbz = vec4( 0, 0, 0, 10000.0 );
    
    for( int i = 0; i < 8; i++ ) {
        vec4 rgbz2 = test_sphere( vec4( 15.0 * spheres[ i ] * obj2cam - pos, 7 ), ray );
        if( length(rgbz2) > 0. && rgbz2.w < rgbz.w ) rgbz = rgbz2;
    }
    
    glFragColor = vec4( rgbz.xyz, 1 );
    
}
