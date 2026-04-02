#version 420

// original https://www.shadertoy.com/view/tlB3WG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;
const float BUMP_FACTOR = 0.5;

// 3D hash function
float hash(vec3 p)
{
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

// 3D precedural noise
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    // interpolate between hashes of adjacent grid points
    return mix(mix(mix( hash(p+vec3(0,0,0)), 
                        hash(p+vec3(1,0,0)),f.x),
                   mix( hash(p+vec3(0,1,0)), 
                        hash(p+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(p+vec3(0,0,1)), 
                        hash(p+vec3(1,0,1)),f.x),
                   mix( hash(p+vec3(0,1,1)), 
                        hash(p+vec3(1,1,1)),f.x),f.y),f.z);
}

// 3D noise layered in several octaves
float layeredNoise(in vec3 x) {
    return 0.7*noise(x) + 0.2*noise(x*4.0) + 0.07*noise(x*8.0) + 0.02*noise(x*16.0) + 0.01*noise(x*32.0);
}

// singed distance function of the y=0 plane
float planeSDF(vec3 p) {
    return p.y;
}

// singed distanc function of plane with noise bump map
float bumpPlaneSDF(vec3 p) {
    // get distance to plane as usual
    float d = planeSDF(p);
    
    vec3 normal;
    float bump = 0.0;
    
      // only consider bumps if close to plane
    if(d < BUMP_FACTOR*1.5)
    {    
        normal = vec3(0.0, 1.0, 0.0);
        bump = layeredNoise(p)*BUMP_FACTOR;
    }
    return d - bump;
}

// singed distance function to enire scene
float sceneSDF(vec3 samplePoint) {
    return bumpPlaneSDF(samplePoint);
}

// returns the distanse to the scene along this ray
// by raymarching using the sceneSDF
float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    //raymarching loop
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        // get distance to scene
        float dist = sceneSDF(eye + depth * marchingDirection);
        // exit if close enough
        if (dist < EPSILON) {
            return depth;
        }
        // step closer
        depth += dist;
        // exit if too far
        if (depth >= end) {
            return end;
        }
    }
    return end;
}

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

// estimate normal by aproximatind the first deriviative of the sceneSDF
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

// generate camera transform
mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    // Based on gluLookAt man page
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

// lambert shading coefficient with raymarched shadows
float lambertShading(vec3 p, vec3 lightDir) {
    vec3 n = estimateNormal(p);
    
    // lambert shading coefficient
    float brightness = max(0.0, dot(-lightDir, n));
    
    // trace ray from surface point in direction of the light source
    // offset in direction of the normal to avoid self intersection
    float distToLight = shortestDistanceToSurface(p + n * EPSILON * 100.0, -lightDir, MIN_DIST, MAX_DIST);
    
    // in shadow
    if (distToLight + 10.0 * EPSILON < MAX_DIST) {
        return 0.0;
    }
    
    return brightness;
}

void main(void)
{
    vec3 viewDir = rayDirection(45.0, resolution.xy);
       vec3 eye = vec3(2.0*sin(time*0.3 - 3.0), 3.0, time);
    mat3 viewToWorld = viewMatrix(eye, eye + vec3(2.0*sin(time*0.3), -3.0, 8.0), vec3(0.2*sin((time-1.0)*0.3), 1.0, 0.0));
    
    vec3 worldDir = viewToWorld * viewDir;
    
    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
    
    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        glFragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    
    // The closest point on the surface to the eyepoint along the view ray
    vec3 p = eye + dist * worldDir;
    
    vec3 lightDir = normalize(vec3(-1.0, -1.0, -3.0));
    
    vec3 ambientLight = vec3(0.01, 0.01, 0.005);
    vec3 diffuseColor = vec3(0.8, 0.8, 0.8);
    
    vec3 color = ambientLight;
    
    color += diffuseColor*lambertShading(p, lightDir);
    
    glFragColor = vec4(color, 1.0);
}
