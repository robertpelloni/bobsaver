#version 420

// original https://www.shadertoy.com/view/MlKSWR

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

mat4 rotationMatrix(vec3 axis, float angle)
{
axis = normalize(axis);
float s = sin(angle);
float c = cos(angle);
float oc = 1.0 - c;
return mat4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, 0.0,
oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c, 0.0,
0.0, 0.0, 0.0, 1.0);
}

// iq's distance function
float sdSphere( vec3 pos, float r ) {
    return length( pos ) - r;
}

float sdBox( vec3 p, vec3 b ) {
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdEllipsoid( in vec3 p, in vec3 r, float angle )
{
       float x = p.x;
    float y = p.y;
    x = x * cos(angle) - y * sin(angle);
    y = x * sin(angle) + y * cos(angle);
    vec3 p2 = vec3(x, y, p.z);
    return (length( p2/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

float sdTriPrism( vec3 p, vec2 h )
{
    float angle = PI * 0.5;
       float x = p.x;
    float z = p.z;
    x = x * cos(angle) - z * sin(angle);
    z = x * sin(angle) + z * cos(angle);
    vec3 p2 = vec3(x, p.y, z) ;
    vec4 p3 = vec4(p2, 1.0) * rotationMatrix(vec3(0.0, 0.0, 1.0), 0.90);
    p2 = vec3(p3.x, p3.y, p3.z);
    vec3 q = abs(p2);
    return max(q.z-h.y,max(q.x*0.866025+p2.y*0.5,-p2.y)-h.x*0.5);
}

// get distance in the world
float dist_field( vec3 pos ) {
    // ear left
    float v =  sdEllipsoid( pos + vec3(0.35, -0.3, 0.0), vec3(0.32, 0.22, 0.5), 0.5 );
       // ear right
    v = min(v, sdEllipsoid( pos + vec3(-0.35, -0.3, 0.0), vec3(0.32, 0.22, 0.5), -0.5 ));
    // flatten ears
    v = max(v, sdBox(pos, vec3(1.0, 1.0, 0.03)));
    // head
    v = min(v,sdSphere( pos, 0.3 ));
    v = min(v,sdSphere( pos + vec3(-0.14, -0.10, -0.20), 0.1 ));
    v = min(v,sdSphere( pos + vec3(0.14, -0.10, -0.20), 0.1 ));
    v = max(v, -sdTriPrism( pos + vec3(0.46, 0.18, -0.18), vec2(0.2, 0.3)));
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
    vec3 eye = vec3( 0.0, 0.0, 1.8 );

    // rotate camera
    mat3 rot = rotationXY( ( mouse*resolution.xy.xy - resolution.xy * 0.5 ).yx * vec2( 0.035, 0.02 ) );
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
