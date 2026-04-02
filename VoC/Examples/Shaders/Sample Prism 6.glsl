#version 420

// original https://www.shadertoy.com/view/lsGyzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/////////////////
// // Created by  Jamie Wong
// 15/03/2018  jmaire: prisme de base hexagonale
//

/**
 * Part 6 Challenges:
 * - Make a scene of your own! Try to use the rotation transforms, the CSG primitives,
 *   and the geometric primitives. Remember you can use vector subtraction for translation,
 *   and component-wise vector multiplication for scaling.
 */

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;
const float PI=3.14159;
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
 * Constructive solid geometry intersection operation on SDF-calculated distances.
 */
float intersectSDF(float distA, float distB) {
    return max(distA, distB);
}

/**
 * Constructive solid geometry union operation on SDF-calculated distances.
 */
float unionSDF(float distA, float distB) {
    return min(distA, distB);
}

/**
 * Constructive solid geometry difference operation on SDF-calculated distances.
 */
float differenceSDF(float distA, float distB) {
    return max(distA, -distB);
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

/**
 * Signed distance function for a sphere centered at the origin with radius r.
 */
float sphereSDF(vec3 p, float r) {
    return length(p) - r;
}

/**
 * Signed distance function for an XY aligned cylinder centered at the origin with
 * height h and radius r.
 */
float cylinderSDF(vec3 p, float h, float r) {
    // How far inside or outside the cylinder the point is, radially
    float inOutRadius = length(p.xy) - r;
    
    // How far inside or outside the cylinder is, axially aligned with the cylinder
    float inOutHeight = abs(p.z) - h/2.0;
    
    // Assuming p is inside the cylinder, how far is it from the surface?
    // Result will be negative or zero.
    float insideDistance = min(max(inOutRadius, inOutHeight), 0.0);

    // Assuming p is outside the cylinder, how far is it from the surface?
    // Result will be positive or zero.
    float outsideDistance = length(max(vec2(inOutRadius, inOutHeight), 0.0));
    
    return insideDistance + outsideDistance;
}

float hexagonSDF(vec3 p,float h,float r){
    float ag=(p.y>0.0)? acos(p.x/length(p.xy)):2.0*PI - acos(p.x/length(p.xy));
 ag=ag+PI/6.0+time*2.0;
float n=floor(ag/(PI/3.0));
float b=ag-n*PI/3.0-PI/6.0  ;
float inoutrayon= cos(b)*length(p.xy)-r;
float inoutheight=abs(p.z)-h/2.0;
float insideDistance=min(max(inoutrayon,inoutheight),0.0);
 float outsideDistance = length(max(vec2(inoutrayon, inoutheight), 0.0));
    
    return insideDistance + outsideDistance;

}

float pMod(float t, float d) {
    return mod(t + d/2.0, d) - d/2.0;
}

/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */
float sceneSDF(vec3 p) {    
    // Slowly spin the whole scene
     p = rotateZ(sin(-time*0.05)) * p; 
   p = rotateX(cos(0.1*time))* p;
  p = rotateY(cos(time*0.05 )) * p;
 
 
  // p+=cos(time*0.1)*vec3(10.0,0.0,5.0);
   p.z = pMod(p.z,1.1);
  // p.y = pMod(p.y,5.8 );
  p.x = pMod(p.x,1.1);
    
    //float cylinderRadius = 0.4 + (2.0 - 0.4) * (1.0 + sin(1.7 * time)) / 4.0;
    float cylinderRadius =0.15;
    float cylinderHeight = 1.2;
    float cylinder1 = hexagonSDF(p, cylinderHeight, cylinderRadius);
    float cylinder2 = hexagonSDF(rotateX(radians(90.0)) * p,(cos(time*0.3)*3.0+ 3.1)*cylinderHeight, cylinderRadius);
    float cylinder3 = hexagonSDF(rotateY(radians(90.0)) * p, cylinderHeight, cylinderRadius);
    
    float cube = boxSDF(p, vec3(1.8, 1.8, 1.8));
    
    float sphere = sphereSDF(p, .2);
    
    //float ballOffset = 0.4 + 1.0 + sin(1.7 * time);
    //float ballRadius = 0.3;
    //float balls = sphereSDF(p - vec3(ballOffset, 0.0, 0.0), ballRadius);
    //balls = unionSDF(balls, sphereSDF(p + vec3(ballOffset, 0.0, 0.0), ballRadius));
    //balls = unionSDF(balls, sphereSDF(p - vec3(0.0, ballOffset, 0.0), ballRadius));
    //balls = unionSDF(balls, sphereSDF(p + vec3(0.0, ballOffset, 0.0), ballRadius));
    //balls = unionSDF(balls, sphereSDF(p - vec3(0.0, 0.0, ballOffset), ballRadius));
    //balls = unionSDF(balls, sphereSDF(p + vec3(0.0, 0.0, ballOffset), ballRadius));
    
    
    
    float csgNut = differenceSDF(sphere,//intersectSDF(cube, sphere),
                         unionSDF(cylinder1, unionSDF(cylinder2, cylinder3)));
    
    //return unionSDF(balls, csgNut);
    return unionSDF(cylinder1, unionSDF(cylinder2, cylinder3));
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
 * Return the normalized direction to march in from the eye point for a single pixel.
 * 
 * fieldOfView: vertical field of view in degrees
 * size: resolution of the output image
 * gl_FragCoord: the x,y coordinate of the pixel in the output image
 */

/*
vec3 rayDirection(float fieldOfView, vec2 size, vec2 gl_FragCoord) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}
*/
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
        return lightIntensity * (k_d * dotLN);
    }
    return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha*5.0));
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
    const vec3 ambientLight = vec3(1.0, 0.0, 1.0);
    vec3 color = ambientLight * k_a;
    
    vec3 light1Pos = vec3(-4.0 * sin(time*0.05),
                         0.0,
                          4.0 * cos(time*0.05));
    vec3 light1Intensity = vec3(1.0,0.0, 1.0);
    
    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light1Pos,
                                  light1Intensity);
    
    vec3 light2Pos = vec3(-4.0 * sin(0.07 * time),
                          -2.0 * cos(0.07 * time),
                          -4.0*sin(0.1*time));
    vec3 light2Intensity = vec3(1.0, 1.0, 1.0);
    
    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light2Pos,
                                  light2Intensity);    
    return color;
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
    vec3 s = cross(f, up);
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

void main(void)
{
    
    vec2 pxy = gl_FragCoord.xy - resolution.xy / 2.0;
    float z = resolution.y /( tan(PI/4.0) / 2.0);
    vec3 viewDir= normalize(vec3(pxy, -z));

    vec3 eye = vec3(0.0, 42.0,0.0);
    
    mat3 viewToWorld = viewMatrix(eye, vec3(5.0, 5.0, 5.0), vec3(0.0, 1.0, 0.0));
    
    vec3 worldDir = viewToWorld * viewDir;
    
    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
    
    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        glFragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    
    // The closest point on the surface to the eyepoint along the view ray
    vec3 p = eye + dist * worldDir;
    
    // Use the surface normal as the ambient color of the material
    vec3 K_a = (estimateNormal(p) + vec3(1.0)*0.2) ;
    vec3 K_d = K_a- vec3(1.0)*0.4 ;
    vec3 K_s = vec3(1.0,1.0, 1.0);
    float shininess = 30.0;
    
    vec3 color = phongIllumination(K_a, K_d, K_s, shininess, p, eye);
    
    glFragColor = vec4(color, 1.0);
}
