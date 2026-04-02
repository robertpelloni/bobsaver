#version 120

// original https://www.shadertoy.com/view/MtyGzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float pos_dist;
vec3 normal;
int sphere_hit; //which sphere did the ray hit
vec3 sphere_hit_point;

vec4 test_sphere( vec4 sphere, vec3 ray ) {
    
    vec3 r2s = ray * dot( sphere.xyz, ray );
    vec3 near2s = r2s - sphere.xyz;
    
    vec4 rgbz = vec4( 0, 0, 0, 0 );
    
    if( length( near2s ) < sphere.w ) {
        vec3 r0s = r2s - ray * sqrt(  pow( sphere.w, 2. ) - pow( length( near2s ), 2. )  );
        normal=normalize( r0s - sphere.xyz );
        sphere_hit_point=r0s;
        float l1 = 0.2-0.8*dot( ray, normal );
        vec3 c = vec3( 1, 1, 1 ) * pow( l1, 1.5 ) * ( 1.0 - smoothstep( abs(pos_dist), abs(pos_dist*1.5), sphere.z ) );
        rgbz = vec4( c, length( r0s ) );
    }
    
    return rgbz;
}
   
void main(void)
{
    float t = 0.0;//time; // uncomment for rotating display
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 ar = vec2( 1, resolution.y / resolution.x );
    
    vec3 ray = normalize( vec3( ( uv - .5 ) * ar, 1 ) );
    
    vec3 v = normalize( vec3( cos( 0.7*t ), sin ( 1.2*t ), cos( 2.0*t ) ) );
    float t2 = t + 0.05;
    vec3 dv = normalize( ( normalize( vec3( cos( 0.7*t2 ), sin ( 1.2*t2 ), cos( 2.0*t2 ) ) ) - v ) / 0.05 );
    mat3 obj2cam = mat3( v, dv, cross( v, dv ) );
