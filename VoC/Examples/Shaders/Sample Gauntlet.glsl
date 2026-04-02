#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tdSyW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// math
const float PI = 3.14159265359;
const float DEG_TO_RAD = PI / 180.0;
const float grad_step = 0.02;

const vec3 blue = vec3(0.0, 0.2, 0.5);
const vec3 red = vec3(1.0, 0.3, 0.4);
const vec3 green = vec3(0.8, 0.9, 0.8);
const vec3 ambient = vec3(0.1, 0.1, 0.1);

// All SDFs and math stuff from from : https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
// get ray direction
vec3 ray_dir( float fov, vec2 size, vec2 pos ) {
    vec2 xy = pos - size * 0.5;

    float cot_half_fov = tan( ( 90.0 - fov * 0.5 ) * DEG_TO_RAD );    
    float z = size.y * 0.5 * cot_half_fov;
    
    return normalize( vec3( xy, -z ) );
}

mat4 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat4(
        vec4(1, 0, 0, 0), 
        vec4(0, c, -s, 0),
        vec4(0, s, c, 0),
        vec4(0, 0, 0, 1));
}

mat4 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat4(
        vec4(0, 0, 1, 0), 
        vec4(c, -s, 0, 0),
        vec4(s, c, 0, 0),
        vec4(0, 0, 0, 1));
}

mat4 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat4(
        vec4(c, 0, s, 0), 
        vec4(0, 1, 0, 0),
        vec4(-s, 0, c, 0),
        vec4(0, 0, 0, 1));
}

float cubicPulse( float c, float w, float x )
{
    x = abs(x - c);
    if( x>w ) return 0.0;
    x /= w;
    return 1.0 - x*x*(3.0-2.0*x);
}

mat4 inverse_rot(mat4 mat) {
    return transpose(mat);
}

float almostIdentity( float x )
{
    return x*x*(2.0-x);
}

