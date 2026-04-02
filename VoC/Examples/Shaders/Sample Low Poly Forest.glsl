#version 420

// original https://www.shadertoy.com/view/3tB3Wd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_MARCHING_STEPS = 255;
const int MAX_SHADOW_STEPS = 60;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0005;

/**
 * Rotation matrix around the X axis.
 */
mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

/**
 * Rotation matrix around the Y axis.
 */
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

/**
 * Rotation matrix around the Z axis.
 */
mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

/**
 * Constructive solid geometry union operation on SDF-calculated distances.
 */
float unionSDF(float distA, float distB) {
    return min(distA, distB);
}

/**
 * Signed distance function for a cube centered at the origin
 * with dimensions specified by size.
 */
float boxSDF(vec3 p, vec3 size) {
    vec3 d = abs(p) - (size / 2.0);
    
    // Assuming p is inside the cube, how far is it from the surface?
    // Result will be negative or zero.
    float insideDistance = min(max(d.x, max(d.y, d.z)), 0.0);
    
    // Assuming p is outside the cube, how far is it from the surface?
    // Result will be positive or zero.
    float outsideDistance = length(max(d, 0.0));
    
    return insideDistance + outsideDistance;
}

// signed distance function for xz plane
float plane(vec3 p) {
    return p.y;
}

// SDF for a single tree layer
float treeLayerSDF(vec3 p) {
    
    p.z = abs(p.z);
    p = rotateY(radians(30.0))*p;
    p.x = abs(p.x);
    p = rotateY(radians(60.0))*p;
    p.z *= 0.5; //length is inacurate!!
      p = rotateZ(radians(45.0))*rotateX(atan(sqrt(0.5)))*p;
    
    return boxSDF(p, vec3(1.0, 1.0, 1.0));
}

// SDF for single tree
float treeSDF(vec3 p) {
    
    p.y *= 0.7; //length is inacurate!!
        
    float layer0 = treeLayerSDF(p);
    float layer1 = treeLayerSDF(p*1.2 - vec3(0.0, 0.7, 0.0))/1.2;
    float layer2 = treeLayerSDF(p*2.0 - vec3(0.0, 2.2, 0.0))/2.0;
    float layer3 = treeLayerSDF(p*4.0 - vec3(0.0, 6.0, 0.0))/4.0;
    
    mat3 rotate = rotateY(radians(60.0));
    
    float layer4 = treeLayerSDF(rotate*p*1.1 - vec3(0.0, 0.2, 0.0))/1.1;
    float layer5 = treeLayerSDF(rotate*p*1.5 - vec3(0.0, 1.1, 0.0))/1.5;
    float layer6 = treeLayerSDF(rotate*p*2.5 - vec3(0.0, 3.2, 0.0))/2.5;
    float layer7 = treeLayerSDF(rotate*p*4.8 - vec3(0.0, 7.8, 0.0))/4.8;
    
    float result = unionSDF(layer0, layer1);
    result = unionSDF(result, layer2);
    result = unionSDF(result, layer3);
    result = unionSDF(result, layer4);
    result = unionSDF(result, layer5);
    result = unionSDF(result, layer6);
    result = unionSDF(result, layer7);
    return result;
}

/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */
float sceneSDF(vec3 p) {
    
    // repeat in xz-plane
    vec3 p1 = vec3(mod(p.x, 3.0) - 1.5,
             p.y,
             mod(p.z, 3.0) - 1.5);
    // ground plane
    return unionSDF(treeSDF(p1), plane(p1));
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
float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end, int max_steps) {
    float depth = start;
    for (int i = 0; i < max_steps; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection);
        if (dist < EPSILON) {
            return depth;
        }
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
}
            

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
 * Using the gradient of the SDF, estimate the normal on the surface at point p.
 */
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

// lambert shading coefficient with raymarched shadows
float lambertShading(vec3 p, vec3 lightPos) {
    vec3 n = estimateNormal(p);
    vec3 ray = p - lightPos;
    vec3 lightDir = normalize(ray);
    
    // lambert shading coefficient
    float brightness = max(0.0, dot(-lightDir, n));
    
    // trace ray from surface point in direction of the light source
    // offset in direction of the normal to avoid self intersection
    float distToLight = shortestDistanceToSurface(p + n * EPSILON * 100.0, -lightDir, MIN_DIST, MAX_DIST, MAX_SHADOW_STEPS);
    
    // in shadow
    if (distToLight + EPSILON < MAX_DIST) {
        return 0.0;
    }
    
    // brightness depends on inverse sqare law
    return brightness/(ray.x*ray.x + ray.y*ray.y);
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

void main(void)
{
    vec3 viewDir = rayDirection(45.0, resolution.xy);
    float cameraRadius = 10.0;
    vec3 eye = vec3(cameraRadius*cos(time*0.4 + 1.0), 7.0, cameraRadius*sin(time*0.4 + 1.0));
    
    mat3 viewToWorld = viewMatrix(eye, vec3(0.0, 2.0, 0.0), vec3(0.0, 1.0, 0.0));
    
    vec3 worldDir = viewToWorld * viewDir;
    
    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST, MAX_MARCHING_STEPS);
    
    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        glFragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    
    // The closest point on the surface to the eyepoint along the view ray
    vec3 p = eye + dist * worldDir;
    
    vec3 objectColor = vec3(0.2, 0.7, 0.3);
    vec3 lightPos1 = vec3(6.0, 10.0, 0.0);
    vec3 lightPos2 = vec3(0.0, 2.6, 0.0);
    vec3 lightPos3 = vec3(-8.0, 10.0, 2.0);
    vec3 lightColor1 = vec3(1.0, 0.4, 0.1);
    vec3 lightColor2 = vec3(0.6, 0.6, 1.0);
    float lightIntensity1 = 200.0;
    float lightIntensity2 = 6.0;
    float lightIntensity3 = 60.0;
    vec3 ambient = vec3(0.01, 0.1, 0.08);
    vec3 diffuse1 = lambertShading(p, lightPos1)*lightIntensity1*lightColor1;
    vec3 diffuse2 = lambertShading(p, lightPos2)*lightIntensity2*lightColor2;
    vec3 diffuse3 = lambertShading(p, lightPos3)*lightIntensity3*lightColor1;
    vec3 color = (ambient + diffuse1 + diffuse2 + diffuse3) * objectColor;
    
    vec3 fogColor = vec3(0.3, 0.3, 0.7);
    
    vec3 eyeRay = p - eye;
    float depth = length(eyeRay);
    float fogFactor = clamp(depth*0.05 - 0.25, 0.0, 1.0);
    color = mix(color, fogColor, fogFactor);
    
    glFragColor = vec4(color, 1.0);
}
