#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/sd3Szs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//----------------------------------------------------
// PERLIN_NOISE_GENERATOR
//----------------------------------------------------

float fade(float t)
{
    return t * t * t * (t * ((t * 6.0f) - 15.0f) + 10.0f);
}

float grad(int hash, float x, float y, float z)
{
    int h = hash & 15;
    // Convert lower 4 bits of hash into 12 gradient directions
    float u = (h < 8) ? x : y,
           v = ((h < 4) ? y : (h == 12 || h == 14 ? x : z));
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
}

int[512] p=int[512](151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142,
             8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117,
             35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71,
             134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41,
             55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89,
             18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226,
             250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182,
             189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167,
             43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246,
             97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239,
             107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254,
             138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180,
             151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142,
             8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117,
             35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71,
             134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41,
             55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89,
             18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226,
             250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182,
             189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167,
             43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246,
             97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239,
             107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254,
             138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180);

// Returns noise value for position
float noise(float x, float y, float z)
{  
    // Find the unit cube that contains the point
    int X = int(floor(x)) & 255;
    int Y = int(floor(y)) & 255;
    int Z = int(floor(z)) & 255;

    // Find relative x, y,z of point in cube
    x -= floor(x);
    y -= floor(y);
    z -= floor(z);
    
    // Compute fade curves for each of x, y, z
    float u = fade(x);
    float v = fade(y);
    float w = fade(z);

    // Hash coordinates of the 8 cube corners
    int A = p[X] + Y;
    int AA = p[A] + Z;
    int AB = p[A + 1] + Z;
    int B = p[X + 1] + Y;
    int BA = p[B] + Z;
    int BB = p[B + 1] + Z;

    // Add blended results from 8 corners of cube
    float res = mix(
        mix(
            mix(grad(p[AA], x, y, z),
                 grad(p[BA], x - 1.0f, y, z),
                 u),
            mix(grad(p[AB], x, y - 1.0f, z),
                 grad(p[BB], x - 1.0f, y - 1.0f, z),
                 u),
            v),
        mix(
            mix(grad(p[AA + 1], x, y, z - 1.0f),
                 grad(p[BA + 1], x - 1.0f, y, z - 1.0f),
                 u),
            mix(grad(p[AB + 1], x, y - 1.0f, z - 1.0f),
                 grad(p[BB + 1], x - 1.0f, y - 1.0f, z - 1.0f),
                 u),
            v),
        w);
    return (res + 1.0f) / 2.0f;
}
//----------------------------------------------------
//----------------------------------------------------

//----------------------------------------------------
// OCTAVE_NOISE_GENERATOR
//----------------------------------------------------
#define IMAGE_ROWS 50
#define SCALE 17.5f
#define SCALE_FROM_CENTER 1
#define LEVEL_OF_DETAIL 0
#define SMOOTH_INVERSE_LERP 1
#define OCTAVES 4
#define PERSISTANCE 0.5f
#define LACUNARITY 2.0f
#define NORMALIZE_OFFSET 1

// Inverse Lerp Function
float linear_step(float l, float u, float a)
{
    return clamp(((a - l) / (u - l)), 0.0f, 1.0f);
}

// Gets the perlin noise for point b/w 0.0 and 1.0
float perlin(vec2 pos)
{
    return noise(pos.x, pos.y, 0.0f);
}

float get_octave_noise(vec2 pos)
{
    float rows = float(IMAGE_ROWS);
    pos *= rows;
    float columns = rows * (resolution.x / resolution.y);
    float scale = float(SCALE);
    if(scale <= 0.0f)
    {
        scale = 0.001f;
    }
    
    int octaves = int(OCTAVES);
    float lacunarity = max(LACUNARITY, 1.0f);
    float persistence = min(PERSISTANCE, 1.0f);
    
    float halfX = 0.0f;
    float halfY = 0.0f;
#if SCALE_FROM_CENTER
    halfX = columns / 2.0f;
    halfY = rows / 2.0f;
#endif

    float amplitude = 1.0f;
    float frequency = 1.0f;
    float noiseVal = 0.0f;
    
    // Add LODs
#if LEVEL_OF_DETAIL
    pos /= float(LEVEL_OF_DETAIL);
    pos = vec2(floor(pos.x), floor(pos.y));
    pos *= float(LEVEL_OF_DETAIL);
#endif

    vec2 offset = 3.0f * vec2(time * 0.00f, time * -1.25f);
    
    for (int i = 0; i < octaves; i++)
    {
#if NORMALIZE_OFFSET
        float sampleX = (((pos.x-halfX) / scale) * frequency) + offset.x;
        float sampleY = (((pos.y-halfY) / scale) * frequency) + offset.y;
#else
        float sampleX = (((pos.x-halfX + offset.x*scale) / scale) * frequency);
        float sampleY = (((pos.y-halfY + offset.y*scale) / scale) * frequency);
#endif
        float noise = (perlin(vec2(sampleX, sampleY)) * 2.0f) - 1.0f;
        noiseVal += noise * amplitude;
        // Decrease A and increase F
        amplitude *= persistence;
        frequency *= lacunarity;
    }    

    // Inverser lerp so that noiseval lies between 0 and 1 
#if SMOOTH_INVERSE_LERP
    noiseVal = smoothstep(-0.95f, 1.1f, noiseVal);
#else
    noiseVal = linear_step(-0.7f,0.85f,noiseVal);
#endif
    return noiseVal;
}
//----------------------------------------------------
//----------------------------------------------------

