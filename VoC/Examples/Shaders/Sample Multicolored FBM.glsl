#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ttjGRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Slow, high-quality 2D hash adapted from nimitz's
// WebGL2 hash collection
// (https://www.shadertoy.com/view/Xt3cDn)
vec2 hash22(uvec2 p)
{
    const uint PRIME32_2 = 2246822519U, PRIME32_3 = 3266489917U;
    const uint PRIME32_4 = 668265263U, PRIME32_5 = 374761393U;
    uint h32 = p.y + PRIME32_5 + p.x*PRIME32_3;
    h32 = PRIME32_4*((h32 << 17) | (h32 >> (32 - 17))); //Initial testing suggests this line could be omitted for extra perf
    h32 = PRIME32_2*(h32^(h32 >> 15));
    h32 = PRIME32_3*(h32^(h32 >> 13));
    h32 = h32^(h32 >> 16);
    uvec2 rz = uvec2(h32, h32*48271U);
    return vec2(rz.xy & uvec2(0x7fffffffU)) / float(0x7fffffff);
}

// Specialty Perlin ease-in/out function
vec2 soften(vec2 t)
{
    vec2 t3 = t * t * t;
    vec2 t4 = t3 * t;
    vec2 t5 = t4 * t;
    return 6.0f * t5 - 
           15.0f * t4 +
           10.0f * t3;
}

// Perlin noise function, taking corner + pixel positions as input
float Perlin(vec2 uv)
{
    // Find corner coordinates
    vec4 lwrUpr = vec4(floor(uv), ceil(uv));
    mat4x2 crnrs = mat4x2(lwrUpr.xw, lwrUpr.zw,
                          lwrUpr.xy, lwrUpr.zy);
    
    // Generate gradients at each corner
    mat4x2 dirs = mat4x2(hash22(uvec2(floatBitsToUint(crnrs[0]))),
                         hash22(uvec2(floatBitsToUint(crnrs[1]))),
                         hash22(uvec2(floatBitsToUint(crnrs[2]))),
                         hash22(uvec2(floatBitsToUint(crnrs[3]))));
    
    // Shift gradients into [-1...0...1]
    dirs *= 2.0f;
    dirs -= mat4x2(vec2(1.0f), vec2(1.0f), 
                   vec2(1.0f), vec2(1.0f));
    
    // Normalize
    dirs[0] = normalize(dirs[0]);
    dirs[1] = normalize(dirs[1]);
    dirs[2] = normalize(dirs[2]);
    dirs[3] = normalize(dirs[3]);
        
    // Find per-cell pixel offset
    vec2 offs = mod(uv, 1.0f);
    
    // Compute gradient weights for each corner; take each offset relative
    // to corners on the square in-line
    vec4 values = vec4(dot(dirs[0], (offs - vec2(0.0f, 1.0f))),
                       dot(dirs[1], (offs - vec2(1.0f))),
                       dot(dirs[2], (offs - vec2(0.0f))),
                       dot(dirs[3], (offs - vec2(1.0f, 0.0f))));
    
    // Return smoothly interpolated values
    vec2 softXY = offs;//soften(offs);
    return mix(mix(values.z, 
                   values.w, softXY.x),
               mix(values.x, 
                   values.y, softXY.x),
               softXY.y);
}

// Compute fractal noise for a given pixel position
#define SCALING_FBM
//#define EXTRA_TRIG_FX
float fbm(vec2 uv)
{
    const uint depth = 6u;
    const vec2 dFreq = vec2(1.01f, 1.02f);
    const float dAmpl = 1.2f;
    float srct = time + 100.0f;
    float t = min((srct * (0.075 / log(srct)) + sin(srct * 0.01)), 400.0);
    vec2 sfreq = vec2(1.01f + (sin(t) * 2.0)); // Starting noise scaling frequency
    vec2 rfreq = vec2(1.1f); // Starting noise rotational frequency
    float ampl = 0.25f; // Starting noise intensity
    float f = 0.0f;
    for (uint i = 0u; i < depth; i += 1u)
    {
        f += ampl * Perlin(uv);//abs(Perlin(uv));
        float fi = float(i);
        #ifdef EXTRA_TRIG_FX
            uv += vec2(cos(fi), 
                       sin(fi)) * (time * 0.25f) * rfreq;
        #endif
        //uv += vec2(t);
        #ifdef SCALING_FBM
            uv += pow(t, dot(sfreq, rfreq) * 0.25);
            sfreq *= dFreq + vec2(0.1f * float(i));
        #endif
        rfreq *= dFreq + vec2(0.1f * float(i));
        ampl *= dAmpl;
    }
    return f;
}

#define NOISE_MIRR
void main(void)
{
    // Normalized pixel coordinates (from 0 to [1.0 / [cellSize]])
    const float cellSize = 0.0825f;
    #ifdef NOISE_MIRR
        float hAspect = (resolution.x / resolution.y) * 0.5f;
        vec2 uv = abs((gl_FragCoord.xy / resolution.y) - vec2(hAspect, 0.5f)) / cellSize;
    #else
        vec2 uv = (gl_FragCoord.xy / resolution.y) / cellSize;
    #endif
    //uv += (vec2(0.1) + texture(iChannel1, uv).rr) * 0.1;
    // Generate per-channel fbm()
    // fbm(p + fbm(p + fbm(p)))
    // FBM recursion function from iq through the Book of Shaders:
    // http://www.iquilezles.org/www/articles/warp/warp.htm
    // https://thebookofshaders.com/13/
    float fbm0 = fbm(uv + vec2(
                     fbm(uv + vec2(
                         fbm(uv)))));
    vec2 uu = uv + vec2(sin(time), fbm0);
    float fbm1 = fbm(uu + vec2(
                     fbm(uu + vec2(
                         fbm(uv)))));
    vec2 vv = uv + vec2(cos(time) * fbm1, fbm1 + fbm0);
    float fbm2 = fbm(vv + vec2(
                     fbm(vv + vec2(
                         fbm(vec2(fbm0, fbm1))))));
    vec3 rgb = vec3(fbm0, fbm1, fbm2);
    
    // Output to screen
    glFragColor = vec4(rgb, 1.0);
}
