#version 420

// original https://www.shadertoy.com/view/WtVSWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Robert Śmietana (Logos) - 11.03.2020
// Bielsko-Biała, Poland, UE, Earth, Sol, Milky Way, Local Group, Laniakea :)

//--- camera stuff ---//

mat3 setCamera(in vec3 ro, in vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(0.0, 1.0, sin(0.59*time));
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));

    return mat3(cu, cv, cw);
}

//--- scene description ---//

float distanceToScene(vec3 p)
{
    float dp = dot(p, p);
    
    p *= 3.0 / dp;
    p  = sin(3.0*p + time*vec3(0.0, -4.0, 0.0));

    float d = min(length(p.xz) - 0.15, length(p*p) - 0.1);

    return 0.6*d * dp*0.111111;
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
    
    float rtime = 0.35*time;
    
    vec2 p   = (-resolution.xy + 2.*gl_FragCoord.xy - 1.)/resolution.y;
     vec3 pos = vec3(5.0 + 5.0*cos(rtime), 10.0*cos(1.2*rtime), 6.0 + 5.0*sin(0.78*rtime));
    vec3 tar = vec3(0.0);
    vec3 dir = setCamera(pos, tar) * normalize(vec3(p.xy, 11.6));  
    
    
    //--- distance to nearest object in the scene ---//
    
    float t = 0.0;
    for(int i = 0; i < 210; i++)
    {
        float d = distanceToScene(pos + t*dir);
        if(d < 0.003) break;
        
        t += d;

        
        //--- early skip of background pixels ---//
    
        if (t > 27.0)
        {
            glFragColor = vec4(0.0);
            return;
        }
    }
    
    
    //--- output color depends on few things ---//
    
    vec3   n = computeSurfaceNormal(pos + t*dir);            // surface normal
    float di = clamp(dot(n, normalize(pos)), 0.0, 1.0);        // diffuse component
    float re = pow(di, 100.0);                                // specular reflection
    float od = length(pos + t*dir);                            // distance to origin
    
    glFragColor     = abs(dir.xzyz);
    glFragColor    *= 0.2 + 0.8*di;
    glFragColor.yz *= clamp(od, 0.0, 1.0);
    glFragColor    += re;
    
}
