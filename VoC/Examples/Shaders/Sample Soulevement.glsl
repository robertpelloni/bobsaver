#version 420

// original https://www.shadertoy.com/view/ldycz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//soulevement  de jmaire

 /*
    Tutorial used and credit: https://www.shadertoy.com/view/lt33z7
    tutorial used and credit:http://jamie-wong.com */

const int MAX_MARCHING_STEPS = 255; 
const float MIN_DIST = 0.0; 
const float MAX_DIST = 100.0; 
const float EPSILON = 0.0001; 
const float PI = 3.14159; 
const float sq2 = cos(PI/4.0); 

/**
 * Signed distance function for a sphere centered at the origin with radius 1.0;
 */
float boxSDF(vec3 p, vec3 b ) {
    return length(max(abs(p) - b, 0.0)); 
}

/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */

float pMod(float t, float d) {
    return mod(t + d/2.0, d) - d/2.0; 
}

vec3 qrotate(vec3 axe, float angl, vec3 v) {
    float a = angl/2.0; 
    vec3 axens = normalize(axe) * sin(a); 
    return v + 2.0 * cross(cross(v, axens) - v * cos(a), axens); 
}

float bras(float an, vec3 pos, vec3 p) {
 vec3  p1 = qrotate(vec3(0., 1., 0.), an + PI/4.0, p); 
 p1 = p1 + vec3(sq2, 0., 0.); 
 vec3 p2 = qrotate(vec3(0.0, 0.0, 1.0), time, p1); 
 float boo = boxSDF(p2, vec3(0.1, 0.1, 2.0)); 
 vec3 p3 = qrotate(vec3(0.0, 1.0, 0.0),  - PI/4.0, p2); 
 p3 = p3 + vec3(0.25, 0., 0.25); 
 float bo1 = boxSDF(p3, vec3(0.25, 2.1, 0.25)); 
return min(boo, bo1); 
}

float sceneSDF(vec3 p) {
     p.z=pMod(p.z,2.0);
     p.x=pMod(p.x,2.0);
 float  s0 = bras(0.0, vec3(-1.0, 0.0, -1.0), p); 
 float  s1 = bras(PI/2.0, vec3(-1., 0.0, -1.0), p); 
 float  s2 = bras(PI, vec3(-1., 0., -1.), p); 
 float  s3 = bras(3.0 * PI/2.0, vec3(-1., 0., -1.), p);     
return min(s3, min(s2, min(s1, s0))); 
}

vec3 estimateNormal(vec3 p) {
   
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)), 
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)), 
        sceneSDF(vec3(p.x, p.y, p.z + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    )); 
}

/**
 * Lighting contribution of a single point light source via Phong illumination.
 * 
 * The vec3 returned is the RGB color of the light's contribution.
 *
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 * lightPos: the position of the light
 * lightIntensity: color/intensity of the light
 *
 * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
 */
vec3 phoneContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye,
                            vec3 lightPos, vec3 lightIntensity)
{ 
    vec3 N = estimateNormal(p); // Estimate normal of surface
    vec3 L = normalize(lightPos - p); // Point from point on surface to light
    vec3 V = normalize(eye - p); // Viewing vector, used to diffuse reflected light
    vec3 R = normalize(reflect(-L, N)); // Reflect light to the normal

    float dotLN = dot(L,N); // cosine angle between light direction and normal direction
    float dotRV = dot(R,V); // cosine angle between reflection direction and viewing direction
    
    // Light is coming from behind the normal of the face, pitch black
    if (dotLN < 0.)
    {
        return vec3(0.0);
    }
    // Reflected light points away from the camera, so there are no direct light. Only ambient light and diffuse color
    if (dotRV < 0.)
    {
        // This value maxes when dotLN = 1, which is when L(light) and N(normal) are equal. 100% of the light is reflected back
        return lightIntensity * (k_d * dotLN);
    }
    return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
    }

/**
 * Lighting via Phong illumination.
 * 
 * The vec3 returned is the RGB color of that point after lighting is applied.
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 *
 * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
 */
vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye) {
    const vec3 globalAmbentLight = vec3(0.1,0.1,0.8);
    vec3 color = globalAmbentLight * k_a; // Multiply brightness by color to get ambient color
    color += phoneContribForLight(k_d, k_s, alpha, p, eye, vec3(-30.,6.,30.), vec3(1.,.1, 0.));
    color += phoneContribForLight(k_d, k_s, alpha, p, eye,vec3(20.,6.,-30.), vec3(0.3, 0.05, 0.5));
    color += phoneContribForLight(k_d, k_s, alpha, p, eye,vec3(3.,8.0,-30.), vec3(0.1, 0.35, 1.0));
    return color;
}

/**
 * Return the shortest distance from the eyepoint to the scene surface along
 * the marching direction. If no part of the surface is found between start and end,
 * return end.
 * 
 * eye: the eye point, acting as the origin of the ray
 * marchingDirection: the normalized direction to march in
 * start: the starting distance away from the eye
 * end: the max distance away from the ey to march before giving up
 */

float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end)
{
    // Start depth
    float depth = start;
    // Keep looking for where the marching ray hits a surface
    for (int i = 0; i < MAX_MARCHING_STEPS; ++i)
    {
        // Get the distance from marching ray point to surface of box
        float dist = sceneSDF(eye + marchingDirection * depth);
        // If we've hit near the surface, return this distance
        if (dist < EPSILON) {
            return depth; 
        }
        // Didn't find anything, let's go to where we found something
        depth =depth +  dist; 
        // We're at the end, stop
        if (depth > end)
        {
            return end;
        }
    }
    // Ran out of steps before we hit the end, just return end
    return end;
}

/**
    fov:         Field of View of camera
    screen_size: Screen size
    gl_FragCoord:   Screen coord of pixel
    return:      Direction of rendering ray of the projection camera
 */

vec3 rayDirection(float fov, vec2 screen_size, vec2 gl_FragCoord)
{
    vec2 xy = gl_FragCoord.xy - screen_size / 2.0;
    float z = (screen_size.y / 2.) / tan(radians(fov) / 2.);
    return normalize(vec3(xy,-z));
}

/**
 * Return a transform matrix that will transform a ray from view space
 * to world coordinates, given the eye point, the camera target, and an up vector.
 *
 * This assumes that the center of the camera is aligned with the negative z axis in
 * view space when calculating the ray marching direction. See rayDirection.
 */
mat3 lookAtMatrix(vec3 eye, vec3 center, vec3 up) 
{
    // Based on gluLookAt man page
    // Forward/Look at vector
    vec3 f = normalize(center - eye);
    // Right vector
    vec3 v = normalize(cross(f, up));
    // Camera local up Vector
    vec3 u = cross(v, f);
    return mat3(
        vec3(v),
        vec3(u),
        vec3(-f)
    );
}

void main(void)
{
    vec3 camera_space_dir = rayDirection(30., resolution.xy, gl_FragCoord.xy);
    vec3 eye = 
        vec3(
            6.*cos(time*0.2) +2.,
            2.*cos(time*0.5) +6.,
            6.*sin(time*0.2)+2. 
            );

   vec3 world_space_dir = lookAtMatrix(eye, vec3(0.), vec3(0,1,0)) * camera_space_dir;
    // Find shortest distance surface
    float dist = shortestDistanceToSurface(
        eye,
        world_space_dir, 
        MIN_DIST, 
        MAX_DIST);
    if (dist > MAX_DIST - EPSILON)
    {
        glFragColor = vec4(0.07);
        return;
    }

    // We've hit a surface
    // Phong shading time!!
    // Surface point
    vec3 p = eye + dist * world_space_dir; 

    vec3 K_ambientColor = vec3(1.0, 0.0, 0.0); 
    vec3 K_diffuseColor = vec3(1.0, 1.0, 1.0); 
    vec3 K_specularColor = vec3(0.0, 1.0, 0.0); 
    float shineness = 3.0; 

    vec3 color = phongIllumination(K_ambientColor, K_diffuseColor, K_specularColor, shineness, p, eye); 
    glFragColor = vec4(color, 1.); 
}
