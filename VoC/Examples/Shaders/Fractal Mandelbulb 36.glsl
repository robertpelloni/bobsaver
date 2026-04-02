#version 420

// original https://www.shadertoy.com/view/3syXRV

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

float sphereSDF(vec3 samplePoint) {
    return length(samplePoint) - 1.0;
}

float sdPlane( vec3 p )
{
    return p.y;
}

#define Scale 2.
#define iteration 15
#define Power (7.+sin(time/7.)*5.)
#define Bailout 5.

float DE(vec3 pos) {
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    for (int i = 0; i < iteration ; i++) {
        r = length(z);
        if (r>Bailout) break;
        
        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow( r, Power-1.0)*Power*dr + 1.0;
        
        // scale and rotate the point
        float zr = pow( r,Power);
        theta = theta*Power;
        phi = phi*Power;
        
        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
    }
    return (0.5*log(r)*r/dr);
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

float march(vec3 pos, vec3 direction, float start, float end, inout int i)
{
    float depth = start;
    for(i = 0; i < MARCHING_STEP; i++)
    {
        float dist =  sceneSDF(pos + direction * depth);
        if(dist < 0.0001f)
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
    
    vec3 dir = getCameraRayDir(uv, pos, at);
    
    float dist = march(pos, dir, 0.f,200.f, i);
    vec3 col = vec3(dist);
    
    if((dist - 100.f) > 0.001f)
    {
        col = vec3(0.0529, 0.0808, 0.0922);
    }
    else
    {
        col = vec3(dist*0.4); 
        col = vec3(0.75 + sin(time/10.), 0.515, 0.053 + cos(time/10.)) * float(i)/float(MARCHING_STEP);
    }
    
    glFragColor = vec4(col,1.0);
}
