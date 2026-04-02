#version 420

// original https://www.shadertoy.com/view/NlS3Ry

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct face{
    vec3 p;
    vec3 side0;
    vec3 side1;
};

struct ray{
    vec3 p;
    vec3 vec;
};

vec4 create_orientation(vec3 axis, float angle){
    float len;
    vec4 outvec;
    
    len = length(axis);
    axis *= sin(angle)/len;
    outvec.yzw = axis;
    outvec.x = cos(angle);
    
    return outvec;
}

vec4 inverse_orientation(vec4 orientation){
    return vec4(orientation.x, -orientation.yzw);
}

vec4 compose_orientation(vec4 a, vec4 b){
    vec4 outvec;
    
    outvec.x = dot(a, b.xyzw*vec4(1.0, -1.0, -1.0, -1.0));
    outvec.y = dot(a, b.yxwz*vec4(1.0, 1.0, 1.0, -1.0));
    outvec.z = dot(a, b.zwxy*vec4(1.0, -1.0, 1.0, 1.0));
    outvec.w = dot(a, b.wzyx*vec4(1.0, 1.0, -1.0, 1.0));
    
    return outvec;
}

vec3 apply_orientation(vec3 p, vec4 o){
    vec4 v;
    
    v.x = 0.0;
    v.yzw = p.xyz;
    return compose_orientation(compose_orientation(o, v), inverse_orientation(o)).yzw;
}

void ray_face_intersect(face f, ray r, out float t, out vec2 face_coords, out vec3 intersect_pos){
    vec3 normal_vec;
    
    normal_vec = cross(f.side0, f.side1);
    t = dot(f.p - r.p, normal_vec)/dot(r.vec, normal_vec);
    intersect_pos = r.vec*t + r.p;
    face_coords.x = dot(intersect_pos - f.p, f.side0)/(dot(f.side0, f.side0));
    face_coords.y = dot(intersect_pos - f.p, f.side1)/(dot(f.side1, f.side1));
}

float hash(const float n){
    return fract(cos(2.0734*n)*sin(n*1.1234512)*12111.312);
}

//The number of rectangular faces in the scene
#define NUM_FACES 51

