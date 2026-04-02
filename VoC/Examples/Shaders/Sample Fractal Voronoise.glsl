#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3tG3D3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Remove for just the noise
//#define SWEEP

// Hash without Sine 2 - https://www.shadertoy.com/view/XdGfRR
#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1.0 / float(0xffffffffU))

vec2 hash22(vec2 p)
{
    uvec2 q = uvec2(ivec2(p))*UI2;
    q = (q.x ^ q.y) * UI2;
    return vec2(q) * UIF;
}

vec3 hash33(vec3 p)
{
    uvec3 q = uvec3(ivec3(p)) * UI3;
    q = (q.x ^ q.y ^ q.z)*UI3;
    return vec3(q) * UIF;
}

// -    -    -    -    -    -    -    -

float calcVoro31(vec3 p)
{
    vec3 cellPos = fract(p);
    vec3 cellId = floor(p);
    
    float len = 2.0;
    
    for (int z = -1; z < 2; z++)
    for (int y = -1; y < 2; y++)
    for (int x = -1; x < 2; x++)
    {
        vec3 offs = vec3(x, y, z);
        len = min(len, length(cellPos + offs - hash33(cellId - offs)));
    }
    
    return len;
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

    vec3 col = vec3(0);
    
    vec3 p = vec3(uv, time / 4.0);
    
    float res;
    float scale = 0.5;
    
    for(int i = 0; i < 3; i++)
    {
        res += calcVoro31(p / scale) * scale;
        scale *= 0.5;
    }
    
    #ifdef SWEEP
    res = step(sin(time) / 4.0 + 0.25, res);
    #endif
    
    col.rgb = vec3(res);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
