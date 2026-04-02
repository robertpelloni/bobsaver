#version 420

// original https://www.shadertoy.com/view/lc2Bzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Animated Running Cubeman.
//
// This is a little complicated, but in essance it's
// a cube renderer with the ability compose rotations
// and translations to give the equivalent of skeletal
// animation. Each cube can have a parent, and a
// parent's transforms will apply to it's children.
// This requires all cubes be in order (parents before
// children) so the hierarchy can be calculated in a
// single pass. 
//
// As for the animation itself, it's very simple.
// Mostly wanted to get the idea out there instead
// of tinkering too much with the model/animation.
//
// A major limitation is that all cubes start from the
// object's origin. This means most proper limbs need
// to comprise two objects so the pivot points are at
// the ends.
//
// provided under CC0.

struct NormAndCol {
    vec3 col;
    vec3 norm;
    float dist;
};

struct Cube {
    vec3 local_pos;
    mat3 local_rot;
    vec3 size;
    vec3 col;
    int parent;
    vec3 world_pos;
    mat3 world_rot;
    mat3 world_irot;
};

NormAndCol n_a_c(vec3 col, vec3 norm, float dist) {
    NormAndCol ret;
    
    ret.col = col;
    ret.norm = norm;
    ret.dist = dist;
    
    return ret;
}

Cube m_c(vec3 pos, vec3 size, vec3 col, mat3 rot) {
    Cube ret;
    
    ret.local_pos = pos;
    ret.local_rot = rot;
    ret.size = size;
    ret.col = col;
    ret.parent = -1;
    
    return ret;
}

Cube m_c(vec3 pos, vec3 size, vec3 col, mat3 rot, int parent) {
    Cube ret;
    
    ret = m_c(pos, size, col, rot);

    ret.parent = parent;
    
    return ret;
}

Cube cubes[20];
int cube_num = 19;

const float max_dist = 1000.0;
vec3 light_dir;
float cube_size = 0.5;
const float ambient_light = 0.4;

const float floor_level = -2.0;
const float checkerboard = 4.0;
const float checkerboard2 = checkerboard/2.0;

// Calculates a ray intersection with an infinite
// checkerboard which scrolls with time.
NormAndCol floor_check(vec3 in_vec, vec3 in_pos) {
    if (in_pos.y < (floor_level+0.0011) || in_vec.y > -0.03) {
        return n_a_c(vec3(0), vec3(0), max_dist+1.0);
    }
    
    float dist = (in_pos.y - floor_level) / -in_vec.y;

    vec3 int_point = in_pos + (in_vec*dist);
    
    int_point.z += time*6.07;
    
    bool x_int = mod(int_point.x, checkerboard) < checkerboard2;
    bool z_int = mod(int_point.z, checkerboard) < checkerboard2;
    
    float fog = (clamp(pow(dist/30.0, 0.2)-0.65, 0.0, 0.5));

    if (x_int ^^ z_int) {
        return n_a_c(vec3(fog), vec3(0,-1,0), dist);
    } else {
        return n_a_c(vec3((1.0-fog)), vec3(0,-1,0), dist);
    }
}

// Calculates transform hierarchies.
void update_cubes() {
    for (int c_n=0; c_n<cube_num; c_n++) {
        int par = cubes[c_n].parent;

        if (par == -1) {
            cubes[c_n].world_pos = cubes[c_n].local_pos;
            cubes[c_n].world_rot = cubes[c_n].local_rot;
        } else {
            cubes[c_n].world_pos = cubes[par].world_pos + (cubes[c_n].local_pos * cubes[par].world_rot);
            cubes[c_n].world_rot = cubes[c_n].local_rot * cubes[par].world_rot;
        }

        cubes[c_n].world_irot = inverse(cubes[c_n].world_rot);
    }
}

// Cube intersection with rotation.
NormAndCol check_cube(vec3 in_vec, vec3 in_pos, Cube cube) {
    in_pos -= cube.world_pos;
    in_vec = in_vec * cube.world_irot;
    in_pos = in_pos * cube.world_irot;

    vec3 origin_dist = in_pos / -in_vec;
    vec3 box_dist = cube.size / abs(in_vec);

    vec3 box_dist_min = origin_dist - box_dist;
    vec3 box_dist_max = origin_dist + box_dist;

    if (box_dist_min.x < box_dist_max.y && box_dist_min.x < box_dist_max.z && 
        box_dist_min.y < box_dist_max.x && box_dist_min.y < box_dist_max.z && 
        box_dist_min.z < box_dist_max.x && box_dist_min.z < box_dist_max.y) {
        vec3 norm = vec3(0);
        float best = 0.0;
        
        if (box_dist_min.x > box_dist_min.y && box_dist_min.x > box_dist_min.z) {
            norm = vec3(1,0,0);
            best = box_dist_min.x;
        
            if (in_vec.x < 0.0) norm = -norm;
        } else if (box_dist_min.y > box_dist_min.z) {
            norm = vec3(0,1,0);
            best = box_dist_min.y;
        
            if (in_vec.y < 0.0) norm = -norm;
        } else {
            norm = vec3(0,0,1);
            best = box_dist_min.z;
        
            if (in_vec.z < 0.0) norm = -norm;
        }
        
        norm = norm * cube.world_rot;
        
        return n_a_c(cube.col, norm, clamp(best, 0.0, max_dist));
    }
    
    return n_a_c(vec3(1), vec3(0), max_dist+1.0);
}

