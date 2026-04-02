#version 420

// original https://www.shadertoy.com/view/3d2SRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 64
#define EPSILON 0.02
#define MAX_DIST 500.0

float gyroidSDF(vec3 p , float s)
{
    float g = cos(p.x) * sin(p.y) + cos(p.y) * sin(p.z) + cos(p.z) * sin(p.x);
    return length(normalize(p) * g * s);

}

float sphereSDF(vec3 p, float r)
{
     return length(p)-r;   
}

float opUnion( float d1, float d2 ) {  return min(d1,d2); }

float opSub( float d1, float d2 ) { return max(-d1,d2); }

float opInter( float d1, float d2 ) { return max(d1,d2); }

float opRep( in vec3 p, in vec3 c)
{
    vec3 q = mod(p,c)-0.5*c;
    return sphereSDF(q, 0.11);
}

float sceneSDF(vec3 p)
{

    return opSub(opRep(p,vec3(0.33,0.33,0.33)), gyroidSDF(p, 0.314159 ));
}

float distToSurface( vec3 eye, vec3 dir, float startDist, float endDist )
{
    float depth = startDist;
    for (int i = 0; i < MAX_STEPS; i++) 
    {
        float dist = sceneSDF(eye + depth * dir);
        if (dist < EPSILON) 
        {
        // We're inside the scene surface!
        return depth;
        }
        // Move along the view ray
        depth += dist;

        if (depth >= MAX_DIST) 
        {
            // Gone too far; give up
            return endDist;
        }
    }
    return endDist;
}

vec3 estimateNormal(vec3 p) 
{
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

void main(void)
{
     // pixel coordinates (from -1 to 1)
    vec2 uv = (gl_FragCoord.xy/resolution.xy)* 2.0 - 1.0;
    uv.x *= resolution.x/resolution.y;

    // camera setup and ray cast
    float zoom = 0.45;
    float ext = time * 0.6;
    vec3 lookAt = vec3(cos(ext)*4.0,0.0,ext);
    vec3 camOrigin = vec3(0.0,1.0,-10.0 + ext);
    vec3 forwardVec = normalize(lookAt - camOrigin);
    vec3 rightVec = normalize(cross(vec3(0.0,1.0,0.0),forwardVec));
    vec3 upVec = cross(forwardVec,rightVec);
    
    vec3 centerVec = camOrigin + forwardVec * zoom;
    vec3 intersectVec = centerVec + uv.x * rightVec + uv.y * upVec;
    vec3 rayDirection = normalize(intersectVec - camOrigin);

    float d = distToSurface(camOrigin,rayDirection, 0.0,MAX_DIST);
    vec3 g = estimateNormal(camOrigin + rayDirection * d);
    d = d/length(g);
      vec3 p = camOrigin + rayDirection * d;
  
       
    if (d > MAX_DIST-EPSILON)
    {
         // no hit
        glFragColor = vec4(0.0,0.0,0.0,0.0);
        return;
    }
    vec3 bc = vec3(-0.1+g.y,-0.9+g.y,1.0-g.x);
    vec3 col = vec3(clamp(d,0.0,0.99))*(bc+g);

    glFragColor = vec4(col,1.0);
}

