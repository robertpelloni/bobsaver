#version 420

// original https://www.shadertoy.com/view/3dcXWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_MARCHING_STEPS = 127;
const float MIN_DIST = 0.0;
const float MAX_DIST = 50.0;
const float EPSILON = 0.005;

/**
 * Return the normalized direction to march in from the eye point for a single pixel.
 * 
 * fieldOfView: vertical field of view in degrees
 * size: resolution of the output image
 * gl_FragCoord: the x,y coordinate of the pixel in the output image
 */
vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

/**
 * Return a transform matrix that will transform a ray from view space
 * to world coordinates, given the eye point, the camera target, and an up vector.
 *
 * This assumes that the center of the camera is aligned with the negative z axis in
 * view space when calculating the ray marching direction. See rayDirection.
 */
mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    // Based on gluLookAt man page
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */
vec4 sceneSDF(vec3 p) {
    // angles for rotation
    float alpha = -3.2 + 0.1*sin(time*0.11);
    float beta = 1.02 + 0.1*cos(time*0.2);
    
    // rotation matrices
    mat3 rot1 = mat3(1.0, 0.0, 0.0, 0.0, cos(alpha), -sin(alpha), 0.0, sin(alpha), cos(alpha));
    mat3 rot2 = mat3(cos(beta), -sin(beta), 0.0, sin(beta), cos(beta), 0.0, 0.0, 0.0, 1.0);
    
    // normals for reflection
    vec3 n1 = normalize(vec3(-0.8, 1.2 - 0.2*sin(time*0.1), -0.8));
    vec3 n2 = normalize(vec3(0.4 + 0.15*cos(time*0.112), 0.4, -0.1 + 0.05*cos(time*0.133)));
    
    // repeat several times
    for (int i = 0; i < 20; i++)
    {
        p-=2.0 * min(0.0, dot(p, n1)) * n1;        // first reflection
        p += vec3(0.1, -0.1, 0.1);                // translate
        p *= rot1;                                // rotate
        p-=2.0 * min(0.0, dot(p, n2)) * n2;        // second reflection
        p += vec3(-0.1, 0.1, 0.0);                // translate
        p *= rot2;                                // rotate
    }
    return vec4(length(p) - 0.5, p);    // return distance to sphere and p for coloring
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
vec4 shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end, int max_steps) {
    float depth = start;
    vec4 result;
    for (int i = 0; i < max_steps; i++) {
        result = sceneSDF(eye + depth * marchingDirection);    // get distance + transformed point
        float dist = result.x;
        if (dist < EPSILON) {
            return vec4(depth, result.xzw);        // return distance + transformed point
        }
        depth += dist;
        if (depth >= end) {
            return vec4(end, result.xzw);        // return distance + transformed point
        }
    }
    return vec4(end, result.xzw);                // return distance + transformed point
}

/**
 * Using the gradient of the SDF, estimate the normal on the surface at point p.
 */
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)).x - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)).x,
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)).x - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)).x,
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)).x - sceneSDF(vec3(p.x, p.y, p.z - EPSILON)).x
    ));
}

void main(void)
{
    // camera setup
    vec3 viewDir = rayDirection(40.0, resolution.xy);
    vec3 eye = vec3(30.0*sin(time*0.3), -30.0*cos(time*0.3), 5.0);  
       vec3 up = vec3(0.0, 0.0, 1.0);
    vec3 lookAt = vec3(0.0, 0.0, 0.0);
    
    mat3 viewToWorld = viewMatrix(eye, lookAt, up); 
    vec3 worldDir = viewToWorld * viewDir;
    
    // raymarch scene
    vec4 result = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST, MAX_MARCHING_STEPS);
    float dist = result.x;
    
    if (dist > MAX_DIST - EPSILON) {            // Didn't hit anything
        glFragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    
    
    vec3 p = eye + dist * worldDir;    // The closest point on the surface to the eyepoint along the view ray
    vec3 n = estimateNormal(p);        // surface normal
    
    vec3 diffuse = vec3(0.5);//texture(iChannel0, abs(0.4*result.yz)).rgb;    // color from texture based on transformed point
    
    // first light
    vec3 lightPos = vec3(2.0, 3.0, 25.0);
    vec3 lightRay = vec3(lightPos - p);
    vec3 lightDir = normalize(lightRay);
    
    vec3 col = vec3(0);
    col += diffuse*vec3(1.0, 0.9, 0.8)*max(0.1, dot(n, lightDir))/length(lightRay)*36.0;
    
    // second light
    vec3 lightPos2 = vec3(15.0, 15.0, -15.0);
    vec3 lightRay2 = vec3(lightPos2 - p);
    vec3 lightDir2 = normalize(lightRay2);

    col += diffuse*vec3(0.4, 0.8, 1.0)*max(0.1, dot(n, lightDir2))/length(lightRay2)*19.0;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
