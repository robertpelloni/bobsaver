#version 420

// original https://www.shadertoy.com/view/Mdlczj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ray marching
const int max_iterations = 512;
const float stop_threshold = 0.001;
const float grad_step = 0.02;
const float clip_far = 1000.0;

// math
const float PI = 3.14159265359;
const float DEG_TO_RAD = PI / 180.0;

// iq's distance function
float sdSphere( vec3 pos, float r ) {
    return length( pos ) - r;
}

float sdCross( vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  return min(min(max(d.x, d.y),max(d.x, d.z)),max(d.y, d.z));
}

float repCross( vec3 p, vec3 c, vec3 b )
{
  vec3 q = mod(p,c)-0.5*c;
  return sdCross( q, b );
}

float sdBox( vec3 p, vec3 b ) {
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

// get distance in the world
float dist_field( vec3 pos ) {
    float s = 0.6;
    float v = sdBox( pos, vec3(s) );
        
    for(int i = 0; i < 3; i++) {        
      v = max( v, -repCross( pos + vec3(s/1.0), vec3(s*2.0), vec3(s/3.0) ) );
      s /= 3.0;  
    }    
    //v = max( v, -repCross( pos + vec3(s/3.0), vec3(s*2.0/3.0), vec3(s/9.0) ) );

    return v;
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

// phong shading
vec3 shading( vec3 v, vec3 n, vec3 eye ) {
    // ...add lights here...
    
    float shininess = 16.0;
    
    vec3 final = vec3( 0.0 );
    
    vec3 ev = normalize( v - eye );
    vec3 ref_ev = reflect( ev, n );
    
    // light 0
    {
        vec3 light_pos   = vec3( 20.0, 20.0, 20.0 );
        vec3 light_color = vec3( 1.0, 0.7, 0.7 );
    
        vec3 vl = normalize( light_pos - v );
    
        float diffuse  = max( 0.0, dot( vl, n ) );
        float specular = max( 0.0, dot( vl, ref_ev ) );
        specular = pow( specular, shininess );
        
        final += light_color * ( diffuse + specular ); 
    }
    
    // light 1
    {
        vec3 light_pos   = vec3( -20.0, -20.0, -20.0 );
        vec3 light_color = vec3( 0.3, 0.7, 1.0 );
    
        vec3 vl = normalize( light_pos - v );
    
        float diffuse  = max( 0.0, dot( vl, n ) );
        float specular = max( 0.0, dot( vl, ref_ev ) );
        specular = pow( specular, shininess );
        
        final += light_color * ( diffuse + specular ); 
    }

    return final;
}

// ray marching
float ray_marching( vec3 origin, vec3 dir, float start, float end ) {
    float depth = start;
    for ( int i = 0; i < max_iterations; i++ ) {
        vec3 p = origin + dir * depth;
        float dist = dist_field( p ) / length( gradient( p ) );
        if ( abs( dist ) < stop_threshold ) {
            return depth;
        }
        depth += dist * 0.9;
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
    vec3 eye = vec3( 0.0, 0.0, 2.5 );

    // rotate camera
    mat3 rot = rotationXY( ( mouse*resolution.xy.xy - resolution.xy * 0.5 ).yx * vec2( 0.01, -0.01 ) );
    dir = rot * dir;
    eye = rot * eye;
    
    // ray marching
    float depth = ray_marching( eye, dir, 0.0, clip_far );
    if ( depth >= clip_far ) {
        glFragColor = vec4( 0.3, 0.4, 0.5, 1.0 );
        return;
    }
    
    // shading
    vec3 pos = eye + dir * depth;
    vec3 n = gradient( pos );
    glFragColor = vec4( shading( pos, n, eye ), 1.0 );
}
