#version 420

// original https://www.shadertoy.com/view/wsVBz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Raymarching the Sierpinski Tetrahedron: Final
// Created by Anthony Hall for Writ 107T

// Raymarching constants
const float maxDistance = 30.0;
const float epsilon = 0.001;

const float maxShadowDistance = 10.0;
const float shadowEpsilon = 0.005;

// Lighting
const float kAmbient = 0.35;
const float kDiffuse = 1.0 - kAmbient;

const float shadowK = 30.0;

const float aoIncrement = 0.02;
const float aoK = 4.0;

// Camera
vec3 cameraPos = vec3(0.0, 0.5, 4.0);
const float fov = radians(50.0);

// Other scene globals
const vec3 skyColor = vec3(0.5, 0.75, 1.0);
const vec3 toSun = normalize(vec3(-1.0, 3.75, 2.0));

// Number of iterations for the Sierpinski IFS
const int sierpinskiLevel = 5;

// Vertices of the tetrahedron defined by the SDF
const vec3[] vertices = vec3[](
    vec3(1.0, 1.0, 1.0),
    vec3(-1.0, 1.0, -1.0),
    vec3(-1.0, -1.0, 1.0),
    vec3(1.0, -1.0, -1.0));

// Get a 2D rotation matrix
mat2 getRotationMatrix(float angle)
{
    return mat2(cos(angle), sin(angle),
                -sin(angle), cos(angle));
}

// Get a surface color based on a point's location
// Uses a procedural palette from iq
// https://www.shadertoy.com/view/ll2GD3
vec3 getColor(vec3 point)
{
    // Set t such that the floor color will change slowly
    // and the tetrahedron color will change more rapidly
    float t;
    if (point.y < -1.9) {
        t = point.x / 60.0 + 0.2;
    }
    else {
        point /= 2.0;
         t = point.x * point.x - point.y + point.z * point.z;
    }
    
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.00, 0.10, 0.20);
    vec3 color = a + b*cos( radians(360.0)*(c*t+d) );
    
    // Lighten the color a bit
    return mix(color, vec3(1.0), 0.3);
}

// Signed distance to a floor plane
float sdFloor(vec3 point, float floorY)
{
    return point.y - floorY;
}

// Signed distance to a tetrahedron within canonical cube
// https://www.shadertoy.com/view/Ws23zt
float sdTetrahedron(vec3 point)
{
    return (max(
        abs(point.x + point.y) - point.z,
        abs(point.x - point.y) + point.z
    ) - 1.0) / sqrt(3.);
}

// Fold a point across a plane defined by a point and a normal
// The normal should face the side to be reflected
vec3 fold(vec3 point, vec3 pointOnPlane, vec3 planeNormal)
{
    // Center plane on origin for distance calculation
    float distToPlane = dot(point - pointOnPlane, planeNormal);
    
    // We only want to reflect if the dist is negative
    distToPlane = min(distToPlane, 0.0);
    return point - 2.0 * distToPlane * planeNormal;
}

// Signed distance to Sierpinski tetrahedron at specified level
// Rotates over time or with mouse press
float sdSierpinski(vec3 point, int level)
{
    // If the mouse is not pressed, rotate the tetrahedron over time
    // Otherwise, rotate it based on the mouse position
    //if (mouse*resolution.xy.z <= 0.0) {
        float time = time / 4.0;
        point.xz = getRotationMatrix(time) * point.xz;
    //}
    //else {
    //    vec2 mouse = (2.0 * mouse*resolution.xy.xy - resolution.xy) / resolution.y;
    //    
    //    point.yz = getRotationMatrix(mouse.y) * point.yz;
    //    point.xz = getRotationMatrix(mouse.x) * point.xz;
    //}
    
    float scale = 1.0;
    for (int i = 0; i < level; i++)
    {
        // Scale point toward corner vertex, update scale accumulator
        point -= vertices[0];
        point *= 2.0;
        point += vertices[0];
        
        scale *= 2.0;
        
        // Fold point across each plane
        for (int i = 1; i <= 3; i++)
        {
            // The plane is defined by:
            // Point on plane: The vertex that we are reflecting across
            // Plane normal: The direction from said vertex to the corner vertex
             vec3 normal = normalize(vertices[0] - vertices[i]); 
            point = fold(point, vertices[i], normal);
        }
    }
    // Now that the space has been distorted by the IFS,
    // just return the distance to a tetrahedron
    // Divide by scale accumulator to correct the distance field
    return sdTetrahedron(point) / scale;
}

// Returns signed distance to the scene
float scene(vec3 point)
{
    // Create a sierpinski tetrahedron and a floor
     float sierpinskiDist = sdSierpinski(point, sierpinskiLevel);
    float floorDist = sdFloor(point, -2.0);
    
    return min(sierpinskiDist, floorDist);
}

