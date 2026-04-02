#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/NddGRs

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ---------------------------------------------------------------------------
// project stochastics round 3
//
// continuing goal: 
//
//   approximate an ideal noise function,
//   that reveals no visual correlations,
//   when sampled at regular intervals,
//   everywhere!
//
//   efficiency is still of only secondary consideration
//
//  note that all bijective transforms of a machine word can be viewed as some kind
//  of shuffling - its shuffling all the way down - addition is a cut of the deck - 
//  bitwise rolling is a faro shuffle! - multiplication by odd numbers is like a
//  weird multi-pile shuffle
//
//  always answering the question where does the Nth card go after this shuffle?
//  
//  thats how hashing do
//
//  the bijections used here are 
//  
//    addition modulo 2^32 (cutting the deck)
//    multiplication by primitive element modulo 2^32 (a pile making shuffle)
//    xoring the high half of the word with the low half (sort of a block swapping shuffle)
//
// the shuffle is provably uniform, but correlations can be uniform too, so to hash, 
// shuffling is done more than once. 
//
// Casinos require three riffle shuffles and a "strip", ending with a cut, 
// when shuffling by hand, for a reason! Here it is.
//
// The reason for many shuffles in both cases is that the ascending or 
// descending orderings of inputs to outputs is not sufficiently shuffled with 
// only a couple of mixing steps. cards that began near each other tend to appear 
// in an ordering related to the one that they began with until sufficient 
// shuffling is done.
//
// the crypto guys go hundreds of shuffling steps just to be sure that they have 
// achieved all properties of an ideal stochastic generator that are achievable 
// when using only bijections
//
// - lets not go that far - our level of analysis is visual, upon the scaled 
// regular latice of key space

//  the refined shuffling step (like a single cut and riffle)
//
//    h  the machine word to be shuffled
//    k  the machine word shuffle key
//
//  outputs machine word between 0u <= x <= 0xffffffffu 

uint shuffle(uint h, uint k)
{
    h += k; h ^= h >> 16; h *= 0xCC2BFE9Du;
    return h;
}

//  point_noise()
//
//  noise at every point in space

float point_noise(uint h, float key)
{   uint k = floatBitsToUint(key); h = shuffle(shuffle(h, k), 0x8675309u);
    return 5.96046448e-8 * float(0xffffffu & h); }

float point_noise(uint h, vec2 key)
{   uvec2 k = floatBitsToUint(key); h = shuffle(shuffle(shuffle(h, k.x), k.y), 0x8675309u);
    return 5.96046448e-8 * float(0xffffffu & h); }

float point_noise(uint h, vec3 key)
{   uvec3 k = floatBitsToUint(key); h = shuffle(shuffle(shuffle(shuffle(h, k.x), k.y), k.z), 0x8675309u);
    return 5.96046448e-8 * float(0xffffffu & h); }

float point_noise(uint h, vec4 key)
{   uvec4 k = floatBitsToUint(key); h = shuffle(shuffle(shuffle(shuffle(shuffle(h, k.x), k.y), k.z), k.w), 0x8675309u);
    return 5.96046448e-8 * float(0xffffffu & h); }

const float pi = 3.14159265358979323846;
#define cmix(e0, e1, x)         mix(e0, e1, 0.5 * (1.0 - cos(pi * (x))))

//  lattice_noise()
//
//  noise on the key lattice

float lattice_noise(uint h, float key)
{   float i = floor(key), f = fract(key);
    return cmix(point_noise(h, i + 0.0), point_noise(h, i + 1.0), f); }

float lattice_noise(uint h, vec2 key)
{   vec2 i = floor(key), f = fract(key);
    return cmix(cmix(point_noise(h, i + vec2(0,0)), point_noise(h, i + vec2(0,1)), f.y),
                cmix(point_noise(h, i + vec2(1,0)), point_noise(h, i + vec2(1,1)), f.y), f.x) ; }

float lattice_noise(uint h, vec3 key)
{   vec3 i = floor(key), f = fract(key);
    return cmix(cmix(cmix(point_noise(h, i + vec3(0,0,0)), point_noise(h, i + vec3(0,0,1)), f.z),
                     cmix(point_noise(h, i + vec3(0,1,0)), point_noise(h, i + vec3(0,1,1)), f.z), f.y),
                cmix(cmix(point_noise(h, i + vec3(1,0,0)), point_noise(h, i + vec3(1,0,1)), f.z),
                     cmix(point_noise(h, i + vec3(1,1,0)), point_noise(h, i + vec3(1,1,1)), f.z), f.y), f.x); }

float lattice_noise(uint h, vec4 key)
{   vec4 i = floor(key), f = fract(key);
    return cmix(cmix(cmix(cmix(point_noise(h, i + vec4(0,0,0,0)), point_noise(h, i + vec4(0,0,0,1)), f.w),
                          cmix(point_noise(h, i + vec4(0,0,1,0)), point_noise(h, i + vec4(0,0,1,1)), f.w), f.z),
                     cmix(cmix(point_noise(h, i + vec4(0,1,0,0)), point_noise(h, i + vec4(0,1,0,1)), f.w),
                          cmix(point_noise(h, i + vec4(0,1,1,0)), point_noise(h, i + vec4(0,1,1,1)), f.w), f.z), f.y),
                cmix(cmix(cmix(point_noise(h, i + vec4(1,0,0,0)), point_noise(h, i + vec4(1,0,0,1)), f.w),
                          cmix(point_noise(h, i + vec4(1,0,1,0)), point_noise(h, i + vec4(1,0,1,1)), f.w), f.z),
                     cmix(cmix(point_noise(h, i + vec4(1,1,0,0)), point_noise(h, i + vec4(1,1,0,1)), f.w),
                          cmix(point_noise(h, i + vec4(1,1,1,0)), point_noise(h, i + vec4(1,1,1,1)), f.w), f.z), f.y), f.x); }

const mat3 brown_transform = mat3(vec3(0.5,0,0), vec3(0,0.5,0), vec3(0,0,0.5)) * mat3(vec3(0.54030231, 0.84147098, 0), vec3(-0.84147098, 0.54030231, 0), vec3(0, 0, 1)) * mat3(vec3(1, 0, 0), vec3(0, 0.54030231, 0.84147098), vec3(0, -0.84147098, 0.54030231));

float brown_noise(uint h, vec3 key, int steps)
{  
  key *= exp2(float(steps));
  float c = lattice_noise(h, key); 
  for(int i = 1; i < steps; i++) 
    c += 0.5 * (lattice_noise(h + uint(i), key *= brown_transform) - c);
  return c;
}

void main(void)
{
    // give brown noise a workout
    vec3 pos = 0.003 * vec3(gl_FragCoord.xy, 30.0 * date.w);
    float c = 1.0; for(int i = 0; i < 6; i++) c = min(c, brown_noise(uint(i), pos, 8));
    glFragColor = vec4(c*c, c, sqrt(c),1.0);
}