// Rotate around axis.
mat3 rotations(vec3 axis, float amt) {
    mat3 ret;
    float ct = cos(amt);
    float st = sin(amt);
    float ict = 1.0-cos(amt);
    
    ret[0] = vec3(axis.x*axis.x,axis.x*axis.y,axis.x*axis.z);
    ret[1] = vec3(axis.y*axis.x,axis.y*axis.y,axis.y*axis.z);
    ret[2] = vec3(axis.z*axis.x,axis.z*axis.y,axis.z*axis.z);
    
    ret *= ict;
    
    ret[0] += vec3(        ct, -axis.z*st,  axis.y*st);
    ret[1] += vec3( axis.z*st,         ct, -axis.x*st);
    ret[2] += vec3(-axis.y*st,  axis.x*st,         ct);
    
    return ret;
}

mat3 indentity() {
    mat3 ret;
    
    ret[0] = vec3(1,0,0);
    ret[1] = vec3(0,1,0);
    ret[2] = vec3(0,0,1);
    
    return ret;
}

// Complete raycast, to aid shadow calculations.
NormAndCol raycast(vec3 in_vec, vec3 in_pos) {
    NormAndCol best = n_a_c(vec3(1), vec3(0), max_dist+1.0);
    
    for (int i=0; i<cube_num; i++) {
        NormAndCol mdia = check_cube(in_vec, in_pos, cubes[i]);

        if (mdia.dist < best.dist && mdia.dist > 0.0001) {
            best = mdia;
        }
    }
    
    NormAndCol mfloor = floor_check(in_vec, in_pos);
    
    if (mfloor.dist < best.dist) {
        best = mfloor;
    }
    
    return best;
}

const float gm_p = 1.5;
const float ch_p = 0.2;

float gamma(float inp) {
    return inp < ch_p ? inp * pow(ch_p, gm_p-1.0) : pow(inp, gm_p);
}

