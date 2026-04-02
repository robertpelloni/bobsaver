#version 420

// original https://www.shadertoy.com/view/WtKGDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ray marching
const int max_iterations = 255;
const float stop_threshold = 0.0001;
const float grad_step = 0.01;
const float clip_far = 1000.0;

// math
const float PI = 3.14159265359;
const float DEG_TO_RAD = PI / 180.0;

float sdBox(vec3 p, vec3 b) {
  p = abs(p) - b;
  return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

float sdBox(vec2 p, vec2 b) {
  p = abs(p) - b;
  return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

float dsCapsule(vec3 point_a, vec3 point_b, float r, vec3 point_p)//cylinder SDF
{
     vec3 ap = point_p - point_a;
    vec3 ab = point_b - point_a;
    float ratio = dot(ap, ab) / dot(ab , ab);
    ratio = clamp(ratio, 0.f, 1.f);
    vec3 point_c = point_a + ratio * ab;
    return length(point_c - point_p) - r;
}

float sdCylinder( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

//--------------------------------------------------------
// distance function
float dist_sphere( vec3 pos, float r ) {
    return length( pos ) - r;
}

float dist_box( vec3 pos, vec3 size ) {
    return length( max( abs( pos ) - size, 0.0 ) );
}

//---------------------------------------------------------
float maxcomp(vec2 p) {
  return max(p.x, p.y);
}

//---------------------------------------------------------
float intersectSDF(float distA, float distB) {
    return max(distA, distB);
}

float unionSDF(float distA, float distB) {
    return min(distA, distB);
}

float differenceSDF(float distA, float distB) {
    return max(distA, -distB);
}
//----------------------------------------------------------

float sdCross(vec3 p) {
  float da = maxcomp(abs(p.xy));
  float db = maxcomp(abs(p.yz));
  float dc = maxcomp(abs(p.xz));
  return min(da, min(db, dc)) - 1.0;
}

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

// get distance in the world
float dist_field( vec3 pos ) {
    vec3 p;
    float d;
    
    d=999.9;
    p=pos;
        
     p.zx *= rotate(time);
       p.yx *= rotate(time * 0.5);

       
   
    float  distToCapsule =sdCylinder( p, vec2(1.0,1.0) );
    float  distToCapsule2 =sdCylinder( p.yzx, vec2(1.0,2.0) );
    d= unionSDF(distToCapsule,distToCapsule2);
    
    //d=distToCapsule;
    
    
    
  float s = 1.0;
  for (int m = 0; m < 4; m++) {
    vec3 a = mod(p * s, 2.0) - 1.0;
    s *= 3.0;
    vec3 r = 1.0 - 3.0 * abs(a);
    float c = sdCross(r) / s;
    d = max(d, c);
  }

  return d;
                        
    
        
    // union     : min( d0,  d1 )
    // intersect : max( d0,  d1 )
    // subtract  : max( d1, -d0 )
    //return max( d1, -d0 );
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
    vec3 eye = vec3( 0.0, 0.0, 5.0 );

    // rotate camera
    mat3 rot = rotationXY( vec2( time ) );
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

