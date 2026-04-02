#version 420

// original https://www.shadertoy.com/view/WdKSWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MARCHING_STEP 64.

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

float sphereSDF(vec3 samplePoint) {
    return length(samplePoint) - 1.0;
}

float sdPlane( vec3 p )
{
    return p.y;
}

#define Scale 2.
#define iteration 10

float DE(vec3 z)
{
    vec3 a1 = vec3(1,1,1);
    vec3 a2 = vec3(-1,-1,1);
    vec3 a3 = vec3(1,-1,-1);
    vec3 a4 = vec3(-1,1,-1);
    vec3 c;
    int n = 0;
    float dist, d;
    while (n < iteration) {
         c = a1; dist = length(z-a1);
            d = length(z-a2); if (d < dist) { c = a2; dist=d; }
         d = length(z-a3); if (d < dist) { c = a3; dist=d; }
         d = length(z-a4); if (d < dist) { c = a4; dist=d; }
        z = Scale*z-c*(Scale);
        n++;
    }

    return length(z) * pow(Scale, float(-n));
}

float sceneSDF(vec3 samplePoint) {

  
    float res = DE(samplePoint);
    //res += sdPlane(-0.5, vec4(0.,1.,0.,1.));
    return res;
   
}

/////
// Ray function
/////

vec3 getCameraRayDir(vec2 uv, vec3 camPos, vec3 camTarget)
{
    // Calculate camera's "orthonormal basis", i.e. its transform matrix components
    vec3 camForward = normalize(camTarget - camPos);
    vec3 camRight = normalize(cross(vec3(0.0, 1.0, 0.0), camForward));
    vec3 camUp = normalize(cross(camForward, camRight));
     
    float fPersp = 2.0;
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

float march(vec3 pos, vec3 direction, float start, float end, inout float i)
{
    float depth = start;
    for(i = 0.; i < MARCHING_STEP; i++)
    {
        float dist =  sceneSDF(pos + direction * depth);
        if(dist < 0.005f)
        {
            return depth;
        }
        depth += dist;
        if(depth >= end)
            return end;
    }
}

/////
// Main function
/////

void main(void)
{
    vec3 at = vec3(0, 0, 0);
    vec2 uv = normalizeScreenCoords(gl_FragCoord.xy);
    vec3 pos = vec3(cos(time/10.),0,sin(time/10.));

    vec3 dir = getCameraRayDir(uv, pos, at);
    
    float i;
    float dist = march(pos, dir, 0.f,200.f,i);
    vec3 col = vec3(dist);
    
    if((dist - 100.f) > 0.001f)
    {
        col = vec3(0.0529, 0.0808, 0.0922);
    }
    else
    {
        col = vec3(dist*0.1); 
        col = vec3(0.75 + sin(time/10.), 0.515, 0.053 + cos(time/10.)) * float(i)/float(MARCHING_STEP);
    }
    
    glFragColor = vec4(col,1.0);
}
