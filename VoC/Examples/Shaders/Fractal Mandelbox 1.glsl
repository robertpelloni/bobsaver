#version 420

// original https://www.shadertoy.com/view/WsXczH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MARCHING_STEP 128

/////
// SDF Operation function
/////

vec3 opRep( in vec3 p, in vec3 c)
{
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    return q;
}

/////
// Scene and primitive SDF function
/////

void sphereFold(inout vec3 z, inout float dz)
{
    float r2 = dot(z,z);
    if (r2 < 0.5)
    { 
        float temp = 2.0;
        z *= temp;
        dz*= temp;
    }
    else if (r2 < 1.0)
    { 
        float temp = 1.0 / r2;
        z *= temp;
        dz*= temp;
    }
}

void boxFold(inout vec3 z, inout float dz)
{
    z = clamp(z, -1.0, 1.0) * 2.0 - z;
}

float DE(vec3 z)
{
    float scale = 3.;
    vec3 offset = z;
    float dr = 1.0;
    for (int n = 0; n < 10; n++)
    {
        boxFold(z,dr);
        sphereFold(z,dr);
        z = scale * z + offset;
        dr = dr * abs(scale) + 0.0;
    }
    float r = length(z);
    return r / abs(dr);
}

float sceneSDF(vec3 samplePoint) {

  
    float res = DE(samplePoint);
    //res += sdPlane(-0.5, vec4(0.,1.,0.,1.));
    return res;
   
}

/////
// Ray function
/////

vec3 getCameraRayDir(vec2 uv, vec3 camPos, vec3 camTarget, float fov)
{
    // Calculate camera's "orthonormal basis", i.e. its transform matrix components
    vec3 camForward = normalize(camTarget - camPos);
    vec3 camRight = normalize(cross(vec3(0.0, 1.0, 0.0), camForward));
    vec3 camUp = normalize(cross(camForward, camRight));
     
    float fPersp = 0.5 / tan(radians(fov)/ 2.0);
    vec3 vDir = normalize(uv.x * camRight + uv.y * camUp + camForward * fPersp);
 
    return vDir;
}

vec3 rayDir(float fov, vec2 size)
{
    vec2 xy = gl_FragCoord.xy - size/2.0;
    float z = size.y * 0.5 / tan(radians(fov)/ 2.0);
    return normalize(vec3(xy,-z));
}

vec2 normalizeScreenCoords(vec2 screenCoord)
{
    vec2 result = 2.0 * (screenCoord/resolution.xy - 0.5);
    result.x *= resolution.x/resolution.y;
    return result;
}

/////
// Marching function
/////

float march(vec3 pos, vec3 direction, float start, float end, inout int i)
{
    float depth = start;
    for(i = 0; i < MARCHING_STEP; i++)
    {
        float dist =  sceneSDF(pos + direction * depth);
        if(dist < 0.0004f)
        {
            //return depth;
            break;
        }
        depth += dist;
        if(depth >= end)
            return end;
    }
    return depth;
}

/////
// Main function
/////

void main(void)
{
    vec3 at = vec3(0, 0, 0);
    vec2 uv = normalizeScreenCoords(gl_FragCoord.xy);
    vec3 pos = vec3(cos(time/10.) * 1.75 ,sin(time/15.),sin(time/10.) * 1.75);
    
    int i = 0;
    
    vec3 dir = getCameraRayDir(uv, pos, at, 60.f);
    
    float dist = march(pos, dir, 0.1f,200.f, i);
    vec3 col = vec3(dist);
    
    col = vec3(dist*0.4); 
    col = vec3(0.55 + sin(time/10.), 0.515, 0.553 + cos(time/10.)) * float(i)/float(MARCHING_STEP);
    
    glFragColor = vec4(col,1.0);
}