//For each face, I have defined a corner of the face and two vectors for the sides of the face
const face faces[NUM_FACES] = face[NUM_FACES](
    //The smooth stone block
    face(vec3(0.0625, 0.0625, -0.0001), vec3(0.875, 0.0, 0.0), vec3(0.0, 0.875, 0.0)),
    face(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0)),
    face(vec3(-0.0001, 0.0625, 0.0625), vec3(0.0, 0.0, 0.875), vec3(0.0, 0.875, 0.0)),
    face(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0)),
    face(vec3(1.0001, 0.0625, 0.0625), vec3(0.0, 0.0, 0.875), vec3(0.0, 0.875, 0.0)),
    face(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0)),
    face(vec3(0.0625, 0.0625, 1.0001), vec3(0.875, 0.0, 0.0), vec3(0.0, 0.875, 0.0)),
    face(vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0)),
    face(vec3(0.0625, 1.0001, 0.0625), vec3(0.875, 0.0, 0.0), vec3(0.0, 0.0, 0.875)),
    face(vec3(0.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0)),
    
    //The grass ground
    //This is just a plane that lies a the bottom of the scene
    face(vec3(50.0, 0.0, 50.0), vec3(-100.0, 0.0, 0.0), vec3(0.0, 0.0, -100.0)),
    
    //The wood on the redstone torch
    face(vec3(0.4375, 0.125, 0.0001), vec3(0.125, 0.0, 0.0), vec3(0.0, 0.5, -0.5)),
    face(vec3(0.4375, 0.125, 0.0001), vec3(0.0, 0.125, 0.125), vec3(0.0, 0.5, -0.5)),
    face(vec3(0.5625, 0.125, 0.0001), vec3(0.0, 0.125, 0.125), vec3(0.0, 0.5, -0.5)),
    face(vec3(0.4375, 0.25, 0.1251), vec3(0.125, 0.0, 0.0), vec3(0.0, 0.5, -0.5)),
    
    //The redstone on the redstone torch
    face(vec3(0.4375, 0.625, -0.4999), vec3(0.125, 0.0, 0.0), vec3(0.0, 0.125, -0.125)),
    face(vec3(0.4375, 0.625, -0.4999), vec3(0.0, 0.125, 0.125), vec3(0.0, 0.125, -0.125)),
    face(vec3(0.5627, 0.625, -0.4999), vec3(0.0, 0.125, 0.125), vec3(0.0, 0.125, -0.125)),
    face(vec3(0.4375, 0.75, -0.3749), vec3(0.125, 0.0, 0.0), vec3(0.0, 0.125, -0.125)),
    face(vec3(0.4375, 0.75, -0.6249), vec3(0.125, 0.0, 0.0), vec3(0.0, 0.125, 0.125)),
    
    //The redstone dust!
    face(vec3(-1.25, 0.0001, 0.5625), vec3(1.25, 0.0, 0.0), vec3(0.0, 0.0, -0.125)),
    face(vec3(-1.25, 0.0001, 0.625), vec3(1.25, 0.0, 0.0), vec3(0.0, 0.0, -0.0625)),
    face(vec3(-1.25, 0.0001, 0.375), vec3(1.25, 0.0, 0.0), vec3(0.0, 0.0, 0.0625)),
    
    //The redstone repeater
    face(vec3(-1, 0, -1), vec3(1.0, 0.0, 0.0), vec3(0.0, 0.125, 0.0)),
    face(vec3(-1, 0, 0), vec3(1.0, 0.0, 0.0), vec3(0.0, 0.125, 0.0)),
    face(vec3(-1, 0, -1), vec3(0.0, 0.0, 1.0), vec3(0.0, 0.125, 0.0)),
    face(vec3(0, 0, -1), vec3(0.0, 0.0, 1.0), vec3(0.0, 0.125, 0.0)),
    face(vec3(-1, 0.125, -1), vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0)),
    
    //The wood on the repeater
    face(vec3(-0.875, 0.125, -0.5625), vec3(0.0, 0.1875, 0.0), vec3(0.0, 0.0, 0.125)),
    face(vec3(-0.75, 0.125, -0.5625), vec3(0.0, 0.1875, 0.0), vec3(0.0, 0.0, 0.125)),
    face(vec3(-0.875, 0.125, -0.5625), vec3(0.0, 0.1875, 0.0), vec3(0.125, 0.0, 0.0)),
    face(vec3(-0.875, 0.125, -0.4375), vec3(0.0, 0.1875, 0.0), vec3(0.125, 0.0, 0.0)),
    
    //The redstone on the repeater
    face(vec3(-0.875, 0.3125, -0.5625), vec3(0.0, 0.125, 0.0), vec3(0.0, 0.0, 0.125)),
    face(vec3(-0.75, 0.3125, -0.5625), vec3(0.0, 0.125, 0.0), vec3(0.0, 0.0, 0.125)),
    face(vec3(-0.875, 0.3125, -0.5625), vec3(0.0, 0.125, 0.0), vec3(0.125, 0.0, 0.0)),
    face(vec3(-0.875, 0.3125, -0.4375), vec3(0.0, 0.125, 0.0), vec3(0.125, 0.0, 0.0)),
    face(vec3(-0.875, 0.4375, -0.5625), vec3(0.125, 0.0, 0.0), vec3(0.0, 0.0, 0.125)),
    
    face(vec3(-0.625, 0.1256, -0.5625), vec3(0.5, 0.0, 0.0), vec3(0.0, 0.0, 0.125)),
    
    //The wood on the repeater
    face(vec3(-0.25, 0.125, -0.5625), vec3(0.0, 0.1875, 0.0), vec3(0.0, 0.0, 0.125)),
    face(vec3(-0.125, 0.125, -0.5625), vec3(0.0, 0.1875, 0.0), vec3(0.0, 0.0, 0.125)),
    face(vec3(-0.25, 0.125, -0.5625), vec3(0.0, 0.1875, 0.0), vec3(0.125, 0.0, 0.0)),
    face(vec3(-0.25, 0.125, -0.4375), vec3(0.0, 0.1875, 0.0), vec3(0.125, 0.0, 0.0)),
    
    //The redstone on the repeater
    face(vec3(-0.25, 0.3125, -0.5625), vec3(0.0, 0.125, 0.0), vec3(0.0, 0.0, 0.125)),
    face(vec3(-0.125, 0.3125, -0.5625), vec3(0.0, 0.125, 0.0), vec3(0.0, 0.0, 0.125)),
    face(vec3(-0.25, 0.3125, -0.5625), vec3(0.0, 0.125, 0.0), vec3(0.125, 0.0, 0.0)),
    face(vec3(-0.25, 0.3125, -0.4375), vec3(0.0, 0.125, 0.0), vec3(0.125, 0.0, 0.0)),
    face(vec3(-0.25, 0.4375, -0.5625), vec3(0.125, 0.0, 0.0), vec3(0.0, 0.0, 0.125)),
    
    //More redstone dust
    face(vec3(-1.25, 0.0001, 0.75), vec3(-0.5, 0.0, 0.0), vec3(0.0, 0.0, -0.5)),
    face(vec3(-1.25, 0.0001, -0.25), vec3(-0.5, 0.0, 0.0), vec3(0.0, 0.0, -0.5)),
    face(vec3(-1.4375, 0.0001, -0.25), vec3(-0.125, 0.0, 0.0), vec3(0.0, 0.0, 0.5)),
    face(vec3(-1.25, 0.0001, -0.4375), vec3(0.25, 0.0, 0.0), vec3(0.0, 0.0, -0.125))
);