// Approximates the normal at an intersection by calculating the gradient of the distance function
vec3 estimateNormal(vec3 point) {
    return normalize(vec3(
        scene(vec3(point.x + epsilon, point.y, point.z)) - scene(vec3(point.x - epsilon, point.y, point.z)),
        scene(vec3(point.x, point.y + epsilon, point.z)) - scene(vec3(point.x, point.y - epsilon, point.z)),
        scene(vec3(point.x, point.y, point.z  + epsilon)) - scene(vec3(point.x, point.y, point.z - epsilon))));
}

// Distance field AO
// https://www.iquilezles.org/www/material/nvscene2008/rwwtt.pdf slide 53
float calcAO(vec3 surfacePoint, vec3 normal)
{
    float t = aoIncrement;
    float distSum = 0.0; // Sum of distance differences

    // Take four distance samples, compare to orthogonal distance
    for (int i = 0; i < 4; i++)
    {
        vec3 point = surfacePoint + t * normal;
         float dist = scene(point);
        
        distSum += exp2(-float(i)) * (t - dist);
        
        t += aoIncrement;
    }
    return 1.0 - aoK * distSum;
}

// Calculates the percentage that a point is illuminated
// https://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
float calcShadow(vec3 surfacePoint)
{
    // Initialize our marching variables
     vec3 point = surfacePoint;
    float t;
    float illumination = 1.0;
    
    // Initialize the ray a little bit away from the point
    // We don't want to start close enough to be considered a hit
    for (t = 2.0 * shadowEpsilon; t < maxShadowDistance;)
    {
         point = surfacePoint + t * toSun;
        float dist = scene(point);
        
        // The path to the sun is blocked
        if (dist < shadowEpsilon) {
            return 0.0;
        }
        
        // Get darker if we get closer to the scene than we have been before
        illumination = min(illumination, shadowK * dist/t);
        t += dist;
    }
    return illumination;
}

// Shades a surface at the given point
vec3 shadeSurface(vec3 point) {
    // Calculate the surface normal and color of our point
    vec3 normal = estimateNormal(point);
    vec3 surfaceColor = getColor(point);
    
    // Ambient
    vec3 color = kAmbient * surfaceColor;
    
    // Diffuse
    float diffuseIntensity = max(dot(normal, toSun), 0.0);
    
    // Shadow
    float illumination = calcShadow(point);
    diffuseIntensity *= illumination;
    color += kDiffuse * diffuseIntensity * surfaceColor;
    
    // AO
    float occlusion = calcAO(point, normal);
    color *= occlusion;
    
    return color;
}

// Returns the result color of casting any ray
vec3 castRay(vec3 rayOrigin, vec3 rayDir)
{
    // Initialize our marching variables
    vec3 point = rayOrigin;
    float t;
    vec3 color = skyColor;
    
    // Repeatedly march the ray forward based on the distance to the scene
    for (t = 0.0; t < maxDistance; point = rayOrigin + t * rayDir)
    {
         float dist = scene(point);
        
        // We got a hit
        if (dist <= epsilon) {
            color = shadeSurface(point);
            break;
        }
        t += dist;
    }
    float totalDist = t / maxDistance;
    return mix(color, skyColor, totalDist * totalDist);
}

// OpenGL's lookAt function
// https://www.geertarien.com/blog/2017/07/30/breakdown-of-the-lookAt-function-in-OpenGL/
mat4 lookAt(vec3 eye, vec3 at, vec3 up)
{
  vec3 zAxis = -normalize(at - eye);    
  vec3 xAxis = -normalize(cross(zAxis, up));
  vec3 yAxis = -cross(xAxis, zAxis);

  return mat4(
    vec4(xAxis, -dot(xAxis, eye)),
    vec4(yAxis, -dot(yAxis, eye)),
    vec4(zAxis, -dot(zAxis, eye)),
    vec4(0.0, 0.0, 0.0, 1.0));
}

void main(void)
{
    // Normalize the coordinates to [-1, 1] in the minimum dimension
    // Use this to calculate the ray direction
    float minDimension = min(resolution.x, resolution.y);
    vec2 coord = 2.0 * (gl_FragCoord.xy - resolution.xy/2.0) / minDimension;
    vec3 rayDir = normalize(vec3(coord * tan(fov/2.0), -1.0));

    // Make the camera point toward the origin
    mat4 cameraMat = lookAt(cameraPos, vec3(0.0), vec3(0.0, 1.0, 0.0));
    rayDir = (cameraMat * vec4(rayDir, 1.0)).xyz;
    
    // Cast the ray!
    vec3 color = castRay(cameraPos, rayDir);
    glFragColor = vec4(color, 1.0);
}