float pulse(float x) {
    return 2.f * sin((x) / 2.f);
}
float sdCappedCylinder( vec3 pos, float h, float r, float neg, inout mat4 transform, vec2 uv)
{
  transform = rotateX(neg * time) * rotateY(mix(-.2f, .2f, uv.x) * abs(sin(time)) * 2.f);
  vec3 p = ( transform * vec4(pos, 1.0)).xyz;
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float opRep( in vec3 p, in vec3 c, float neg, inout mat4 transform, vec2 uv)
{
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    return sdCappedCylinder(q, 0.15f, 0.15f, neg, transform, uv);
}

float dist_field(vec3 pos, inout mat4 t, vec2 uv) {
    float dist = 0.6f;
    mat4 pos_blue_t;
    mat4 neg_blue_t;
    mat4 pos_white_t;
    mat4 neg_white_t;
    
    float res;
    if (sin(time) < 0.f) {
        float blueLeft = opRep(pos + vec3(dist * 0.5, 0, 0), vec3(dist, dist, 0), 1.f, pos_blue_t, uv);
    float blueRight = opRep(pos - vec3(0, dist * 0.5, 0), vec3(dist, dist, 0), -1.f, neg_blue_t, uv);
        res = min(blueLeft, blueRight);
        if (res == blueLeft) {
        t = pos_blue_t;
    } else if (res == blueRight) {
        t = neg_blue_t;
        }
    } else {
        float whiteLeft = opRep(pos + vec3(dist *0.5f, -dist * 0.5f, 0), vec3(dist, dist, 0), -1.f, pos_white_t, uv);
        float whiteRight = opRep(pos + vec3(0, 0, 0), vec3(dist, dist, 0), 1.f, neg_white_t, uv);
        res = min(whiteLeft, whiteRight);
        if (res == whiteLeft) {
        t = pos_white_t;
    } else {
        t = neg_white_t;
    }
    }
    //res = min(blueLeft, blueRight);
   
    
    
    
    return res;
}

// get gradient in the world
vec3 gradient( vec3 pos, vec2 uv) {
    const vec3 dx = vec3( grad_step, 0.0, 0.0 );
    const vec3 dy = vec3( 0.0, grad_step, 0.0 );
    const vec3 dz = vec3( 0.0, 0.0, grad_step );
    vec3 col;
    mat4 transform;
    bool is_white;
    return normalize (
        vec3(
            dist_field( pos + dx, transform, uv) - dist_field( pos - dx, transform, uv),
            dist_field( pos + dy, transform, uv) - dist_field( pos - dy, transform, uv),
            dist_field( pos + dz, transform, uv) - dist_field( pos - dz, transform, uv)            
        )
    );
}

// ray marching
bool ray_marching( vec3 o, vec3 dir, inout float depth, inout vec3 n, vec2 uv) {
    float t = 0.0;
    float d = 10000.0;
    float dt = 0.0;
    mat4 transform;
    for ( int i = 0; i < 150; i++ ) {
        vec3 v = o + dir * t;
       
        d = dist_field( v, transform, uv);
        if ( d < 0.0001 ) {
            break;
        }
        dt = min( abs(d), 0.1 );
        t += dt;
        if ( t > depth ) {
            break;
        }
    }
    
    if ( d >= 0.0001 ) {
        return false;
    }
    
    t -= dt;
    for ( int i = 0; i < 4; i++ ) {
        dt *= 0.5;
        
        vec3 v = o + dir * ( t + dt );
        if ( dist_field( v, transform, uv) >= 0.001 ) {
            t += dt;
        }
    }
    
    depth = t;
    n = normalize( gradient( o + dir * t, uv) );
    //if (n.g > 0.9 && n.x < 0.001 && n.z < 0.001) n = vec3(1.0, 0.0, 0.0);
    vec3 obj_normal = (transform * vec4(n, 0.0f)).xyz;
    n = obj_normal;
    if (abs(n.y) > 0.6f ) {
        n = red;
    } else {
         n = sin(time) > 0.f ? green : blue;
    }
    return true;
    
}

//https://www.shadertoy.com/view/MsV3z3
float hash_2D(ivec2 c)
{
  int x = 0x3504f333*c.x*c.x + c.y;
  int y = 0xf1bbcdcb*c.y*c.y + c.x;
    
  return float(x*y)*(2.0/8589934592.0)+0.5;
}

//https://www.shadertoy.com/view/4tXyWN
float hash_IQ3( uvec2 x )
{
    uvec2 q = 1103515245U * ( (x>>1U) ^ (x.yx   ) );
    uint  n = 1103515245U * ( (q.x  ) ^ (q.y>>3U) );
    return float(n) * (1.0/float(0xffffffffU));
}

vec2 hash( vec2 x )
{
  return vec2(fract(x.x * 44389.f / 319.f), fract(x.y * x.y * 4209292.f  + 22.23f * x.x));
}

void main(void)
{
    
    // Normalized pixel coordinates (from 0 to 1)
    vec4 col = vec4(0.0f, 0.f, 0.f, 0.f);
    int numSamples = 1;
    for (int its = 0; its < numSamples; its++) {

        vec2 uv = gl_FragCoord.xy/resolution.xy;
        vec2 jitter = vec2(hash_2D(ivec2(gl_FragCoord.xy)), hash_IQ3(uvec2(gl_FragCoord.xy)));
        jitter /= 25.f;
        jitter = vec2(0);
        uv += jitter;
        // default ray dir
        // default ray origin
        vec3 eye = vec3( 0.0, 0.0, 10.f );
        //vec3 eye= vec3(uv.x, uv.y, -1.);
        vec3 dir = ray_dir( 45.0, resolution.xy, gl_FragCoord.xy );
        //dir = vec3(uv.x, uv.y, 0.) - ro;

         // screenPos can range from -1 to 1
        vec2 s_pos =  (2.0 * gl_FragCoord.xy - resolution.xy)  / resolution.y;

        //Orthographic projection from: https://www.shadertoy.com/view/ldjfzd
        // up vector
        vec3 up = vec3(0.0, 1.0, 0.0);

        // camera position
        vec3 c_pos = vec3(0.0, 0.0, 7.0);
        // camera target
        vec3 c_targ = vec3(0.0, 0.0, 0.0);
        // camera direction
        vec3 c_dir = normalize(c_targ - c_pos);
        // camera right
        vec3 c_right = cross(c_dir, up);
        // camera up
        vec3 c_up = cross(c_right, c_dir);
        // camera to screen distance
        float c_sdist = 1000.0;

        // compute the ray direction
        vec3 r_dir = normalize(c_dir);
        // ray progress, just begin at the cameras position
        vec3 r_prog = c_pos + c_right * s_pos.x + c_up * s_pos.y;

        //r_prog = vec3( 0.0, 0.0, 3.f );
        //r_dir = dir;
        // Output to screen
        float depth= 10000.f;
        vec3 normal;
        vec2 q = uv*6.0 + vec2(5.0,0.0);

        bool is_white = sin(time) > 0.f;
        if (ray_marching(r_prog, r_dir, depth, normal, uv)) {

            vec4 c= vec4(normal + ambient, 1.0);
            col += c;
            
        } else {
            vec4 c = vec4((is_white ? blue : green)+ambient, 1.0);
            col += c;
        }
    }
    
    col /= float(numSamples);
    glFragColor = col;
    
    
}