//Each face gets a default color
vec3 face_colors[NUM_FACES] = vec3[NUM_FACES](
    //The smooth stone block
    vec3(0.7, 0.7, 0.7),
    vec3(0.5, 0.5, 0.5),
    vec3(0.7, 0.7, 0.7),
    vec3(0.5, 0.5, 0.5),
    vec3(0.7, 0.7, 0.7),
    vec3(0.5, 0.5, 0.5),
    vec3(0.7, 0.7, 0.7),
    vec3(0.5, 0.5, 0.5),
    vec3(0.7, 0.7, 0.7),
    vec3(0.5, 0.5, 0.5),
    
    //The grass ground
    vec3(0.2, 0.4, 0.05),
    
    //The wood on the redstone torch
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    
    //The redstone on the redstone torch
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    
    //The redstone dust
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    
    //The redstone repeater
    vec3(0.7, 0.7, 0.7),
    vec3(0.7, 0.7, 0.7),
    vec3(0.7, 0.7, 0.7),
    vec3(0.7, 0.7, 0.7),
    vec3(0.7, 0.7, 0.7),
    
    //The wood on the repeater
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    
    //The redstone on the repeater
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    
    vec3(0.4, 0.0, 0.0),
    
    //The wood on the repeater
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    
    //The redstone on the repeater
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    
    //More redstone dust
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0),
    vec3(0.4, 0.0, 0.0)
);

//Since I can't store the actual textures in the shader, I instead resort to adding the
//"roughness" that you see in Minecraft's textures to try to make it look like the same
//textures. I compensate by adding more faces when I need more detail
const vec3 material_variation[NUM_FACES] = vec3[NUM_FACES](
    //The smooth stone block
    vec3(0.15, 0.15, 0.15),
    vec3(0.15, 0.15, 0.15),
    vec3(0.15, 0.15, 0.15),
    vec3(0.15, 0.15, 0.15),
    vec3(0.15, 0.15, 0.15),
    vec3(0.15, 0.15, 0.15),
    vec3(0.15, 0.15, 0.15),
    vec3(0.15, 0.15, 0.15),
    vec3(0.15, 0.15, 0.15),
    vec3(0.15, 0.15, 0.15),
    
    //The grass ground
    vec3(0.2, 0.2, 0.2),
    
    //The wood on the redstone torch should only vary in "brown-ness"
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    vec3(0.25, 0.14, 0.0),
    
    //The redstone on the redstone torch
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    
    //The redstone dust
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 0.0, 0.0),
    
    //The redstone repeater
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    
    //The wood on the repeater
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    
    //The redstone on the repeater
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    
    vec3(0.0, 0.0, 0.0),
    
    //The wood on the repeater
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    vec3(0.24, 0.14, 0.0),
    
    //The redstone on the repeater
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    vec3(0.2, 0.2, 0.2),
    
    //More redstone dust
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 0.0, 0.0)
);

