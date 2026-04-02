#version 420

// original https://www.shadertoy.com/view/3tj3W3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;
const float BUMP_FACTOR = 0.1;
const float TEMPERATURE = 2200.0;

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

float octaveNoise( in vec3 p ) {
    p += vec3(23.481, 67.44, 68.81);
    return 0.7*noise(p) + 0.2*noise(p*4.0)  + 0.1*noise(p*10.0);
}

vec3 blackbody(float t)
{
    t *= TEMPERATURE;
    
    float u = ( 0.860117757 + 1.54118254e-4 * t + 1.28641212e-7 * t*t ) 
            / ( 1.0 + 8.42420235e-4 * t + 7.08145163e-7 * t*t );
    
    float v = ( 0.317398726 + 4.22806245e-5 * t + 4.20481691e-8 * t*t ) 
            / ( 1.0 - 2.89741816e-5 * t + 1.61456053e-7 * t*t );

    float x = 3.0*u / (2.0*u - 8.0*v + 4.0);
    float y = 2.0*v / (2.0*u - 8.0*v + 4.0);
    float z = 1.0 - x - y;
    
    float Y = 1.0;
    float X = Y / y * x;
    float Z = Y / y * z;

    mat3 XYZtoRGB = mat3(3.2404542, -1.5371385, -0.4985314,
                        -0.9692660,  1.8760108,  0.0415560,
                         0.0556434, -0.2040259,  1.0572252);

    return max(vec3(0.0), (vec3(X,Y,Z) * XYZtoRGB) * pow(t * 0.0004, 4.0));
}

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

float bumpCylynderSDF(vec3 p, float h, float r) {
    // get distance to plane as usual
    float d = cylinderSDF(p, h, r);
    
    vec3 normal;
    float bump = 0.0;
    
      // only consider bumps if close to plane
    if(d < BUMP_FACTOR*1.5)
    {    
        normal = normalize(vec3(p.x, p.y, 0.0));
        bump = octaveNoise(10.0*p + 0.4*vec3(time, time, time))*min(0.0, 1.7*(p.z + 1.4));
    }
    return d - bump;
}

/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */
float sceneSDF(vec3 samplePoint) {    
    
    float cylinderRadius = 0.35;
    float cylinder = bumpCylynderSDF(rotateX(radians(90.0))*(samplePoint + vec3(0.0, 1.0, 0.0)), 7.0, cylinderRadius);

    return cylinder;
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
vec3 shading(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye,
                          vec3 lightPos, vec3 lightIntensity) {
    vec3 N = estimateNormal(p);
    vec3 L = normalize(lightPos - p);
    
    float dotLN = dot(L, N);
    
    if (dotLN < 0.0) {
        // Light not visible from this point on the surface
        return vec3(0.0, 0.0, 0.0);
    } 
    
    return lightIntensity * (k_d * dotLN);
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
vec3 illumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye) {
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;
    
    vec3 light1Pos = vec3(4.0 * sin(time),
                          2.0,
                          4.0 * cos(time));
    vec3 light1Intensity = vec3(0.2, 0.2, 0.2);
    
    color += shading(k_d, k_s, alpha, p, eye,
                                  light1Pos,
                                  light1Intensity);
    
    vec3 light2Pos = vec3(2.0 * sin(0.37 * time),
                          2.0 * cos(0.37 * time),
                          2.0);
    vec3 light2Intensity = vec3(0.2, 0.2, 0.2);
    
    color += shading(k_d, k_s, alpha, p, eye,
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
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

float smokeDensity(vec2 uv) {
    return octaveNoise(vec3(uv.x*0.01, uv.y*0.005, 0.0));
}

void main(void)
{
    vec3 viewDir = rayDirection(55.0, resolution.xy);
    vec3 eye = vec3(8.0*sin(0.2*time), 3.0 + 2.0*sin(0.2*time), 8.0*cos(0.2*time));
    
    vec3 up = normalize(vec3(0.5, 1.0, 0.2));
    
    mat3 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), up);
    
    vec3 worldDir = viewToWorld * viewDir;
    
    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
    
    vec3 p = eye + dist * worldDir;
    vec3 color = vec3(0.6, 0.6, 1.0)*0.05*octaveNoise(0.2*p + vec3(0.0, 0.0, time));
    
    if (dist <= MAX_DIST - EPSILON) {
        // The closest point on the surface to the eyepoint along the view ray
        
    
        // Use the surface normal as the ambient color of the material
        float pattern = sin(60.0*p.y - 2.0*time);
        if (pattern < -0.9) pattern = -1.5;
        else pattern = 1.0;
        vec3 paper = vec3(0.8, 0.8, 0.7)*(0.95 + 0.05*pattern);
        vec3 burnt = vec3(0.08, 0.05, 0.01);
        vec3 glow = blackbody((0.3*sin(0.8*time) + 1.8)*octaveNoise(5.0*p));
        float noiseVal = octaveNoise(8.0*p - 0.2*vec3(time, time, 0.0));
        float mixing_burn = clamp(p.y + 0.7*noiseVal + 0.3, 0.0, 1.0);
        if (mixing_burn < 0.75) mixing_burn = max(0.0, mixing_burn - 0.1);
        float mixing_glow = clamp(p.y + 0.3*noiseVal, 0.0, 1.0);
        if (mixing_glow < 0.6) mixing_glow = 0.0;
        vec3 K_a = mix(paper, burnt, mixing_burn);
        K_a = mix(K_a, glow, mixing_glow);
        vec3 K_d = K_a;
        vec3 K_s = vec3(1.0, 1.0, 1.0);
        float shininess = 1.0;
    
        color = illumination(K_a, K_d, K_s, shininess, p, eye);
    
        
    }
    
    glFragColor = vec4(color, 1.0);
}
