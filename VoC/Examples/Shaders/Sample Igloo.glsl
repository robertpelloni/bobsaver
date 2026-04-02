#version 420

// original https://www.shadertoy.com/view/4t3BD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
 * Part 3 Challenges
 * - Make the camera move up and down while still pointing at the cube
 * - Make the camera roll (stay looking at the cube, and don't change the eye point)
 * - Make the camera zoom in and out
 */

const int MAX_MARCHING_STEPS = 1024;
const float MIN_DIST = 0.0;
const float MAX_DIST = 1000.0;
const float EPSILON = 0.0001;
const float PI = 3.1415926535897932384626433832795;

/**
 * Signed distance function for a cube centered at the origin
 * with width = height = length = 2.0
 */
float cubeSDF(vec3 p) {
    // If d.x < 0, then -1 < p.x < 1, and same logic applies to p.y, p.z
    // So if all components of d are negative, then p is inside the unit cube
    vec3 d = abs(p) - vec3(1.0, 1.0, 1.0);
    
    // Assuming p is inside the cube, how far is it from the surface?
    // Result will be negative or zero.
    float insideDistance = min(max(d.x, max(d.y, d.z)), 0.0);
    
    // Assuming p is outside the cube, how far is it from the surface?
    // Result will be positive or zero.
    float outsideDistance = length(max(d, 0.0));
    
    return insideDistance + outsideDistance;
}

/**
 * Signed distance function for a sphere centered at the origin with radius 1.0;
 */
float sphereSDF(vec3 p) {
    return length(p) - 5.0;
}

float coneSDF( vec3 p, vec2 c )
{
    float q = length(p.xz);
    return dot(c,vec2(q,p.y));
}

float iglooOuterSDF(vec3 p) {
    float d = length(p) - 5.0;
    if (d <= 0.1 && d >= -0.1) {
        if (mod(p.y, 0.5) <= 0.03) {
            d += 0.02;
        } else {
            float angle = atan(p.z, p.x);
            if (mod(p.y, 1.0) <= 0.5) {
                if (mod(angle, PI / 7.0) <= 0.03) {
                    d += 0.02;
                }
            } else {
                if (mod(angle + (PI / 5.0), PI / 7.0) <= 0.03) {
                    d += 0.02;
                }
            }
        }
    }
    return d;
}

float iglooInnerSDF(vec3 p) {
    return length(p) - 4.0;
}

float groundSDF(vec3 p, float level) {
    return (p.y - level);
}

float wallXSDF(vec3 p, float x) {
    return (p.x - x);
}

float cylinderSDF( vec3 p, vec2 h ) {
  vec2 d = abs(vec2(length(p.xy),p.z)) - h;
  float dist = min(max(d.x,d.y),0.0) + length(max(d,0.0));
  if (dist <= 0.1 && dist >= -0.1) {
     if (mod(p.y, 0.5) <= 0.03) {
         dist += 0.02;
     } else if (mod(p.z, 1.2) <= 0.03) {
         dist += 0.02;
     }
  }
  return dist;
}

/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */
float sceneSDF(vec3 p) {
    return min(
               max(
                   max(
                       min(
                           iglooOuterSDF(p),
                           cylinderSDF(p - vec3(0.0, 0, 4.0), vec2(2.0, 3.0))),
                       -cylinderSDF(p - vec3(0.0, 0, 4.0), vec2(1.20, 5.0))),
                   -iglooInnerSDF(p)),
                groundSDF(p, 0.0));
}

/**
 * Return the shortest distance from the eyepoint to the scene surface along
 * the marching direction. If no part of the surface is found between start and end,
 * return end.
 * 
 * eye: the eye point, acting as the origin of the ray
 * marchingDirection: the normalized direction to march in
 * start: the starting distance away from the eye
 * end: the max distance away from the eye to march before giving up
 */
float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
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
Returns a number to multiply the illumination by.
k is softness of shadows
*/
float softShadowMarch(vec3 eye, vec3 marchingDirection, float start, float end, float k) {
    float depth = start;
    float res = 1.0;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection);
        if (dist < EPSILON) {
            return 0.0;
        }
        depth += dist;
        //res = min(res, k*dist/depth);
        if (depth >= end) {
            return res;
        }
    }
    return res;
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
vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye,
                          vec3 lightPos, vec3 lightIntensity) {
    float lightToPointDist = length(p - lightPos);
    float res = softShadowMarch(lightPos, normalize(p - lightPos),
                                EPSILON, lightToPointDist - 12.0*EPSILON, 50.0);
    //res = 1.0;
    
    vec3 N = estimateNormal(p);
    vec3 L = normalize(lightPos - p);
    vec3 V = normalize(eye - p);
    vec3 R = normalize(reflect(-L, N));
    
    float dotLN = dot(L, N);
    float dotRV = dot(R, V);
    
    if (dotLN < 0.0) {
        // Light not visible from this point on the surface
        return vec3(0.0, 0.0, 0.0);
    } 
    
    if (dotRV < 0.0) {
        // Light reflection in opposite direction as viewer, apply only diffuse
        // component
        return res * lightIntensity * (k_d * dotLN);
    }
    return res * lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
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
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;
    
    vec3 light1Pos = vec3(10.0 * sin(1.8*time),
                          9.0,
                          8.0 * cos(1.8*time));
    vec3 light1Intensity = vec3(0.4, 0.4, 0.4);
    
    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light1Pos,
                                  light1Intensity);
    
    vec3 light2Pos = vec3(10.0 * sin(1.3 * time),
                          15.0 * cos(1.3 * time),
                          8.0);
    vec3 light2Intensity = vec3(0.4, 0.4, 0.4);
    
    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light2Pos,
                                  light2Intensity);
    
    vec3 light3Pos = vec3(0,1.0,0.0);
    vec3 light3Intensity = vec3(5, 1, 0);
    
    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light3Pos,
                                  light3Intensity); 
    return color;
}

/**
 * Return a transform matrix that will transform a ray from view space
 * to world coordinates, given the eye point, the camera target, and an up vector.
 *
 * This assumes that the center of the camera is aligned with the negative z axis in
 * view space when calculating the ray marching direction. See rayDirection.
 */
mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    // Based on gluLookAt man page
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}

void main(void)
{
    vec3 viewDir = rayDirection(45.0, resolution.xy);
    vec3 eye = vec3(23.0 * sin(0.2 * time), 4., 23.0 * cos(0.2 * time));
    
    mat4 viewToWorld = viewMatrix(eye, vec3(0.0, 2.0, 0.0), vec3(0.0, 1.0, 0.0));
    
    vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
    
    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
    
    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        glFragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    
    // The closest point on the surface to the eyepoint along the view ray
    vec3 p = eye + dist * worldDir;
    
    vec3 K_a = vec3(1.2, 1.2, 1.4);
    vec3 K_d = vec3(0.8, 0.8, 0.8);
    vec3 K_s = vec3(0.1, 0.1, 0.1);
    float shininess = 2.0;
    
    vec3 color = phongIllumination(K_a, K_d, K_s, shininess, p, eye);
    
    glFragColor = vec4(color, 1.0);
}
