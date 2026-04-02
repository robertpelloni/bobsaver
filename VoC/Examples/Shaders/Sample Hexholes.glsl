#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XlGBWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_FLOAT 3.402823466e+38
#define MIN_FLOAT 1.175494351e-38
#define MAX_DOUBLE 1.7976931348623158e+308
#define MIN_DOUBLE 2.2250738585072014e-308

// Indicate to 'repeat' function that we don't wish to
#define NEVER 1000000.0

/**
 * Common vectors
 */
const vec3 ORIGIN = vec3(0,0,0);
const vec3 X = vec3(1,0,0);
const vec3 Y = vec3(0,1,0);
const vec3 Z = vec3(0,0,1);

/**
 * Common color values
 */
const vec3 BLACK = vec3(0,0,0);
const vec3 WHITE = vec3(1,1,1);
const vec3 RED   = vec3(1,0,0);
const vec3 GREEN = vec3(0,1,0);
const vec3 BLUE  = vec3(0,0,1);
const vec3 YELLOW  = vec3(1,1,0);
const vec3 CYAN    = vec3(0,1,1);
const vec3 MAGENTA = vec3(1,0,1);

/**
 * For the given 2d screen position, figure out the ray vector
 */
vec3 calculateRay(vec2 res, vec2 screenPos, 
                  vec3 eye, vec3 look_at, vec3 up) {
    vec2 screen_pos = screenPos.xy / res.xy;
    float aspect = res.y / res.x;
    screen_pos -= 0.5;
    screen_pos.y *= aspect;
    vec3 look_center = normalize(look_at - eye);
    vec3 look_right = cross(up, look_center);
    vec3 look_up = cross(look_center, look_right);
        
    vec3 newRay = normalize(look_center + screen_pos.x * look_right + screen_pos.y * look_up);
    return newRay;
}

/*
 * Signed distance functions for object primitives
 */
float sphere(vec3 where, vec3 center, float radius) {
  return length(where - center) - radius;
}

//float torus_around_x(vec3 where, float major, float minor) {
    

float round_box( vec3 where, vec3 sizes, float roundness ) {
    return length(max(abs(where)-sizes,0.0))-roundness;
}

/**
 * centred modulo
 */
float cmod(float x, float r) {
    return mod(x + 0.5 *r, r) - 0.5 *r;
}

vec3 repeat(vec3 where, vec3 repetition) {

    return mod(where, repetition);
}
vec3 repeat_x(vec3 where, float r) {

    where.x = mod(where.x, r);
    return where;
}

#define PI 3.141592653589793
vec3 radial_symmetry_xz(vec3 where, float count) {
    float ang = mod(atan(where.x, where.z) + PI, 2.0 *PI /count);
    float r = length(where.xz);
    return vec3(r *cos(ang), where.y, r * sin(ang));
}

// polynomial smooth min (k = 0.1);
float blend( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 );
    return min( a, b ) - h*h*0.25/k;
}

int hash(int x) {
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = (x >> 16) ^ x;
    return x;
}

/**
 * Ray marching parameters for this scene
 */
#define MAX_STEPS  10000
#define MAX_DIST   100.0
#define EPSILON    0.001
#define STEP_RATIO 0.3

/**
 * object ids
 */
#define ID_FLOOR 1
#define ID_BIZZO 2
#define ID_TUBE  3
#define ID_CAP   4

#define COS_30    0.8660254037844387
#define HEX_EVEN  1.7320508075688772

float hex_hole_board(vec3 where, float hole_radius, 
                     float thickness, float rounding) {
    where = abs(where);
    float d_plane = where.y - thickness/2.0;
    
    vec3 first = where;
    first.z = abs(cmod(first.z, HEX_EVEN));
    // this is either gonna be 0 or 1 on alternating rows
    float odd_row_bump = floor(first.z / (0.5*COS_30));
    first.x -= 0.5 * odd_row_bump;
    first.z -= COS_30 * odd_row_bump;
    first.x = cmod(first.x, 1.0);
    float d_hole = length(first.xz) - hole_radius;

    float d_board = max(d_plane, -d_hole);
    float d_edge = length(vec2(d_plane+rounding, d_hole)) - rounding;
    return min(d_board, d_edge);
}

/**
 * fold space into polar coords and put a hex hole board there,
 * forming a tube along the Z axis
 */
float hex_hole_tube(vec3 where, 
                    float tube_radius,
                    float hole_radius,
                    float thickness,
                    float hole_rounding) {
    float where_angle = atan(where.x, where.y);
    float where_radius = length(where.xy);
    where.x = where_angle * tube_radius;
    where.y = where_radius - tube_radius;
    return hex_hole_board(where, hole_radius, thickness, hole_rounding);
}

/*
 * framing and bracing between columns
 */
