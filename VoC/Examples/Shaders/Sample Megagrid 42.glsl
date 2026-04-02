#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3sf3R4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
just a simple raymarch scene with a pretty good hashing function using big primes.
using the hashing function to distribute some objects in ways that look random to ppl.
also using hyperbolic brightness attenutation to preserve color in overexposed areas.
*/

#define EPSILON 0.001
#define MAX_STEPS 1000
#define MAX_DIST 20.0
#define STEP_RATIO 0.5

#define ID_NONE   0
#define ID_GRID   1
#define ID_BALL   2
#define ID_PLATES 3
int hash(ivec3 p) {
    return ((p.x * 7919 + p.y) * 6563 + p.z) * 4273;
}

/**
 * distance to grid
 * return grid-local beam coords with distance
 */
vec4 dist_grid(vec3 pos) {
    vec3 dp1 = abs(fract(pos+0.5)-0.5);
    vec3 dp2 = vec3(
        min(dp1.x,dp1.y),
        max(dp1.x,dp1.y), 
        dp1.z);
    vec3 dp3 = vec3(
        dp2.x,
        max(dp2.y,dp2.z), 
        min(dp2.y,dp2.z));
    float dist = length(max(vec2(0.00,0.00),vec2(dp3.x,dp3.z) -0.03)) - 0.01;
    return vec4(dp3, dist);
}

vec4 dist_ball(vec3 pos) {
    vec3 offset = floor(pos+0.5);
    ivec3 gp = ivec3(int(offset.x),int(offset.y),int(offset.z));
    if (hash(gp) % 0x0f == 0) {
        pos = abs(fract(pos+0.5)-0.5);
        return vec4(pos, length(pos)-0.15);
    }
    return vec4(pos,3.0); // no ball here, fake it being elsewhere
}

const vec3 ORIGIN = vec3(0,0,0);
const vec3 PLATE_SIZE = vec3(0.5,0.01,0.5);

vec4 dist_floorplates(vec3 pos) {
    pos+=vec3(0.5,0.0,0.5);
    vec3 offset = floor(pos+0.5);
    ivec3 gp = ivec3(int(offset.x),int(offset.y),int(offset.z));
    if (hash(gp) % 7 == 0 || 
        
        ((gp.y%3==0) && (gp.x % 5 == 0 || gp.z%10==0))) {
        pos = max(ORIGIN,abs(fract(pos + 0.5) - 0.5)-PLATE_SIZE);
        return vec4(pos, length(pos));
    }
    return vec4(pos,3.0); // no ball here, fake it being elsewhere
}

void main(void)
{
    float aspect = resolution.y / resolution.x;
    
    // Normalized pixel coordinates (from 0 to 1)
    
    vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(0.5,0.5);
    uv.y *= aspect;
    vec3 eye = vec3(0.3 + 5.0*sin(time*0.1),
                    0.3,
                    -3.5 + 4.1*sin(time*0.27));
    vec3 look_at = vec3(
        12.3* cos(time*0.3),
        4.3* cos(time*0.34),
        5.3+9.0*cos(time*0.22));
    vec3 look = normalize(look_at - eye);
    vec3 up_init = vec3(0,1,0);
    vec3 right = cross(up_init, look);
    vec3 up = cross(look, right);
    vec3 ray = normalize(uv.x * right + uv.y * up + look);
    float dist = 0.0;
    vec3 pos = eye;
    int hit = ID_NONE;
    vec3 local_hit;
    for (int steps = 0; steps < MAX_STEPS && dist <MAX_DIST; steps++) {
        pos = eye + dist * ray;
        vec4 res_grid = dist_grid(pos);
        float closest = 100000.0;
        if (res_grid.w < closest) {
            local_hit = res_grid.xyz;
            hit = ID_GRID;
            closest = res_grid.w;
        }
        
        vec4 res_ball = dist_ball(pos);
        if (res_ball.w < closest) {
            local_hit = res_ball.xyz;
            hit = ID_BALL;
            closest = res_ball.w;
        }
        
        vec4 res_plate = dist_floorplates(pos);
        if (res_plate.w < closest) {
            local_hit = res_plate.xyz;
            hit = ID_PLATES;
            closest = res_plate.w;
        }

        if (closest < EPSILON) {
            break;
        }
        dist += STEP_RATIO * closest;
    }
    vec3 col = vec3(0,0,0);
    if (hit == ID_GRID) {
        float level = floor(fract((local_hit.y+0.0125)*20.0)*2.0);
        
        col = vec3(level);
    }
    else if (hit == ID_BALL) {
        float level = floor(fract((local_hit.y+0.0125)*20.0)*2.0);
        
        col = vec3(13.0*(1.02-pow(fract(time),0.25)),0,0);
    }
    else if (hit == ID_PLATES) {
        col = vec3(0.7,0.5,0.3);
    }
    float light_power = 10.0;
    // inverse square light falloff
    col *= light_power /(dist*dist);
    // smooth transition to overexposed areas while keeping hue&sat.
    float brightness = max(max(col.x, col.y), col.z);
    float attenuation = tanh(brightness) / brightness;
    col *= attenuation;
    // Output to screen
    glFragColor = vec4(col,1.0);
}