void main(void) {
    float tim = time*5.0+1.0;

    float torso_tilt = sin((tim*2.0)+3.0)/15.0+0.1;
    float head_tilt = sin(((tim+0.2)*2.0)+3.0)/15.0+0.1;
    
    float u_leg = (sin(tim)/1.2)+3.1416;
    float l_leg = u_leg/2.0 + cos(tim)/3.0;
    
    float arm_swing = (sin((tim+0.8))/4.0)+3.1416;
    float arm_twist = (sin((tim+0.8))/4.0);
    
    float body_bob = sin((tim*2.0)+0.5)/8.0;
    
    // Quick explanation, the general pattern here is m_c (make_cube), which
    // initializes the cube, then manually setting the local_rot. This is
    // just a prefereance thing, and you can pass the rotation matrix into
    // m_c, but this seemed cleaner when I was writing it.
    // 
    // The numebr at the end (excluding cubes[0]) is which cube is a parent
    // to that cube. So 1 is parented to 0, 2 is parented to 1, and so on.
    
    // torso
    cubes[0] = m_c(vec3(0.0, 0.5, 0.0), vec3(0.38,0.6,0.25), vec3(1.0, 0.5, 0.5),  mat3(0));
    cubes[0].local_pos += vec3(0, body_bob, 0);
    cubes[0].local_rot = rotations(vec3(1,0,0), torso_tilt);
    
    // right arm
    cubes[1] = m_c(vec3(0.55,0.4, 0.0), vec3(0.2, 0.2, 0.2), vec3(1.0, 0.5, 0.5), mat3(0), 0);
    cubes[1].local_rot = rotations(vec3(1,0,0), arm_swing+0.3);
    cubes[2] = m_c(vec3(0,0.4,0),       vec3(0.13,0.4,0.13), vec3(1.0, 0.9, 0.7), mat3(0), 1);
    cubes[2].local_rot = rotations(vec3(0,1,0), -arm_twist);
    cubes[3] = m_c(vec3(0,0.4,0),       vec3(0.13,0.13,0.13),vec3(1.0, 0.9, 0.7), mat3(0), 2);
    cubes[3].local_rot = rotations(vec3(1,0,0), arm_swing+2.0);
    cubes[4] = m_c(vec3(0,0.4,0),       vec3(0.12,0.4,0.12), vec3(1.0, 0.9, 0.7), mat3(0), 3);
    cubes[4].local_rot = indentity();
    
    // left arm
    cubes[5] = m_c(vec3(-0.55,0.4,0.0), vec3(0.2, 0.2, 0.2), vec3(1.0, 0.5, 0.5), mat3(0), 0);
    cubes[5].local_rot = rotations(vec3(1,0,0), -arm_swing+0.3);
    cubes[6] = m_c(vec3(0,0.4,0),       vec3(0.15,0.4,0.15), vec3(1.0, 0.9, 0.7), mat3(0), 5);
    cubes[6].local_rot = rotations(vec3(0,1,0), -arm_twist);
    cubes[7] = m_c(vec3(0,0.4,0),       vec3(0.13,0.13,0.13),vec3(1.0, 0.9, 0.7), mat3(0), 6);
    cubes[7].local_rot = rotations(vec3(1,0,0), -arm_swing+2.0);
    cubes[8] = m_c(vec3(0,0.4,0),       vec3(0.12,0.4,0.12), vec3(1.0, 0.9, 0.7), mat3(0), 7);
    cubes[8].local_rot = indentity();
    
    // right leg
    cubes[ 9] = m_c(vec3(0.2,-0.5, 0.0), vec3(0.18,0.18,0.18),vec3(0.5, 0.5, 1.0), mat3(0), 0);
    cubes[ 9].local_rot = rotations(vec3(1,0,0), -u_leg-0.2);
    cubes[10] = m_c(vec3(0,0.5,0),       vec3(0.18,0.5,0.18), vec3(0.5, 0.5, 1.0), mat3(0), 9);
    cubes[10].local_rot = indentity();
    cubes[11] = m_c(vec3(0,0.5,0),       vec3(0.15,0.15,0.15),vec3(0.5, 0.5, 1.0), mat3(0), 10);
    cubes[11].local_rot = rotations(vec3(1,0,0), l_leg-1.0);
    cubes[12] = m_c(vec3(0,0.5,0),       vec3(0.15,0.5,0.15), vec3(0.5, 0.5, 1.0), mat3(0), 11);
    cubes[12].local_rot = indentity();
    
    // left leg
    cubes[13] = m_c(vec3(-0.2,-0.5, 0.0),vec3(0.18,0.18,0.18),vec3(0.5, 0.5, 1.0), mat3(0), 0);
    cubes[13].local_rot = rotations(vec3(1,0,0), u_leg-0.2);
    cubes[14] = m_c(vec3(0,0.5,0),       vec3(0.18,0.5,0.18), vec3(0.5, 0.5, 1.0), mat3(0), 13);
    cubes[14].local_rot = indentity();
    cubes[15] = m_c(vec3(0,0.5,0),       vec3(0.15,0.15,0.15),vec3(0.5, 0.5, 1.0), mat3(0), 14);
    cubes[15].local_rot = rotations(vec3(1,0,0), -l_leg+2.0);
    cubes[16] = m_c(vec3(0,0.5,0),       vec3(0.15,0.5,0.15), vec3(0.5, 0.5, 1.0), mat3(0), 15);
    cubes[16].local_rot = indentity();
    
    // head
    cubes[17] = m_c(vec3(0, 1.0, 0),     vec3(0.25,0.3,0.25), vec3(1.0, 0.9, 0.7), mat3(0), 0);
    cubes[17].local_rot = rotations(vec3(1,0,0), -head_tilt);
    
    // neck
    cubes[18] = m_c(vec3(0, 0.5, 0),     vec3(0.15,0.5,0.15), vec3(1.0, 0.9, 0.7), mat3(0), 0);
    cubes[18].local_rot = indentity();
    
    // Propagate parent changes to children to accelerate raycasting.
    update_cubes();

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy-(resolution.xy/2.0);

    uv /= resolution.y;

    float dist = 7.0;
    float c_ang = (time+4.5)/2.0;

    vec3 in_vec_p = vec3(sin(c_ang)*dist, 2.0, -(cos(c_ang)*dist));
    vec3 in_vec_d = normalize(-in_vec_p);
    light_dir = normalize(vec3(0.3,0.6,0.3));
    
    float fov = 1.0;

    mat3 lookat;
    lookat[2] = in_vec_d;
    lookat[0] = cross(vec3(0,1,0), lookat[2]);
    lookat[1] = cross(lookat[2], lookat[0]);
    lookat = transpose(lookat);
    
    in_vec_d = normalize(vec3(uv.xy*fov, 1.0)) * lookat;

    vec3 col = mix(vec3(0.7,0.8,1), vec3(0.5,0.6,1), uv.y);
    
    NormAndCol best = raycast(in_vec_d, in_vec_p);
    
    if (best.dist < max_dist) {
        vec3 hit_point = in_vec_p + (in_vec_d * best.dist);
    
        NormAndCol sun = raycast(light_dir, hit_point);

        float light = dot(best.norm, -light_dir);
        float light2 = clamp(light, ambient_light, 1.0);
            
        col = best.col * light2;
        
        // Shadow calculation, I dont like that light <= 0
        // is in here, but it was the easiest way to make 
        // sure backfaces are in shadow. The cube intersection
        // algorithm struggles when that happens for some
        // reason.
        if (sun.dist < 100.0 || light <= 0.0) {
            col *= 0.7;
        }
    }
    
    col.x = gamma(col.x);
    col.y = gamma(col.y);
    col.z = gamma(col.z);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