float measure_frame(vec3 where_tube, float tube_rad) {
    float r = length(where_tube.xy);
    where_tube.z = cmod(where_tube.z, 5.0);
    float sheath = r-tube_rad-0.3;
    float interior = r-tube_rad-0.1;
    float bar = length(where_tube.zy-vec2(0,0)) - 0.3;
    float sheath_cut = abs(where_tube.z)-0.5;
    float frame = min(sheath, bar);
    float weld = length(vec2(bar, sheath)) - 0.10;
    float weld2 = max(sheath - 0.5, bar - 0.05);
    frame = min(frame, min(weld, weld2));
    frame = max(frame, -interior);
    frame = max(frame, sheath_cut);
    return frame;
}

/**
 * find the closest object in the scene and return its distance and id
 */
vec2 measure(vec3 where) {
    vec2 closest = vec2(100000.0, 0.0);

    float dist_floor = hex_hole_board(where, 0.42, 0.2, 0.1);
    if (dist_floor <= closest.x) {
        closest = vec2(dist_floor, ID_FLOOR);
    }
    vec3 where_tube = where.xzy; // flip tube around x
    where_tube.x = cmod(where_tube.x, 10.0);
    float tube_rad = 6.0/PI;
    float dist_tube = hex_hole_tube(where_tube, tube_rad, 0.42, 0.2, 0.1);
    if (dist_tube <= closest.x) {
        closest = vec2(dist_tube, ID_TUBE);
    }
    float frame = measure_frame(where_tube, tube_rad);
    if (frame <= closest.x) {
        closest = vec2(frame, ID_CAP);
    }
    return closest;
}

/**
 * Figure out coloring for where we hit
 */
const vec4 floor_color = vec4(0.18,0.18,0.22,0.0);
const vec4 bizzo_color = vec4(0.2,0.5,0.7,0.2);
const vec4 guts_color = vec4(0.5,0.2,0.1,0.0);
const vec4 rod_color = vec4(1,0,0,1.0);
const vec4 bone_color = vec4(0.6,0.57,0.50,0.2);
const vec4 tube_color = vec4(1,1,1,0.2);
const vec4 sky = vec4(0,0,0,0);

vec4 paint(vec2 hit, vec3 where) {

    int who = int(hit.y);
    float ambient = 0.0;
    if (who == ID_FLOOR) {
        return bone_color;
    }
    if (who == ID_BIZZO) {
        return bizzo_color;
    }
    if (who == ID_TUBE) {
        return tube_color;
    }
    if (who == ID_CAP) {
        return bone_color;
    }
    return sky;
}

// end of model stuff

vec3 calc_surface_normal(vec3 hit);
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax );

/**
 * main entrypoint
 */
void main(void)
{
    vec3 eye = vec3(sin(time*0.31)*15.0+5.0,
                    sin(time*0.22)*15.0+20.0,
                    cos(time*0.13)*10.0-15.0);
    vec3 look_at = vec3(10,12.0+10.0*sin(time*0.05),0);
    vec3 up = Y;
    vec3 ray = calculateRay(resolution, gl_FragCoord.xy, eye, look_at, up);
    
    vec3 where = eye;
    float total_dist = 0.0;
    vec2 current;
    int who = 0;
    for(int steps = 0; steps < MAX_STEPS; steps++) {
        current = measure(where);
        float current_dist = current.x;
        if (current_dist < EPSILON) {
            who = int(current.y);
            break;
        }
        total_dist += current_dist * STEP_RATIO;
        if (total_dist > MAX_DIST) {
            break;
        }
        where = eye + total_dist * ray;
    }

    vec3 fog_color = vec3(0,0,0);
    if (who == 0){
        glFragColor = vec4(fog_color, 1.0);
        return;
    }
    vec3 hit = where;
    vec4 the_paint = paint(current, where);
    vec3 to_light = normalize(vec3(-5,15,-1));
    float shadow = calcSoftshadow(hit, to_light, 0.0, total_dist);
    vec3 surface_normal = calc_surface_normal(hit);
    float dotty = dot(to_light, surface_normal);
    float light_amount = max(0.0, dotty);
    float light_fade = 1.0;
    float ambient = the_paint.w;
    float lighting = ambient + (1.0-ambient) * 
        (shadow*0.5 * (1.0 + light_amount * light_fade));

    vec3 coloring = light_fade *(the_paint.xyz * lighting)
        + fog_color * (1.0-light_fade);
    vec3 reflected = surface_normal * 2.0 * dotty - to_light;
    vec3 toEye = normalize(-ray);
    float specular = pow(max(0.0, dot(toEye, reflected)), 32.0);
    coloring += vec3(specular, specular, specular);
    glFragColor = vec4(coloring,1.0);
}

#define NORMAL_DELTA 0.001

vec3 calc_surface_normal(vec3 hit) {
    return normalize(vec3(
            measure(hit+vec3(NORMAL_DELTA, 0.0, 0.0)).x - measure(hit-vec3(NORMAL_DELTA, 0.0, 0.0)).x,
            measure(hit+vec3(0.0, NORMAL_DELTA, 0.0)).x - measure(hit-vec3(0.0, NORMAL_DELTA, 0.0)).x,
            measure(hit+vec3(0.0, 0.0, NORMAL_DELTA)).x - measure(hit-vec3(0.0, 0.0, NORMAL_DELTA)).x
    ));
}

float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
        float h = measure( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}