//This stores how many "mc pixels" across each face is
//This will determine the resolution of the material variation
const vec2 texture_dims[NUM_FACES] = vec2[NUM_FACES](
    //The smooth stone block
    vec2(16.0, 16.0),
    vec2(16.0, 16.0),
    vec2(16.0, 16.0),
    vec2(16.0, 16.0),
    vec2(16.0, 16.0),
    vec2(16.0, 16.0),
    vec2(16.0, 16.0),
    vec2(16.0, 16.0),
    vec2(16.0, 16.0),
    vec2(16.0, 16.0),
    
    //The grass ground
    vec2(1600.0, 1600.0),
    
    //The wood on the redstone torch
    vec2(2.0, 8.0),
    vec2(2.0, 8.0),
    vec2(2.0, 8.0),
    vec2(2.0, 8.0),
    
    //The redstone on the redstone torch
    vec2(2.0, 2.0),
    vec2(2.0, 2.0),
    vec2(2.0, 2.0),
    vec2(2.0, 2.0),
    vec2(2.0, 2.0),
    
    //The redstone dust
    vec2(20.0, 2.0),
    vec2(20.0, 1.0),
    vec2(20.0, 1.0),
    
    //The redstone repeater
    vec2(16.0, 2.0),
    vec2(16.0, 2.0),
    vec2(16.0, 2.0),
    vec2(16.0, 2.0),
    vec2(16.0, 16.0),
    
    //The wood on the redstone repeater
    vec2(3.0, 2.0),
    vec2(3.0, 2.0),
    vec2(3.0, 2.0),
    vec2(3.0, 2.0),
    
    //The redstone on the repeater
    vec2(2.0, 2.0),
    vec2(2.0, 2.0),
    vec2(2.0, 2.0),
    vec2(2.0, 2.0),
    vec2(2.0, 2.0),
    
    vec2(1.0, 1.0),
    
    //The wood on the redstone repeater
    vec2(3.0, 2.0),
    vec2(3.0, 2.0),
    vec2(3.0, 2.0),
    vec2(3.0, 2.0),
    
    //The redstone on the repeater
    vec2(2.0, 2.0),
    vec2(2.0, 2.0),
    vec2(2.0, 2.0),
    vec2(2.0, 2.0),
    vec2(2.0, 2.0),
    
    //More redstone dust
    vec2(8.0, 8.0),
    vec2(8.0, 8.0),
    vec2(2.0, 8.0),
    vec2(4.0, 2.0)
);

//This stores which materials are transparent to light
const bool material_transparent[NUM_FACES] = bool[NUM_FACES](
    //The smooth stone block is not transparent
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    
    //The grass is not transparent
    false,
    
    //The wood on the redstone is not transparent
    true,
    true,
    true,
    true,
    
    //The redstone on the redstone torch is transparent (so we can put the light source inside)
    true,
    true,
    true,
    true,
    true,
    
    //The redstone dust
    true,
    true,
    true,
    
    //The redstone repeater
    false,
    false,
    false,
    false,
    false,
    
    //The wood on the redstone repeater
    true,
    true,
    true,
    true,
    
    //The redstone on the repeater
    true,
    true,
    true,
    true,
    true,
    
    true,
    
    //The wood on the redstone repeater
    true,
    true,
    true,
    true,
    
    //The redstone on the repeater
    true,
    true,
    true,
    true,
    true,
    
    //More redstone dust
    true,
    true,
    true,
    true
);

//The chance that a pixel of the block will be transparent
//This is pretty much only for redstone dust (I might use this for particle effects later though)
const float material_pixel_invisible_chance[NUM_FACES] = float[NUM_FACES](
    //The smooth stone block is not transparent
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    
    //The grass is not transparent
    0.0,
    
    //The wood on the redstone is not transparent
    0.0,
    0.0,
    0.0,
    0.0,
    
    //The redstone on the redstone torch is transparent (so we can put the light source inside)
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    
    //The redstone dust
    0.5,
    0.8,
    0.8,
    
    //The redstone repeater
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    
    //The wood on the redstone repeater
    0.0,
    0.0,
    0.0,
    0.0,
    
    //The redstone on the repeater
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    
    0.0,
    
    //The wood on the redstone repeater
    0.0,
    0.0,
    0.0,
    0.0,
    
    //The redstone on the repeater
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    
    //More redstone dust
    0.5,
    0.5,
    0.6,
    0.5
);

//The number of light sources
#define NUM_LIGHT_SOURCES 4

//This stores the different light source colors
vec3 light_source_color[NUM_LIGHT_SOURCES] = vec3[NUM_LIGHT_SOURCES](
    vec3(0.25, 0.03125, 0.03125),
    vec3(2.0, 4.0, 4.0),
    vec3(0.1, 0.0125, 0.0125),
    vec3(0.1, 0.0125, 0.0125)
);

//This stores each light source position
vec3 light_source_position[NUM_LIGHT_SOURCES] = vec3[NUM_LIGHT_SOURCES](
    vec3(0.5, 0.775, -0.5),
    vec3(-2.0, 4.0, 4.0),
    vec3(-0.8125, 0.375, -0.5),
    vec3(-0.1875, 0.375, -0.5)
);

//This stores whether each light source is active
bool light_source_active[NUM_LIGHT_SOURCES] = bool[NUM_LIGHT_SOURCES](
    true, true, true, true
);

