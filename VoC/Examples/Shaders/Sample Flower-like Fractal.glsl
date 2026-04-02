#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3dScRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Source Material:
// Great source for all kinds of computer graphics stuff: http://iquilezles.org/
// Fractals: http://blog.hvidtfeldts.net/index.php/2011/06/distance-estimated-3d-fractals-part-i/

// Videos:
// Ray marching setup and HDR colors: https://www.youtube.com/watch?v=Cfe5UQ-1L9Q
// SDF maths: https://www.youtube.com/watch?v=sl9x19EnKng

float boxSDF(in vec3 p, in vec3 r)
{
    return length(max(abs(p) - r, 0.0));
}

vec3 fold3(in vec3 p, in vec3 n)
{
    return p - 2.0 * min(0.0, dot(p, n)) * n;
}

// Signed distance function that describes the scene
float sceneSDF(in vec3 pos)
{    
    for (int i = 0; i < 15; ++i)
    {
        float t = float(i) * 1.0 + cos(time) * 0.18;
        vec3 n = normalize(vec3(cos(t), sin(t), sin(t)));
        
        pos = fold3(pos, n);
        
        if (i % 2 == 0)
        {
            float x = n.x;
            n.x = n.z;
            n.z = x;
            pos = fold3(pos, n);
        }
    }
    
    vec3 off = vec3(1.8, 0, 0);
    return boxSDF(pos - off, vec3(2.7, 0.2, 0.3)) - 0.3;
}

// Approximates the normal of the surface at the given position
// by calculating the gradient of the scene SDF
vec3 calcNormal(in vec3 pos)
{
    vec2 e = vec2(0.0001, 0.0);
    
    return normalize(vec3(
        sceneSDF(pos + e.xyy) - sceneSDF(pos - e.xyy),
        sceneSDF(pos + e.yxy) - sceneSDF(pos - e.yxy),
        sceneSDF(pos + e.yyx) - sceneSDF(pos - e.yyx)));
}

// Returns the distance to scene surface.
// If the ray hit nothing this returns -1.0
float rayMarchScene(in vec3 rayOrigin, in vec3 rayDir)
{
    float t = 0.0;
    for (int i = 0; i < 100; ++i)
    {
        vec3 pos = rayOrigin + rayDir * t;
        
        float dist = sceneSDF(pos);
        t += dist;
        if (dist < 0.00001)
            break;
        if (t > 100.0)
            return -1.0;
    }
    
    return t;
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    //vec2 mouse = vec2(0.5, 1.0);
    float time = mouse.x * 6.28;//time * 0.2;
    float cameraDist = 2.6;
    float upDownAngle = mouse.y-0.6;
    
    vec3 rayOrigin = vec3(cos(time), sin(upDownAngle)*1.2, sin(time)) * cameraDist;
    vec3 lookAtPos = vec3(0.0, 0.6, 0.0);
    
    vec3 forward = normalize(lookAtPos - rayOrigin);
    vec3 right = cross(forward, vec3(0.0, 1.0, 0.0));
    vec3 up = cross(right, forward);
    
    vec3 rayDir = normalize(forward + right * uv.x + up * uv.y);
    
    float t = rayMarchScene(rayOrigin, rayDir);
    
    // Skybox color
    vec3 skyCol = vec3(0.5, 0.2, 0.1) + rayDir.y * 0.1;
    vec3 col = skyCol;
    if (t > 0.0)
    {
        vec3 surfacePos = rayOrigin + rayDir * t;
        vec3 normal = calcNormal(surfacePos);
        
        col = normal;
        col.x = abs(col.x);
        col.z = -abs(col.z);
        col *= 0.5;
        col += 0.5;
    }
    
    // Gamma correction
    col = pow(col, vec3(0.4545));    
    glFragColor = vec4(col, 1.0);
}
