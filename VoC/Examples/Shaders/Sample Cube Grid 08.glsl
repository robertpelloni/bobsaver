#version 420

// original https://www.shadertoy.com/view/MdSyWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Tutorial used: https://www.shadertoy.com/view/lt33z7
    I rewrote everything for practice.
*/

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST         = 0.0;
const float MAX_DIST         = 2000.0;
const float EPSILON          = 0.0001;

/**
 * Signed distance function for a sphere centered at the origin with radius 1.0;
 */
float boxSDF( vec3 p, vec3 b )
{
    return length(max(abs(p)-b,0.0));
}

// Repeat in three dimensions
vec3 pMod3(inout vec3 p, vec3 size) {
    vec3 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5, size) - size*0.5;
    return c;
}

/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */
float sceneSDF(vec3 p)
{
    pMod3(p, vec3(5,5,5));
    return boxSDF(p, vec3(0.5));
}

vec3 estimateNormal(vec3 p)
{
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
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
    float light_dist = distance(eye, p);
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
        return min(1., abs(30./light_dist)) * lightIntensity * (k_d * dotLN);
    }
    return min(1., abs(30./light_dist)) * lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
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
    const vec3 globalAmbentLight = 0.9 * vec3(1.);
    vec3 color = globalAmbentLight * k_a; // Multiply brightness by color to get ambient color

    // Light 1
    vec3 light1Pos = vec3(0.,1.,3.);
    vec3 light1Insentity = vec3(0, 67.1/100., 43.5/100.);
    color += phoneContribForLight(k_d, k_s, alpha, p, eye, light1Pos, light1Insentity);

    // Light 2
    vec3 light2Pos = vec3(-1.,-1.,1.);
    vec3 light2Insentity = vec3(50./100., 59.2/100., 0);
    color += phoneContribForLight(k_d, k_s, alpha, p, eye, light2Pos, light2Insentity);

    // Light 3
    vec3 light3Pos = vec3(-0.5,2,-3.);
    vec3 light3Insentity = vec3(4.7/100., 35.3/100., 65.1/100.);
    color += phoneContribForLight(k_d, k_s, alpha, p, eye, light3Pos, light3Insentity);

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
        if (dist < EPSILON)
        {
            return depth;
        }
        // Didn't find anything, let's go to where we found something
        depth += dist;
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
    vec2 xy = gl_FragCoord - screen_size / 2.0;
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
    vec3 camera_space_dir = rayDirection(60., resolution.xy, gl_FragCoord.xy);
    vec3 eye = 
        vec3(
            cos(time*0.25) * 100.,
            cos(time) * 30.,
            (sin(time)+5.) * 1.5
            );

   vec3 world_space_dir = lookAtMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0,1,0)) * camera_space_dir;
    // Find shortest distance surface
    float dist = shortestDistanceToSurface(
        eye,
        world_space_dir, 
        MIN_DIST, 
        MAX_DIST);
    if (dist > MAX_DIST - EPSILON)
    {
        glFragColor = vec4(0.2 * vec3(1.), 1);
        return;
    }

    // We've hit a surface
    // Phong shading time!!
    // Surface point
    vec3 p = eye + dist * world_space_dir;

    vec3 K_ambientColor = vec3(0.2, 0.2, 0.2);
    vec3 K_diffuseColor = vec3(0.7, 0.2, 0.2);
    vec3 K_specularColor = vec3(1.0, 1.0, 1.0);
    float shineness = 20.0;

    vec3 color = phongIllumination(K_ambientColor, K_diffuseColor, K_specularColor, shineness, p, eye);
    glFragColor = vec4(color,1.);
}
