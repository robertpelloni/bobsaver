#version 420

// original https://www.shadertoy.com/view/DsGBRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const uint max32 = 0xffffffffu;

// taken from https://nullprogram.com/blog/2018/07/31/
uint hash(uint x)
{
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

// 1D noise
float hash1(uint seed)
{
    return float(hash(seed)) / float(max32);
}
float hash1(float seed)
{
    return hash1(floatBitsToUint(seed));
}
float hash1(vec2 seed)
{
    return hash1(floatBitsToUint(seed.x) ^ floatBitsToUint(seed.y));
}
float hash1(vec3 seed)
{
    return hash1(floatBitsToUint(seed.x) ^ floatBitsToUint(seed.y) ^ floatBitsToUint(seed.z));
}
float hash1(vec4 seed)
{
    return hash1(floatBitsToUint(seed.x) ^ floatBitsToUint(seed.y) ^ floatBitsToUint(seed.z) ^ floatBitsToUint(seed.w));
}

// 2D noise
vec2 hash2(uint seed)
{
    return vec2(hash1(seed), hash1(seed ^ 0x1u));
}
vec2 hash2(float seed)
{
    return hash2(floatBitsToUint(seed));
}
vec2 hash2(vec2 seed)
{
    return hash2(floatBitsToUint(seed.x) ^ floatBitsToUint(seed.y));
}
vec2 hash2(vec3 seed)
{
    return hash2(floatBitsToUint(seed.x) ^ floatBitsToUint(seed.y) ^ floatBitsToUint(seed.z));
}
vec2 hash2(vec4 seed)
{
    return hash2(floatBitsToUint(seed.x) ^ floatBitsToUint(seed.y) ^ floatBitsToUint(seed.z) ^ floatBitsToUint(seed.w));
}

// 3D noise
vec3 hash3(uint seed)
{
    return vec3(hash1(seed), hash1(seed ^ 0x1u), hash1(seed ^ 0x2u));
}
vec3 hash3(float seed)
{
    return hash3(floatBitsToUint(seed));
}
vec3 hash3(vec2 seed)
{
    return hash3(floatBitsToUint(seed.x) ^ floatBitsToUint(seed.y));
}
vec3 hash3(vec3 seed)
{
    return hash3(floatBitsToUint(seed.x) ^ floatBitsToUint(seed.y) ^ floatBitsToUint(seed.z));
}
vec3 hash3(vec4 seed)
{
    return hash3(floatBitsToUint(seed.x) ^ floatBitsToUint(seed.y) ^ floatBitsToUint(seed.z) ^ floatBitsToUint(seed.w));
}

// 4D noise
vec4 hash4(uint seed)
{
    return vec4(hash1(seed), hash1(seed ^ 0x1u), hash1(seed ^ 0x2u), hash1(seed ^ 0x3u));
}
vec4 hash4(float seed)
{
    return hash4(floatBitsToUint(seed));
}
vec4 hash4(vec2 seed)
{
    return hash4(floatBitsToUint(seed.x) ^ floatBitsToUint(seed.y));
}
vec4 hash4(vec3 seed)
{
    return hash4(floatBitsToUint(seed.x) ^ floatBitsToUint(seed.y) ^ floatBitsToUint(seed.z));
}
vec4 hash4(vec4 seed)
{
    return hash4(floatBitsToUint(seed.x) ^ floatBitsToUint(seed.y) ^ floatBitsToUint(seed.z) ^ floatBitsToUint(seed.w));
}

// 1D-4D normalized direction noise
float hash_norm(float seed)
{
    return normalize(hash1(seed) - 0.5);
}
vec2 hash_norm(vec2 seed)
{
    return normalize(hash2(seed) - 0.5);
}
vec3 hash_norm(vec3 seed)
{
    return normalize(hash3(seed) - 0.5);
}
vec4 hash_norm(vec4 seed)
{
    return normalize(hash4(seed) - 0.5);
}

// simple noise
float simple_noise(vec2 uv)
{        
    vec2 cell = floor(uv);
    vec2 sub = uv - cell;
    
    vec2 cube = sub * sub * (3.0 - 2.0 * sub);
    
    vec2 c00 = cell + vec2(0.0, 0.0);
    vec2 c10 = cell + vec2(1.0, 0.0);
    vec2 c01 = cell + vec2(0.0, 1.0);
    vec2 c11 = cell + vec2(1.0, 1.0);
    
    return mix(mix(hash1(c00), hash1(c10), cube.x),
               mix(hash1(c01), hash1(c11), cube.x), cube.y);
}
float simple_noise(vec3 uvw)
{
    vec3 cell = floor(uvw);
    vec3 sub = uvw - cell;
    
    vec3 cube = sub * sub * (3.0 - 2.0 * sub);
    
    vec3 c000 = cell + vec3(0.0, 0.0, 0.0);
    vec3 c100 = cell + vec3(1.0, 0.0, 0.0);
    vec3 c010 = cell + vec3(0.0, 1.0, 0.0);
    vec3 c110 = cell + vec3(1.0, 1.0, 0.0);
    vec3 c001 = cell + vec3(0.0, 0.0, 1.0);
    vec3 c101 = cell + vec3(1.0, 0.0, 1.0);
    vec3 c011 = cell + vec3(0.0, 1.0, 1.0);
    vec3 c111 = cell + vec3(1.0, 1.0, 1.0);
    
    return mix(mix(mix(hash1(c000), 
                       hash1(c100), cube.x),
                   mix(hash1(c010), 
                       hash1(c110), cube.x), cube.y),
               mix(mix(hash1(c001), 
                       hash1(c101), cube.x),
                   mix(hash1(c011), 
                       hash1(c111), cube.x), cube.y), cube.z);
}

// cellular noise
float cellular_noise(vec2 uv, bool reverse)
{
    vec2 cell = floor(uv);
    float range_cell = 1.0;
    
    for(int x = -1; x <= 1; x++)
    for(int y = -1; y <= 1; y++)
    {
        vec2 nearby_cell = cell + vec2(x, y);
        vec2 direction = hash2(nearby_cell) + nearby_cell - uv;
        range_cell = min(range_cell, length(direction));
    }
    
    return 1.0 * float(reverse) + range_cell;
}
float cellular_noise(vec2 uv)
{
    return cellular_noise(uv, false);
}
float cellular_noise(vec3 uvw, bool reverse)
{
    vec3 cell = floor(uvw);
    float range_cell = 1.0;
    
    for(int x = -1; x <= 1; x++)
    for(int y = -1; y <= 1; y++)
    for(int z = -1; z <= 1; z++)
    {
        vec3 nearby_cell = cell + vec3(x, y, z);
        vec3 direction = hash3(nearby_cell) + nearby_cell - uvw;
        range_cell = min(range_cell, length(direction));
    }
    
    return  1.0 * float(reverse) + range_cell;
}
float cellular_noise(vec3 uvw)
{
    return cellular_noise(uvw, false);
}

// gradient noise
float gradient_noise(vec2 uv, float smooth_range)
{
    vec2 cell = floor(uv);
    vec2 sub = uv - cell;
    
    vec2 quint = sub * sub * sub * (sub * (sub * 6.0 - 15.0) + 10.0);
    
    float c00 = dot(hash_norm(cell), sub);
    float c01 = dot(hash_norm(cell + vec2(0.0, 1.0)), sub - vec2(0.0, 1.0));
    float c10 = dot(hash_norm(cell + vec2(1.0, 0.0)), sub - vec2(1.0, 0.0));
    float c11 = dot(hash_norm(cell + vec2(1.0, 1.0)), sub - vec2(1.0, 1.0));

    float noise = mix(mix(c00, c01, quint.y),
                      mix(c10, c11, quint.y), quint.x);
    
    return noise * (1.0 - smooth_range) + smooth_range;
}
float gradient_noise(vec2 uv)
{
    return gradient_noise(uv, 0.5);
}
float gradient_noise(vec3 uvw, float smooth_range)
{
    vec3 cell = floor(uvw);
    vec3 sub = uvw - cell;
    
    vec3 quint = sub * sub * sub * (sub * (sub * 6.0 - 15.0) + 10.0);
    
    float c000 = dot(hash_norm(cell + vec3(0.0, 0.0, 0.0)), sub - vec3(0.0, 0.0, 0.0));
    float c100 = dot(hash_norm(cell + vec3(1.0, 0.0, 0.0)), sub - vec3(1.0, 0.0, 0.0));
    float c010 = dot(hash_norm(cell + vec3(0.0, 1.0, 0.0)), sub - vec3(0.0, 1.0, 0.0));
    float c110 = dot(hash_norm(cell + vec3(1.0, 1.0, 0.0)), sub - vec3(1.0, 1.0, 0.0));
    float c001 = dot(hash_norm(cell + vec3(0.0, 0.0, 1.0)), sub - vec3(0.0, 0.0, 1.0));
    float c101 = dot(hash_norm(cell + vec3(1.0, 0.0, 1.0)), sub - vec3(1.0, 0.0, 1.0));
    float c011 = dot(hash_norm(cell + vec3(0.0, 1.0, 1.0)), sub - vec3(0.0, 1.0, 1.0));
    float c111 = dot(hash_norm(cell + vec3(1.0, 1.0, 1.0)), sub - vec3(1.0, 1.0, 1.0));
    
    float noise = mix(mix(mix(c000, c100, quint.x),
                          mix(c010, c110, quint.x), quint.y),
                      mix(mix(c001, c101, quint.x),
                          mix(c011, c111, quint.x), quint.y), quint.z);
    
    return noise * (1.0 - smooth_range) + smooth_range;
}
float gradient_noise(vec3 uvw)
{
    return gradient_noise(uvw, 0.5);
}

// noise library: 1-simple, 2-cellular, 3-gradient
float noise_library(int num_noise, vec2 uv)
{ 
    switch(num_noise)
    {
        default: case(1): return simple_noise(uv);
        case(2): return cellular_noise(uv);
        case(3): return gradient_noise(uv);
    }
}
float noise_library(int num_noise, vec3 uvw)
{ 
    switch(num_noise)
    {
        default: case(1): return simple_noise(uvw);
        case(2): return cellular_noise(uvw);
        case(3): return gradient_noise(uvw);
    }
}

// isoline noise(form)
float isoline_form(float noise, float wave)
{
    return noise * (cos(pow(2.0, wave) * noise));
}
float isoline_form(float noise)
{
    return noise * (cos(noise * 64.0));
}

// fractal noise(form)
float fractal_form(int num_noise, vec2 uv, float num_octaves, float scale)
{
    float noise_sum = 0.0;
    float weight_sum = 0.0;
    float weight = 1.0;

    for(float octave = 0.0; octave < num_octaves; octave++)
    {
        noise_sum += noise_library(num_noise, uv * pow(2.0, octave) * scale)  * weight;
        weight_sum += weight;
        weight *= 0.5;
    }
    
    return noise_sum / weight_sum;
}
float fractal_form(int num_noise, vec2 uv)
{
    return fractal_form(num_noise, uv, 4.0, 0.5); 
}
float fractal_form(int num_noise, vec3 uvw, float num_octaves, float scale)
{
    float noise_sum = 0.0;
    float weight_sum = 0.0;
    float weight = 1.0;

    for(float octave = 0.0; octave < num_octaves; octave++)
    {
        noise_sum += noise_library(num_noise, uvw * pow(2.0, octave) * scale)  * weight;
        weight_sum += weight;
        weight *= 0.5;
    }
    
    return noise_sum / weight_sum;
}
float fractal_form(int num_noise, vec3 uvw)
{
    return fractal_form(num_noise, uvw, 4.0, 0.5); 
}

const vec2 tiling = vec2(20.0, 12.0);
const vec2 offset = vec2(0.0, 0.0);

vec2 transform(vec2 uv, vec2 tiling, vec2 offset)
{
    return uv * tiling + offset;
}
vec2 transform(vec2 uv)
{
    return transform(uv, tiling, offset);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float speed = time * 0.5;
    float view = 0.0;
    vec2 tile2D = vec2(transform(uv));
    vec3 tile3D = vec3(tile2D, speed);
    
    tile2D.x += speed;
    
    switch (int(gl_FragCoord.xy.y / resolution.y * 4.0))
    {
        case 0:
        {
            switch (int(gl_FragCoord.xy.x / resolution.x * 6.0)) 
            {
                case 0:
                    view = isoline_form(fractal_form(1, tile2D));
                    break;
                case 1:
                    view = isoline_form(fractal_form(1, tile3D));
                    break;
                case 2:
                    view = isoline_form(fractal_form(2, tile2D));
                    break;
                case 3:
                    view = isoline_form(fractal_form(2, tile3D));
                    break;
                case 4:
                    view = isoline_form(fractal_form(3, tile2D));
                    break;
                case 5:
                    view = isoline_form(fractal_form(3, tile3D));
                    break;
            }
        } break;
        
        case 1:
        {
            switch (int(gl_FragCoord.xy.x / resolution.x * 6.0)) 
            {
                case 0:
                    view = fractal_form(1, tile2D);
                    break;
                case 1:
                    view = fractal_form(1, tile3D);
                    break;
                case 2:
                    view = fractal_form(2, tile2D);
                    break;
                case 3:
                    view = fractal_form(2, tile3D);
                    break;
                case 4:
                    view = fractal_form(3, tile2D);
                    break;
                case 5:
                    view = fractal_form(3, tile3D);
                    break;
            }
        } break;        
        
        case 2:
        {
            switch (int(gl_FragCoord.xy.x / resolution.x * 6.0)) 
            {
                case 0:
                    view = isoline_form(simple_noise(tile2D));
                    break;
                case 1:
                    view = isoline_form(simple_noise(tile3D));
                    break;
                case 2:
                    view = isoline_form(cellular_noise(tile2D));
                    break;
                case 3:
                    view = isoline_form(cellular_noise(tile3D));
                    break;
                case 4:
                    view = isoline_form(gradient_noise(tile2D));
                    break;
                case 5:
                    view = isoline_form(gradient_noise(tile3D));
                    break;
            }
        } break;
        
        case 3:
        {
            switch (int(gl_FragCoord.xy.x / resolution.x * 6.0)) 
            {
                case 0:
                    view = simple_noise(tile2D);
                    break;
                case 1:
                    view = simple_noise(tile3D);
                    break;
                case 2:
                    view = cellular_noise(tile2D);
                    break;
                case 3:
                    view = cellular_noise(tile3D);
                    break;
                case 4:
                    view = gradient_noise(tile2D);
                    break;
                case 5:
                    view = gradient_noise(tile3D);
                    break;
            }
        } break;
    }

    glFragColor = vec4(vec3(view), 1.0);
}
