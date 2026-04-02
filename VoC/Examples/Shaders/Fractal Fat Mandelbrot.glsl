#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WlBfRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Robert Śmietana (Logos) - 05.09.2020
// Bielsko-Biała, Poland, UE, Earth, Sol, Milky Way, Local Group, Laniakea :)

//--- program parameters ---//

const float K    = 100.0;            // iteration count
const float IK    = 1.0/K;

vec2 rot(vec2 z, float a)
{
    return vec2(z.x*cos(a) - z.y*sin(a), z.y*cos(a) + z.x*sin(a));
}

vec2 cmul(vec2 z1, vec2 z2)
{
    return vec2(z1.x*z2.x - z1.y*z2.y, z1.x*z2.y + z1.y*z2.x);
}

vec2 cdiv(vec2 z1, vec2 z2)
{
    vec2 conj = vec2(z2.x, -z2.y);
    return cmul(z1, conj)/dot(z2, z2);
}

//--- fractal recipe ---//

vec3 getColor(vec2 p)
{
    float    i = 0.0;
    vec2    z = vec2(0.0);
    float    l = 110.0 + 100.0*sin(1.6*time);
    
    
    //- calculate iteration count -//
    
    for (; i < K; i++)
    {
        z = cmul(z, z) + p;
        z = cdiv(z, p) + p;
        
        if (dot(z, z) > l) break;
    }

    
    //- return "inside" color -//
    
    if (i == 100.0) return vec3(1.0, 0.5 + z.x/p.x, 0.15 + 0.15*cos(4.0*time));
    
    
    //- return "outside" color -//
    
    vec3    c = ((int(i) % 2) == 0)? vec3(0.0) : vec3(1.0, 0.5, 0.0);
    vec2    w = rot(z, time);
    
    return    w.x > 0.0?
            w.y > 0.0?
        
            vec3(0.5) : vec3(1.0) : c;
}

//--- calculate pixel color ---//

void main(void)
{
    
    //- point coordinates -//
    
    float    zoom    = 1.5;
    vec2    z        = zoom * (gl_FragCoord.xy - resolution.xy / 2.0) / resolution.y;
            z        = z.yx + vec2(-0.97 + 0.03*sin(1.0*time + 5.0*z.y), 0.03*cos(0.9*time + 4.0*z.x));
    
    
    //- AA section -//
    
    float     a        =      2.0;
    float     e        =        1.0 / min(resolution.x, resolution.y);    
    vec3    c        = vec3(0.0);
    
    for (float j = -a; j < a; j++)
        for (float i = -a; i < a; i++)
            c += getColor(z + 0.5*zoom*vec2(i, j) * (e/a)) / (4.0*a*a);
    
        
    //- return final color -//
        
    glFragColor = vec4(c, 1.0);
    
}
