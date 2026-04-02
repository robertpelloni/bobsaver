#version 420

// original https://www.shadertoy.com/view/WllSzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
 * Part 5 Challenges:
 * - Change the axis of motion of the cube being intersected with the sphere
 * - Rotate the intersection 
 */

const int MAX_MARCHING_STEPS = 200;
const float MIN_DIST = 8.0;
const float MAX_DIST = 21.0;
const float EPSILON = 0.0001;

const float TUBES = 8.0;

float tubeSDF(vec3 samplePoint, float radius)
{
    return length(samplePoint.yz) - radius;
}

float sceneSDF(vec3 p)
{
    vec3 pp = p;
    
    float angle = -time * 0.5 + cos(pp.x + time + cos(time * 2.0));
        
    p.y = cos(angle)*pp.y - sin(angle)*pp.z;
    p.z = sin(angle)*pp.y + cos(angle)*pp.z;
    
    p.z -= sin(pp.x - cos(time * 0.3)) * 0.25;
    
    float scene = MAX_DIST;
    
    for (float i = 0.0; i < TUBES; i += 1.0)
    {
        float angle = 6.28 * (i / TUBES);
        vec3 dp = vec3(0.0, sin(angle), cos(angle)) * 0.5;
        
        scene = min(scene, tubeSDF(p - dp, 0.2));
    }
    
    return scene;
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
        float dist = sceneSDF(eye + depth * marchingDirection) * 0.9;
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

float ao(vec3 eye) {
    float depth = 0.01;
    vec3 norma = estimateNormal(eye);
    float accum = 0.0;
    for (int i = 0; i < 10; i++) {
        float dist = sceneSDF(eye + depth * norma);
        accum += (depth - dist) / depth;
        depth += 0.02;
    }
    return 1.0 - min(accum * 0.06, 1.0);
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
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;
    
    vec3 light1Pos = vec3(4.0 * sin(time),
                          2.0,
                          4.0 * cos(time));
    vec3 light1Intensity = vec3(0.4, 0.4, 0.4);
    
    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light1Pos,
                                  light1Intensity);
    
    vec3 light2Pos = vec3(2.0 * sin(0.37 * time),
                          2.0 * cos(0.37 * time),
                          2.0);
    vec3 light2Intensity = vec3(0.4, 0.4, 0.4);
    
    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light2Pos,
                                  light2Intensity);    
    
    return color;
}

vec3 bgColor(float x)
{
    float bg = 0.7 + 0.3 * cos(x - time * 2.0) + sin(time * 4.0) * 0.05;
    return vec3(0.9, 1.15, 1.4) * bg;
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
    vec3 eye = vec3(8.0, 5.0, 7.0);
    
    mat4 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    
    vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
    
    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
    
    vec3 bgc = bgColor(worldDir.x * 30.0);
    
    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        glFragColor = vec4(bgc, 1.0);
        return;
    }
    
    // The closest point on the surface to the eyepoint along the view ray
    vec3 p = eye + dist * worldDir;
    
    vec3 K_a = vec3(0.7, 0.65, 0.2);
    vec3 K_d = vec3(1.0, 0.95, 0.2);
    vec3 K_s = vec3(0.5, 0.5, 0.5);
    float shininess = 50.0;
    
    vec3 color = (phongIllumination(K_a, K_d, K_s, shininess, p, eye) * 0.9 + bgColor(p.x) * 0.3) * (0.2 + 0.8 * ao(p));
    color = mix(color, bgColor(time * 2.0), pow(smoothstep(5.0, 30.0, dist), 2.0));
    
    glFragColor = vec4(pow(color, vec3(1.2)), 1.0);
}
