#version 420

// original https://www.shadertoy.com/view/3sffz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Robert Śmietana (Logos) - 24.04.2020
// Dobrzyca, Poland, UE, Earth, Sol, Milky Way, Local Group, Laniakea :)

//--- some globals ---//

vec3 orbitTrap = vec3(10000.0);

//--- camera stuff ---//

mat3 setCamera(in vec3 ro, in vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(0.0, 1.0, 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));

    return mat3(cu, cv, cw);
}

//--- scene description ---//

vec2 rotate(vec2 v, float a)
{
    float ca = cos(a);
    float sa = sin(a);
    
    return vec2(ca*v.x + sa*v.y, -sa*v.x + ca*v.y);
}

float spring_cyl(vec3 p)
{
    bool b = mod(time, 5.0) > 2.5;
    
    p.xy  = rotate(b ? p.xy : p.yz, (1.5 + 0.05*sin(17.0*time - 2.1*p.z)) * p.z);
    p.xy -= vec2(-0.63564, -0.75968);

    return max(abs(p.z) - 10.0, length(p.xy) - 0.14414);
}

float c3(vec3 p)
{
    return min(spring_cyl(p), spring_cyl(p.zyx));
}

float distanceToScene(vec3 pos)
{
    float d = 10000.0;
    vec4  p = vec4(pos, 0.0);
    vec4 dp = vec4(1.0, 0.0, 0.0, 0.0);
    vec4  C = vec4(0.0303, -0.0303, 0.01516, 0.21);
    
    for (int i = 0; i < 6; i++)
    {
        dp = 2.0*vec4(p.x*dp.x - dot(p.yzw, dp.yzw), p.x*dp.yzw + dp.x*p.yzw + cross(p.yzw, dp.yzw));
        p = vec4(p.x*p.x - dot(p.yzw, p.yzw), vec3(2.0*p.x*p.yzw)) + C;

        float r = c3(p.yxz);
        d = min(d, 0.5 * r / length(dp));

        float p2 = dot(p, p);
        orbitTrap = min(orbitTrap, abs(p.zxy));
        if (p2 > 14.286) break;
    }

    return 0.45*min(d, length(pos) - 0.9771);
}

//--- cheap normal computing ---//

vec3 computeSurfaceNormal(vec3 p)
{
    float d = distanceToScene(p);
    
    return normalize(vec3(
        distanceToScene(p + vec3(0.001, 0.0, 0.0)) - d,
        distanceToScene(p + vec3(0.0, 0.001, 0.0)) - d,
        distanceToScene(p + vec3(0.0, 0.0, 0.001)) - d));
}

//--- output color ---//

void main(void)
{
    
    //--- camera setup ---//
    
    float rtime = 0.32165*time;
    
    vec2 p   = (-resolution.xy + 2.0*gl_FragCoord.xy - 1.0) / resolution.y;
     vec3 pos = vec3(25.0*cos(rtime), 25.0*sin(rtime), 10.0);
    vec3 tar = vec3(0.0);
    vec3 dir = setCamera(pos, tar) * normalize(vec3(p.xy, 11.6));  
    
    
    //--- distance to nearest object in the scene ---//
    
    float t = 0.0;
    for(int i = 0; i < 256; i++)
    {
        float d = distanceToScene(pos + t*dir);
        if(d < 0.0023) break;
        
        t += d;

        
        //--- early skip of background pixels ---//
    
        if (t > 35.0)
        {
            glFragColor = vec4(1.0);
            return;
        }
    }
    
    
    //--- output color depends on few things ---//
    
    //bool   b = mod(time, 4.0) > 2.0;
    vec3  sn = computeSurfaceNormal(pos + t*dir);            // surface normal
    float dc = clamp(dot(sn, normalize(pos)), 0.0, 1.0);    // diffuse component
    float sr = pow(dc, 56.2);                                // specular reflection
    
    glFragColor     = 0.4*orbitTrap.xyzz;
    glFragColor    *= 0.75 + 0.5*dc;
    glFragColor    += sr;
    
}