ray get_camera_ray(vec2 pixel){
    float least_side;
    
    pixel -= vec2(0.5);
    least_side = min(resolution.x, resolution.y);
    return ray(vec3(0), vec3(pixel.x*resolution.x/least_side, pixel.y*resolution.y/least_side, 1.0));
}

void main(void) {
    vec4 camera_orientation;
    vec3 camera_position;
    vec4 look_down;
    ray camera_ray;
    face f;
    int face_num;
    int texture_id;
    vec3 intersect_pos;
    vec2 face_coords;
    float intersect_time;
    float best_dist = 25.0;
    vec3 face_pos;
    vec3 face_color;
    vec3 face_normal;
    int face_intersect;
    ray shadow_ray;
    vec3 current_color;
    vec3 emission;
    int light_id;
    float pix_x;
    float pix_y;
    vec2 texture_dim;
        
    camera_orientation = create_orientation(vec3(0.0, 1.0, 0.0), time/5.0 + 0.125);
    look_down = create_orientation(vec3(1.0, 0.0, 0.0), 0.3);
    camera_ray = get_camera_ray(vec2(gl_FragCoord.xy.x/resolution.x, gl_FragCoord.xy.y/resolution.y));
    camera_ray.vec = apply_orientation(camera_ray.vec, look_down);
    camera_ray.vec = apply_orientation(camera_ray.vec, camera_orientation);
    camera_ray.p = apply_orientation(vec3(-0.25, 1.75, -2.875), camera_orientation);
    
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
    
    for(face_num = 0; face_num < NUM_FACES; face_num++){
        f = faces[face_num];
        ray_face_intersect(f, camera_ray, intersect_time, face_coords, intersect_pos);
        if(intersect_time > 0.0 && length(intersect_pos - camera_ray.p) < best_dist && face_coords.x > 0.0 && face_coords.x < 1.0 && face_coords.y > 0.0 && face_coords.y < 1.0){
            texture_dim = texture_dims[face_num];
            pix_x = floor(face_coords.x*texture_dim.x);
            pix_y = floor(face_coords.y*texture_dim.y);
            if(material_pixel_invisible_chance[face_num] > hash((pix_x + 4.0 + 2.0*float(face_num))*(pix_y + 1.0 + float(face_num))))
                continue;
            best_dist = length(intersect_pos - camera_ray.p);
            face_pos = intersect_pos;
            face_color = face_colors[face_num] + material_variation[face_num]*hash(pix_x + 16.0*pix_y);
            face_intersect = face_num;
            face_normal = normalize(cross(f.side0, f.side1));
        }
    }
    
    if(best_dist != 25.0){
        current_color = vec3(1.0/dot(face_pos - camera_ray.p, face_pos - camera_ray.p))*face_color;
        light_source_active[0] = mod(time, 1.0) < 0.5;
        light_source_active[2] = mod(time - 0.4, 1.0) < 0.5;
        light_source_active[3] = mod(time - 0.4, 1.0) < 0.5;
        if(mod(time, 1.0) < 0.5 && face_intersect >= 15 && face_intersect <= 19)
            current_color += 2.0*face_color;
        if(mod(time - 0.4, 1.0) < 0.5 && ((face_intersect >= 32 && face_intersect <= 36) || (face_intersect >= 20 && face_intersect <= 22) || face_intersect >= 42))
            current_color += 2.0*face_color;
        for(light_id = 0; light_id < NUM_LIGHT_SOURCES; light_id++){
            if(!light_source_active[light_id])
                continue;
            if(light_id == 0 && face_intersect >= 15 && face_intersect <= 19)
                continue;
            if(light_id == 2 && face_intersect >= 32 && face_intersect <= 36)
                continue;
            if(light_id == 3 && face_intersect >= 42 && face_intersect <= 46)
                continue;
            shadow_ray = ray(face_pos, light_source_position[light_id] - face_pos);
            for(face_num = 0; face_num < NUM_FACES; face_num++){
                if(material_transparent[face_num] || face_num == face_intersect)
                    continue;
                f = faces[face_num];
                ray_face_intersect(f, shadow_ray, intersect_time, face_coords, intersect_pos);
                if(intersect_time > 0.0 && intersect_time < 1.0 && face_coords.x > 0.0 && face_coords.x < 1.0 && face_coords.y > 0.0 && face_coords.y < 1.0)
                    break;
            }
            if(face_num == NUM_FACES)
                current_color += light_source_color[light_id]*vec3(abs(dot(face_normal, shadow_ray.vec))/(length(shadow_ray.vec)*dot(shadow_ray.vec, shadow_ray.vec)))*face_color;
        }
        glFragColor = vec4(current_color, 1.0);
    }
}
