#version 420

// original https://www.shadertoy.com/view/WsjBDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ray marching
const int max_iterations = 255;
const float stop_threshold = 0.001;
const float grad_step = 0.01;
const float clip_far = 1000.0;

// math
const float PI = 3.14159265359;
const float DEG_TO_RAD = PI / 180.0;

// distance function
float dist_sphere( vec3 pos, float r ) {
    return length( pos ) - r;
}

float dist_ellipsoid( vec3 pos, vec3 r )
{
    float k0 = length( pos / r );
    float k1 = length( pos / ( r * r ) );
    return k0 * ( k0 - 1.0 ) / k1;
}

float dist_box( vec3 pos, vec3 size ) {
    return length( max( abs( pos ) - size, 0.0 ) );
}

float dist_torus( vec3 pos, vec2 t ) {
    vec2 q = vec2( length( pos.xy ) - t.x, pos.z );
    return length( q ) - t.y;
}

float smoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5 * ( d2 - d1 ) / k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k * h * ( 1.0 - h );
}

float smoothSubtract( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5 * ( d2 + d1 ) / k, 0.0, 1.0 );
    return mix( d2, -d1, h ) +  k * h * ( 1.0 - h );
}

float smoothIntersect( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5 * ( d2 - d1 ) / k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k * h * ( 1.0 - h );
}

// get distance in the world
float dist_field( vec3 pos ) {
    // ...add objects here...
    
    pos.xy = mod( pos.xy + vec2( 2.5 ), 5. ) - vec2( 2.5 );
    pos.z += 1.;
    
    if( pos.z <= 0.1 )
        pos.z = mod( pos.z + 1., 5. ) - 1.;
    
    float edge = .5 - .49 * cos( time );
    
    float sphere = dist_sphere( pos, 1. );
    
    float ellipsoid = dist_ellipsoid( pos, vec3( .5, .5, 1.2 ) );
    
    float box = dist_box( pos, vec3( 2.3, 2.3, 0. ) ) - 0.2 * edge;
    
    float torus = dist_torus( pos, vec2( 1.7, 0.3 ) );
    
    float result = sphere;
    result = smoothUnion( box, result, edge );
    result = smoothSubtract( ellipsoid, result, edge );
    result = smoothUnion( torus, result, edge );

    return result;
}

// phong shading
vec3 shading( vec3 v, vec3 n, vec3 eye ) {
    // ...add lights here...
    
    float shininess = 3.0;
    
    vec3 final = vec3( 0.0 );
    
    vec3 ev = normalize( v - eye );
    vec3 ref_ev = reflect( ev, n );
    
    // light 0
    {
        vec3 light_pos   = vec3( 20.0, 20.0, 20.0 );
        vec3 light_color = vec3( 0.5, 0.4, 0.3 );
    
        vec3 vl = normalize( light_pos - v );
    
        float diffuse  = max( 0.0, dot( vl, n ) );
        float specular = max( 0.0, dot( vl, ref_ev ) );
        specular = pow( specular, shininess );
        
        final += light_color * ( diffuse + specular ); 
    }
    
    // light 1
    {
        vec3 light_pos   = vec3( -20.0, -20.0, 20.0 );
        vec3 light_color = vec3( 0.3, 0.2, 0.1 );
    
        vec3 vl = normalize( light_pos - v );
    
        float diffuse  = max( 0.0, dot( vl, n ) );
        float specular = max( 0.0, dot( vl, ref_ev ) );
        specular = pow( specular, shininess );
        
        final += light_color * ( diffuse + specular ); 
    }

    return final;
}

// get gradient in the world
vec3 gradient( vec3 pos ) {
    const vec3 dx = vec3( grad_step, 0.0, 0.0 );
    const vec3 dy = vec3( 0.0, grad_step, 0.0 );
    const vec3 dz = vec3( 0.0, 0.0, grad_step );
    return normalize (
        vec3(
            dist_field( pos + dx ) - dist_field( pos - dx ),
            dist_field( pos + dy ) - dist_field( pos - dy ),
            dist_field( pos + dz ) - dist_field( pos - dz )            
        )
    );
}

// ray marching
float ray_marching( vec3 origin, vec3 dir, float start, float end ) {
    float depth = start;
    for ( int i = 0; i < max_iterations; i++ ) {
        float dist = dist_field( origin + dir * depth );
        if ( dist < stop_threshold ) {
            return depth;
        }
        depth += dist;
        if ( depth >= end) {
            return end;
        }
    }
    return end;
}

// get ray direction
vec3 ray_dir( float fov, vec2 size, vec2 pos ) {
    vec2 xy = pos - size * 0.5;

    float cot_half_fov = tan( ( 90.0 - fov * 0.5 ) * DEG_TO_RAD );    
    float z = size.y * 0.5 * cot_half_fov;
    
    return normalize( vec3( xy, -z ) );
}

// camera rotation : pitch, yaw
mat3 rotationXY( vec2 angle ) {
    vec2 c = cos( angle );
    vec2 s = sin( angle );
    
    return mat3(
        c.y      ,  0.0, -s.y,
        s.y * s.x,  c.x,  c.y * s.x,
        s.y * c.x, -s.x,  c.y * c.x
    );
}

void main(void)
{
    // default ray dir
    vec3 dir = ray_dir( 45.0, resolution.xy, gl_FragCoord.xy );
    
    // default ray origin
    vec3 eye = vec3( 0.0, 0.0, 10.0 );

    // rotate camera
    mat3 rot = rotationXY( vec2( 0.1 * time ) );
    dir = rot * dir;
    eye = rot * eye;
    
    // ray marching
    float depth = ray_marching( eye, dir, 0.0, clip_far );
    if ( depth >= clip_far ) {
        glFragColor = vec4( 0.0, 0.0, 0.0, 1.0 );
        return;
    }
    
    // shading
    vec3 pos = eye + dir * depth;
    vec3 n = gradient( pos );
    glFragColor = vec4( shading( pos, n, eye ), 1.0 );
}

