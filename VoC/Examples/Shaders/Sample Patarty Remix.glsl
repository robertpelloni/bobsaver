#version 420

// original https://www.shadertoy.com/view/3lXGD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Patarty" by MrsBeanbag. https://shadertoy.com/view/wtXGWr
// 2019-04-26 12:45:38

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float plasma (in vec2 st) {
    float value = 4.0 * noise(st);
    return step(fract(value), 0.5);
}

// ray marching
const int max_iterations = 128;
const float grad_step = 0.0001;
const float clip_far = 10.0;

// math
const float PI = 3.14159265359;
const float DEG_TO_RAD = PI / 180.0;
float bounce = 0.0;

vec3 diffuse_colour = vec3(0.0);
vec3 specular_colour = vec3(0.0);
vec3 final_diff_colour = vec3(0.0);
vec3 final_spec_colour = vec3(0.0);

// iq's distance function
float sdSphere( vec3 pos, float r ) {
    return length( pos ) - r;
}

float sdUnion( float d0, float d1 ) {
    return min( d0, d1 );
}

float sdUnion_mat( float d0, float d1, vec3 cd, vec3 cs ) {
    if (d0 <= d1) {
        return d0;
    } else {
        diffuse_colour = cd;
        specular_colour = cs;
        return d1;
    }
}

float sdUnion_s( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float potato( vec3 p ) {
    float d0 = sdSphere( p + vec3(0.05,-0.5*sin(fract(time) * 13.2), 0.0), 0.45 );
    float d1 = sdSphere( p + vec3(0.0, 0.0, 0.1), 0.6 );
    float d2 = sdSphere( p + vec3(0.15 * cos(fract(time) * 6.6), 0.5, 0.0), 0.5 );
    
    float d = sdUnion_s( d0, d1, 0.4 );
    return sdUnion_s( d, d2, 0.4 );
}

float eyes( vec3 p ) {
    float e0 = sdSphere( p + vec3(0.15, -0.2, -0.42), 0.15 );
    float e1 = sdSphere( p + vec3(-0.15, -0.22, -0.42), 0.15 );
    return sdUnion(e0, e1);
}

// get distance in the world
float dist_field( vec3 p ) {
    vec3 pb = p;
    pb.y += -0.2 + bounce;
    diffuse_colour = vec3( 0.9, 0.7, 0.55 );
    specular_colour = vec3( 0.0 );

    float d = sdUnion_mat(potato(pb), eyes(pb), vec3(0.0), vec3(1.0));
    
    return d;
}

// get gradient in the world
vec3 gradient( vec3 p ) {
    const vec2 k = vec2(1,-1);
    return vec3( k.xyy*dist_field( p + k.xyy * grad_step ) + 
                 k.yyx*dist_field( p + k.yyx * grad_step ) + 
                 k.yxy*dist_field( p + k.yxy * grad_step ) + 
                 k.xxx*dist_field( p + k.xxx * grad_step ) );
}

// phong shading
vec3 shading( vec3 v, vec3 n, vec3 dir, vec3 eye) {
    vec3 light_pos   = vec3( 20.0, 20.0, 30.0 );
    vec3 light_color = vec3( 1.0 );

    float shininess = 40.0;
    
    vec3 vl = normalize( light_pos - v );
    vec3 ref = reflect( dir, n );
    
    float diffuse  = max( 0.0, dot( vl, n ) );
    float specular = max( 0.0, dot( vl, ref ) );
        
    specular = pow( specular, shininess );
        
    return light_color * final_diff_colour * diffuse
        + final_spec_colour * specular;
}

// ray marching
bool ray_marching( vec3 o, vec3 dir, inout float depth, inout vec3 n ) {
    float t = 0.0;
    for ( int i = 0; t < depth; i++ ) {
        vec3 v = o + dir * t;
        float d = dist_field( v );
        if ( d < grad_step || i >= max_iterations) {
            final_diff_colour = diffuse_colour;
            final_spec_colour = specular_colour;
            n = normalize( gradient( v ) );
            depth = t;
            return true;
        }
        t += d;
    }
    return false;
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
    vec3 eye = vec3( 0.0, 0.0, 3.5 );

    // rotate camera
    mat3 rot = rotationXY( vec2(0.0, sin(time) ) );
    //mat3 rot = rotationXY( ( mouse*resolution.xy.xy - resolution.xy * 0.5 ).yx * vec2( 0.01, -0.01 ) );
    dir = rot * dir;
    eye = rot * eye;

    bounce = fract(time*2.2)-0.5;
    bounce *= bounce;
    float boom = pow(cos(bounce), 25.);

    // ray marching
    float depth = clip_far;
    vec3 n = vec3( 0.0 );
    if (ray_marching( eye, dir, depth, n)) {
        // shading
        vec3 pos = eye + dir * depth;
    
        vec3 color = shading( pos, n, dir, eye );
        glFragColor = vec4( color, 1.0 );
        return;
    }
    
    vec2 st0 = vec2(.9, .5) - gl_FragCoord.xy/resolution.y;
    vec2 st = vec2(length(st0), atan(st0.x, st0.y));

    vec3 color = vec3((1.- boom));
    color.x += plasma(vec2(log(st.x), st.y + time*0.2)*3.0);
    color.y += plasma(vec2(log(st.x) * boom, st.y + time*0.1)*4.0);
    color.z += plasma(vec2(log(st.x), st.y - time*0.4)*5.0);

    glFragColor = vec4(color*0.5,1.0);
    return;
}
