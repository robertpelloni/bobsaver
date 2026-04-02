#version 420

// original https://www.shadertoy.com/view/wlsSzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define LAYERS_COUNT 14.0
#define SIZE_MOD 1.5
#define ALPHA_MOD 0.93
#define FRONT_BLEND_DISTANCE 1.0
#define BACK_BLEND_DISTANCE 4.0
#define PARTICLE_SIZE 0.045
#define FOV 1.0

#define TIME (time * 0.4)

float hash12(vec2 x)
{
     return fract(sin(dot(x, vec2(43.5287, 41.12871))) * 523.582);   
}

vec2 hash21(float x)
{
     return fract(sin(x * vec2(24.0181, 52.1984)) * 5081.4972);   
}

vec2 rotate(vec2 point, float angle)
{
     float s = sin(angle);
    float c = cos(angle);
    return point * mat2(s, c, -c, s);
}

//Random point from [rootUV] to [rootUV + 1.0]
vec2 particleCoordFromRootUV(vec2 rootUV)
{
    return rotate(vec2(0.0, 1.0), time * 3.0 * (hash12(rootUV) - 0.5)) * (0.5 - PARTICLE_SIZE) + rootUV + 0.5;
}

//particle shape
float particleFromParticleUV(vec2 particleUV, vec2 uv)
{
     return 1.0 - smoothstep(0.0, 0.01, abs(PARTICLE_SIZE - length(particleUV - uv)));   
}

//grid based particle layer
float particlesLayer(vec2 uv, float seed)
{
       uv = uv + hash21(seed) * 10.0;
    vec2 rootUV = floor(uv);
    vec2 particleUV = particleCoordFromRootUV(rootUV);
    float particles = particleFromParticleUV(particleUV, uv);
    return particles;
}

float layerScaleFromIndex(float index)
{
     return index * SIZE_MOD;  //Can be optimized by removing pow
}

float layeredParticles(vec2 screenUV, vec3 cameraPos)
{
    screenUV *= FOV;
    float particles = 0.0;
    float alpha = 1.0;
    float previousScale = 0.0;
    float targetScale = 1.0;
    float scale = 0.0;
    
    //Painting layers from front to back
    for (float i = 0.0; i < LAYERS_COUNT; i += 1.0)
    {
        //depth offset
        float offset = fract(cameraPos.z);
        
        //blending back and front
        float blend = smoothstep(0.0, FRONT_BLEND_DISTANCE, i - offset + 1.0);
        blend *= smoothstep(0.0, -BACK_BLEND_DISTANCE, i - offset + 1.0 - LAYERS_COUNT);
        
        float fog = mix(alpha * ALPHA_MOD, alpha, offset) * blend;
        
        targetScale = layerScaleFromIndex(i + 1.0);
        
        //dynamic scale - depends on depth offset
        scale = mix(targetScale, previousScale, offset);
        
        //adding layer
         particles += particlesLayer(screenUV * scale + cameraPos.xy, floor(cameraPos.z) + i) * fog;
        alpha *= ALPHA_MOD;
        previousScale = targetScale;
    }
    
    return particles;
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.x;
    
    //smooth camera movement
     vec3 cameraPos = vec3(cos(time * 0.096) * 60.0,
                          cos(time * 0.06 + 1.0) * 30.0, 
                          -cos(time * 0.1 + 1.0) * 40.0);
    
    float particles = layeredParticles(uv, cameraPos);
    glFragColor = vec4(particles);
}
