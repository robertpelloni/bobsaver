#version 420

// original https://www.shadertoy.com/view/MtsBDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int ITERATIONS = 40;
const int MAX_MARCHING_STEPS = 100;
const float MIN_DIST = 1.5;
const float MAX_DIST = 7.5;
const float EPSILON = 0.002;
const float ORBIT_TIME = 2.0;
const float PI = 3.141592653;
const float MIN_POWER = 5.0;
const float MAX_POWER = 9.0;
const float POWER_TIME = 70.0;
const vec3 xDir = vec3(1,0,0);
const vec3 yDir = vec3(0,1,0);
const vec3 zDir = vec3(0,0,1);
const int USE_SPECULAR = 0;
const float SHADOW_VISIBILITY = 0.15;
const float ROTATION_TIME = 29.0;

vec3 bulbPower(vec3 z, float power)
{
    float r = length(z);
    // convert to polar coordinates
    float theta = acos(z.z/r);
    float phi = atan(z.y,z.x);
        
    // scale and rotate the point
    float zr = pow(r, power);
    theta = theta * power;
    phi = phi * power;
        
    // convert back to cartesian coordinates
    z = zr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
    return z;
}

float DE(vec3 pos) 
{
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    float power = MIN_POWER + (MAX_POWER-MIN_POWER) * (sin(time * 2.0 * PI / POWER_TIME) + 1.0) ;
    for (int i = 0; i < ITERATIONS ; i++) {
        r = length(z);
        if (r > 2.0) break;
        dr =  pow( r, power-1.0)*power*dr + 1.0;
        
        z = bulbPower(z, power) + pos;
    }
    return 0.5*log(r)*r/dr;
}

/*
vec3 gradient;
int last = 0;
float escapeLength(in vec3 pos)
{
    vec3 z = pos;
    for( int i=1; i<ITERATIONS; i++ )
    {
        z = bulbPower(z, POWER) + pos;
        float r2 = dot(z,z);
        if ((r2 > 4.0 && last==0) || (i==last))
        {
            last = i;
            return length(z);
        }
    }    
    return length(z);
}
 
float gradientDE(vec3 p) {
    last = 0;
    float r = escapeLength(p);
    if (r*r < 2.0) return 0.0;
    gradient = (vec3(escapeLength(p+xDir*EPSILON), escapeLength(p+yDir*EPSILON), escapeLength(p+zDir*EPSILON))-r)/EPSILON;
    return 0.5*r*log(r)/length(gradient);
}
*/

/**
 * returns the shortest distance from the eyepoint to the scene surface along
 * the marching direction. If no part of the surface is found between start and end,
 * end is returned
 * 
 * eye: the eye point, acting as the origin of the ray
 * marchingDirection: the normalized direction to march in
 * start: the starting distance away from the eye
 * end: the max distance away from the eye to march before giving up
 */
float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = DE(eye + depth * marchingDirection);
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
 * returns the normalized direction to march in from the eye point for a single pixel.
 * 
 * fieldOfView: vertical field of view in degrees
 * size: resolution of the output image
 * gl_FragCoord: the x,y coordinate of the pixel in the output image
 */
vec3 rayDirection(float fieldOfView, vec2 size, vec2 gl_FragCoord) {
    vec2 xy = gl_FragCoord - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

/**
 * using the gradient of the DE, estimate the normal on the surface at point p.
 */
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        DE(vec3(p.x + EPSILON, p.y, p.z)) - DE(vec3(p.x - EPSILON, p.y, p.z)),
        DE(vec3(p.x, p.y + EPSILON, p.z)) - DE(vec3(p.x, p.y - EPSILON, p.z)),
        DE(vec3(p.x, p.y, p.z  + EPSILON)) - DE(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

/**
 * calculates ighting contribution for a single point light source via Phong illumination.
 * 
 * the vec3 returned is the RGB color of the light's contribution.
 *
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 * lightPos: the position of the light
 * lightIntensity: color/intensity of the light
 */
vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye,
                          vec3 lightPos, vec3 lightIntensity) 
{
    vec3 color;
    
    vec3 N = estimateNormal(p);
    vec3 L = normalize(lightPos - p);
    float dotLN = dot(L, N);
    if (dotLN < 0.0) {
        // light not visible from this point on the surface
        return vec3(0.0, 0.0, 0.0);
    } 
    else
    {
        if (USE_SPECULAR == 1)
        {
            vec3 V = normalize(eye - p);
            vec3 R = normalize(reflect(-L, N));
            float dotRV = dot(R, V);
            //vec3 H = normalize(L * V);
            //float dotNH = dot(N, H);
            if (dotRV < 0.0) 
            {
                // light reflection in opposite direction as viewer, apply only diffuse
                // component
                color = lightIntensity * (k_d * dotLN);
            }
            else
                color = lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
        }
        else
        {
            color = lightIntensity * (k_d * dotLN);
        }
        
        vec3 lightToPos = p - lightPos;
        float maxDist = length(lightToPos);
        float dist = shortestDistanceToSurface(lightPos, normalize(lightToPos), 0.0f, maxDist);
        if (dist <= maxDist - EPSILON) 
        {
            // hit something between light source and point -> shadow
            return color * SHADOW_VISIBILITY; //
        }
    }
    return color;
}

/**
 * lighting via Phong illumination.
 * 
 * the vec3 returned is the RGB color of that point after lighting is applied.
 * k_a: Ambient color of the surface
 * k_d: Diffuse color of the surface
 * k_s: Specular color of the surface
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 */
vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye) {
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;
    
    vec3 light1Pos = vec3(2.5*sin(time * 2.0 * PI / ROTATION_TIME), 2.0, 3.0*cos(time * 2.0 * PI / ROTATION_TIME));
    vec3 light1Intensity = vec3(1, 1, 1);
    
    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light1Pos,
                                  light1Intensity);
    

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
    vec3 viewDir = rayDirection(45.0, resolution.xy, gl_FragCoord.xy);
    vec3 eye = vec3(3.0*sin(time * 2.0 * PI / ROTATION_TIME), (sin(time + 1.0)) * 0.7, 6.0*cos(time * 2.0 * PI / ROTATION_TIME));

    mat4 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    
    vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
    
    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
    
    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        glFragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    
    // The closest point on the surface to the eyepoint along the view ray
    vec3 p = eye + dist * worldDir;
    float distance = length(p);
    float scale = (distance - 0.5) * 1.2;
    //0.3, 0.1
    //0.7, 0.24
    vec3 K_a = vec3(0.7 - 0.4 * scale, 0.24 - 0.14 * scale, 0.0) / 2.0;
    vec3 K_d = K_a * 2.8;
    vec3 K_s = K_a * 2.0;
    float shininess = 50.0;
    
    vec3 color = phongIllumination(K_a, K_d, K_s, shininess, p, eye);
    
    glFragColor = vec4(color, 1.0);
}