//----------------------------------------------------
// FRACTAL_NOISE_GENERATOR
//----------------------------------------------------
#define SHARPNESS 3.5f
#define OFFSET 1.0f

float get_fractal_noise(vec2 pos)
{
    float rows = float(IMAGE_ROWS);
    pos *= rows;
    float columns = rows * (resolution.x / resolution.y);
    float scale = float(SCALE);
    if(scale <= 0.0f)
    {
        scale = 0.001f;
    }
    
    int octaves = int(OCTAVES);
    float lacunarity = max(LACUNARITY, 1.0f);
    float persistence = min(PERSISTANCE, 1.0f);
    
    float halfX = 0.0f;
    float halfY = 0.0f;
#if SCALE_FROM_CENTER
    halfX = columns / 2.0f;
    halfY = rows / 2.0f;
#endif

    float amplitude = 1.0f;
    float frequency = 1.0f;
    float noiseVal = 0.0f;
    
    // Add LODs
#if LEVEL_OF_DETAIL
    pos /= float(LEVEL_OF_DETAIL);
    pos = vec2(floor(pos.x), floor(pos.y));
    pos *= float(LEVEL_OF_DETAIL);
#endif

    vec2 offset = 1.0f * vec2(time * 0.0f, time * -1.25f);
    vec2 shift=vec2(45.0f);
    mat2 rot = mat2(cos(1.5), sin(1.5),
                    -sin(1.5), cos(1.5));
    
    for (int i = 0; i < octaves; i++)
    {
#if NORMALIZE_OFFSET
        float sampleX = (((pos.x-halfX) / scale) * frequency) + offset.x;
        float sampleY = (((pos.y-halfY) / scale) * frequency) + offset.y;
#else
        float sampleX = (((pos.x-halfX + offset.x*scale) / scale) * frequency);
        float sampleY = (((pos.y-halfY + offset.y*scale) / scale) * frequency);
#endif
        float noise = (perlin(vec2(sampleX, sampleY)) * 2.0f) - 1.0f;
        noiseVal += abs(noise) * amplitude;
        // Decrease A and increase F
        amplitude *= persistence;
        frequency *= lacunarity;
        pos=pos*rot+shift;
    }

    // Inverser lerp so that noiseval lies between 0 and 1 
    noiseVal=linear_step(0.0f,1.5f,noiseVal);
    return noiseVal;
}

float get_fractal_height(vec2 pos)
{
    float h=get_fractal_noise(pos);
    h = OFFSET-h;
    h = pow(h,SHARPNESS);
    return h;
}
//----------------------------------------------------
//----------------------------------------------------
vec2 xLimits=vec2(-0.75f,0.75f);
vec2 cCenter=vec2(0.0f,-0.6f);
float cRadius=1.0f;
vec3 darkCol=vec3(0.6f,0.1f,0.0f);
vec3 lightCol=vec3(1.0f,0.7f,0.0f);

vec3 get_color(vec2 pos)
{
    // Get Height Map
    float h=get_octave_noise(pos);
    h=pow(h,1.1f);
    
    // Get Fractal height
    float fH=get_fractal_height(pos);
    
    // Limits on X
    vec2 limits=xLimits+vec2(pos.y+0.3f,-(pos.y+0.3f));
    if((pos.x<limits.x || pos.x<xLimits.x) ||(pos.x>limits.y || pos.x>xLimits.y))
    {
        h=0.0f;
    }
    
    
    // Get Circle limits
    float h2=distance(pos,cCenter)/cRadius;
    h2=smoothstep(0.0f,cRadius,h2);
    h2=1.0f-h2;
    
    // Apply circle's alpha map
    h2*=h;
    
    // Apply Fractal distortion
    h2*=fH;
    h2=smoothstep(0.0f,0.3f,h2);
    
    // Apply threshold
    if(h2<0.15f)
    {
        h2=0.0f;
    }
    
    // Set Final Color
    vec3 col=vec3(0.05f);
    if(h2>0.0f)
    {
        col=mix(darkCol,lightCol,h2);
    }
    return col;
}

void main(void)
{
    // Get UVs
    vec2 uv=gl_FragCoord.xy/resolution.xy;
    uv=uv*2.0f-1.0f;
    uv.x*=resolution.x/resolution.y;
    
    // Get Color
    vec3 col=get_color(uv);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
