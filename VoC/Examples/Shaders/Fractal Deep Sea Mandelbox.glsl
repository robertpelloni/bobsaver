#version 420

// original https://www.shadertoy.com/view/wllczj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// deep-sea mandelbox
// by wj
// 
// This is a stripped down version of a shader I had used on my 2017 page:
// https://www.wothke.ch/modum
//
// The code is rather verbose and it might be useful to play around with
// here on shadertoy.
//
// It is heavily based on the logic from an old version of Fractal Lab 
// (see http://www.subblue.com). Copyright 2011, Tom Beddard
// 
// I am therefore using the same licence here that Tom Beddard's 
// respective code had used:
//
// Licensed under the GPL Version 3 license.
// http://www.gnu.org/licenses/

precision highp float;

#define HALFPI 1.570796
#define MIN_EPSILON 6e-7
#define MIN_NORM 1.5e-7

#define maxIterations 15                              // 1 to 30
#define stepLimit 105                                 // 10 to 300
#define aoIterations 3                                // 0 to 10

#define minRange 6e-5

            
// fractal params            
const float deFactor= 1.;                             // 0 to 1
const float scale= -2.81;                             // -10 to 10
const float surfaceDetail= 0.66;                      // 0.1 to 2
const float surfaceSmoothness= 0.79;                  // 0.01 to 1
const float boundingRadius= 114.02;                   // 0.1 to 150
const vec3 offset= vec3(0., 0., 0.);                  // -3 to 3

const float sphereScale= 1.;                          // 0.01 to 3
float boxScale= 0.5;                                  // 0.01 to 3
const float boxFold= 1.;                              // 0.01 to 3
const float fudgeFactor= 0.;                          // 0 to 100

float glitch;                                         // 0 to 0.02

// unused..  uncomment if needed
//mat3  objectRotation;
//mat3  fractalRotation1;
//mat3  fractalRotation2;

// color
const int   colorIterations= 3;                       // 0 to 30
const vec3  color1= vec3(0.4, 0.3, 0.9);
const float color1Intensity= 2.946;                   // 0 to 3 
const vec3  color2= vec3(0.1, 0.1803, 0.1);
const float color2Intensity= 0.16;                    // 0 to 3
const vec3  color3= vec3(0.3, 0.3, 0.9);
const float color3Intensity= 0.11;                    // 0 to 3
const bool  transparent= false;                       // transparent background
const float gamma= 0.799;                             // gamma correction; 0.1 to 2

// lights
const vec3  light= vec3(48, 191, -198);               // light position
const vec2  ambientColor= vec2(0.41, 0);              // ambient intensity, ambient color
const vec3  background1Color= vec3(0.7882, 1, 1);
const vec3  background2Color= vec3(0,0,0);            // background bottom

// glow
const vec3  innerGlowColor= vec3(0.23, 0.249, 0.9019);
const float innerGlowIntensity= 0.24;                 // 0, 1
const vec3  outerGlowColor= vec3(1.0, 1.0, 1.0);
const float outerGlowIntensity= 0.08;                 // 0, 1

// fog
const float fogIntensity= 0.06;                       // 0, 1
const float fogFalloff= 2.8;                          // 0, 10

// shinyness
const float specularity= 0.86;                        // 0, 3
const float specularExponent= 7.0;                    // 0, 50

// ambient occlusion
const float aoIntensity= 0.21;                        // 0 to 1
const float aoSpread= 11.79;                          // 0 to 20

// camera
const float cameraFocalLength= 0.9;                   // 0.1 to 3
float fovfactor;                                      // field of view
vec3 cameraPosition;
mat3  cameraRotation;

float aspectRatio;
float pixelScale;
float epsfactor;

vec2  size;
vec2  halfSize;

vec3  w = vec3(0, 0, 1);
vec3  v = vec3(0, 1, 0);
vec3  u = vec3(1, 0, 0);

// Pre-calculations
float mR2;                                           // Min radius
float fR2;                                           // Fixed radius
vec2  scaleFactor;
                        

// Details about the Mandelbox DE algorithm:
// http://www.fractalforums.com/3d-fractal-generation/a-mandelbox-distance-estimate-formula/
vec3 Mandelbox(vec3 w)
{
//    w *= objectRotation;
    float md = 1000.0;
    vec3 c = w;
                
    // distance estimate
    vec4 p = vec4(w.xyz, deFactor),
        p0 = vec4(w.xyz, 1.0);  // p.w is knighty's DEfactor
                
    for (int i = 0; i < int(maxIterations); i++) {
        // box fold:
        p.xyz = clamp(p.xyz, -boxFold, boxFold) * 2.0 * boxFold - p.xyz;  // box fold
//        p.xyz *= fractalRotation1;
                    
        // sphere fold:
        float d = dot(p.xyz, p.xyz);
        p.xyzw *= clamp(max(fR2 / d, mR2), 0.0, 1.0);  // sphere fold
                    
        p.xyzw = p * scaleFactor.xxxy + p0 + vec4(offset, 0.0);
//        p.xyz *= fractalRotation2;

        if (i < colorIterations) {
            md = min(md, d);
            c = p.xyz;
        }
    }
                
    // Return distance estimate, min distance, fractional iteration count
    return vec3((length(p.xyz) - fudgeFactor) / p.w, md, 0.33 * log(dot(c, c)) + 1.0);
}

// Define the ray direction from the pixel coordinates
vec3 rayDirection(vec2 pixel)
{
    vec2 p = (0.5 * halfSize - pixel) / vec2(halfSize.x, -halfSize.y);
    p.x *= aspectRatio;
    vec3 d = (p.x * u + p.y * v - cameraFocalLength * w);
    return normalize(cameraRotation * d);
}

// Intersect bounding sphere
//
// If we intersect then set the tmin and tmax values to set the start and
// end distances the ray should traverse.
bool intersectBoundingSphere(vec3 origin,
                             vec3 direction,
                             out float tmin,
                             out float tmax)
{
    bool hit = false;
    float b = dot(origin, direction);
    float c = dot(origin, origin) - boundingRadius;
    float disc = b*b - c;           // discriminant
    tmin = tmax = 0.0;

    if (disc > 0.0) {
        // Real root of disc, so intersection
        float sdisc = sqrt(disc);
        float t0 = -b - sdisc;          // closest intersection distance
        float t1 = -b + sdisc;          // furthest intersection distance

        if (t0 >= 0.0) {
            // Ray intersects front of sphere
            tmin = t0;
            tmax = t0 + t1;
        } else {
            // Ray starts inside sphere
            tmax = t1;
        }
        hit = true;
    }

    return hit;
}

// Calculate the gradient in each dimension from the intersection point
vec3 generateNormal(vec3 z, float d)
{
    float e = max(d * 0.5, MIN_NORM);
                
    float dx1 = Mandelbox(z + vec3(e, 0, 0)).x;
    float dx2 = Mandelbox(z - vec3(e, 0, 0)).x;
                
    float dy1 = Mandelbox(z + vec3(0, e, 0)).x;
    float dy2 = Mandelbox(z - vec3(0, e, 0)).x;
                
    float dz1 = Mandelbox(z + vec3(0, 0, e)).x;
    float dz2 = Mandelbox(z - vec3(0, 0, e)).x;
                
    return normalize(vec3(dx1 - dx2, dy1 - dy2, dz1 - dz2));
}

// Blinn phong shading model
// http://en.wikipedia.org/wiki/BlinnPhong_shading_model
// base color, incident, point of intersection, normal
vec3 blinnPhong(vec3 color, vec3 p, vec3 n)
{
                // Ambient colour based on background gradient
    vec3 ambColor = clamp(mix(background2Color, background1Color, (sin(n.y * HALFPI) + 1.0) * 0.5), 0.0, 1.0);
    ambColor = mix(vec3(ambientColor.x), ambColor, ambientColor.y);
                
    vec3  halfLV = normalize(light - p);
    float diffuse = max(dot(n, halfLV), 0.0);
    float specular = pow(diffuse, specularExponent);
                
    return ambColor * color + color * diffuse + specular * specularity;
}

// Ambient occlusion approximation.
// Based upon boxplorer's implementation which is derived from:
// http://www.iquilezles.org/www/material/nvscene2008/rwwtt.pdf
float ambientOcclusion(vec3 p, vec3 n, float eps)
{
    float o = 1.0;                  // Start at full output colour intensity
    eps *= aoSpread;                // Spread diffuses the effect
    float k = aoIntensity / eps;    // Set intensity factor
    float d = 2.0 * eps;            // Start ray a little off the surface
                
    for (int i = 0; i < aoIterations; ++i) {
        o -= (d - Mandelbox(p + n * d).x) * k;
        d += eps;
        k *= 0.5;                   // AO contribution drops as we move further from the surface 
    }
                
    return clamp(o, 0.0, 1.0);
}

// Calculate the output color for each input pixel
vec4 render(vec2 pixel)
{
    vec3  ray_direction = rayDirection(pixel);
    
    float ray_length = minRange;
    vec3  ray = cameraPosition + ray_length * ray_direction;
    vec4  bg_color = vec4(clamp(mix(background2Color, background1Color, (sin(ray_direction.y * HALFPI) + 1.0) * 0.5), 0.0, 1.0), 1.0);
    vec4  color = bg_color;
                
    float eps = MIN_EPSILON;
    vec3  dist;
    vec3  normal = vec3(0);
    int   steps = 0;
    bool  hit = false;
    float tmin = 0.0;    // 'out' params of intersectBoundingSphere()
    float tmax = 0.0;
            
    if (intersectBoundingSphere(ray, ray_direction, tmin, tmax)) {
        ray_length = tmin;
        ray = cameraPosition + ray_length * ray_direction;

           vec3  lastDist= vec3(0.,0.,0.);
            
        for (int i = 0; i < stepLimit; i++) {
            steps = i;
            dist = Mandelbox(ray);
            dist.x *= surfaceSmoothness;
                        
            // If we hit the surface on the previous step check again to make sure it wasn't
            // just a thin filament
            if (hit && dist.x < eps || ray_length > tmax || ray_length < tmin) {    // XXX ray_length < tmin impossible!
                steps--;
                break;
            }
                        
            hit = false;
            ray_length += dist.x;    // XXX dist.x is always positive...
            ray = cameraPosition + ray_length * ray_direction;
            eps = ray_length * epsfactor;

            // add-on effect hack: "distant" stuff turns into water...             
            if (ray_length > 0.1) {
                ray_length+=glitch;
                hit = true;
            } else if (dist.x < eps || ray_length < tmin) {
                hit = true;    // normal mode
                lastDist= dist;            
            }
        }
    }
                
    // Found intersection?
    float glowAmount = float(steps)/float(stepLimit);
    float glow;
                
    if (hit) {
        float aof = 1.0, shadows = 1.0;
        glow = clamp(glowAmount * innerGlowIntensity * 3.0, 0.0, 1.0);

        if (steps < 1 || ray_length < tmin) {
            normal = normalize(ray);
        } else {
            normal = generateNormal(ray, eps);
            aof = ambientOcclusion(ray, normal, eps);
        }
                    
        color.rgb = mix(color1, mix(color2, color3, dist.y * color2Intensity), dist.z * color3Intensity);
        color.rgb = blinnPhong(clamp(color.rgb * color1Intensity, 0.0, 1.0), ray, normal);
        color.rgb *= aof;
        color.rgb = mix(color.rgb, innerGlowColor, glow);
            
        // make details disapear in the distant fog
        color.rgb = mix(bg_color.rgb, color.rgb, exp(-pow(abs(ray_length * exp(fogFalloff)), 2.0) * fogIntensity));
        color.a = 1.0;
    } else {
        // Apply outer glow and fog
        ray_length = tmax;
        color.rgb = mix(bg_color.rgb, color.rgb, exp(-pow(abs(ray_length * exp(fogFalloff)), 2.0)) * fogIntensity);
        glow = clamp(glowAmount * outerGlowIntensity * 3.0, 0.0, 1.0);
                    
        color.rgb = mix(color.rgb, outerGlowColor, glow);
        if (transparent) color = vec4(0.0);
    }
    return color; 
}

// Return rotation matrix for rotating around vector v by angle
mat3 rotationMatrixVector(vec3 v, float angle)
{
    float c = cos(radians(angle));
    float s = sin(radians(angle));
                
    return mat3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
              (1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
              (1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z);
}

void main(void)
{
    // size of generated texture   
    size = resolution.xy;
    halfSize= size/2.0;
       
    // setup camera
    vec3 dir= vec3(20.*sin(time*.33), 20.*sin(time*.33), -22.);     // 180= full circle
    cameraPosition= vec3( 0.17963 + sin(time*.1)*.4, 
                          0.099261, 
                         -1.3678434 + sin(time*.05)*.2);    
        
    cameraRotation=     rotationMatrixVector(u, dir.x) *
                        rotationMatrixVector(v, dir.y) * 
                        rotationMatrixVector(w, dir.z);
    
    fovfactor = 1.0 / sqrt(1.0 + cameraFocalLength * cameraFocalLength);
    aspectRatio = size.x / size.y;
    pixelScale = 1.0 / min(size.x, size.y);
    epsfactor = 2.0 * fovfactor * pixelScale * surfaceDetail;

    // animate box scale
    float freq= 1.0;    // 0 to 512    (use some bass frequeny)
    float fft= 0.0;//texelFetch( iChannel0, ivec2(freq,0), 0 ).x; 
    boxScale= 0.5 + fft*0.03;
    
        // update derived fractal
    mR2 = boxScale * boxScale;
    fR2 = sphereScale * mR2;
    scaleFactor = vec2(scale, abs(scale)) / mR2;
    
    
    // throw in glitch effect once in a while 
    float m= mod(time*.2, 2.0); 
    if (m <= 1.0) {
        glitch= 0.002*(2.0-(cos(m*HALFPI*4.)+1.0));
    } else {
        glitch= 0.00;
    }
                        
    vec4 color = render(gl_FragCoord.xy);    // do without antialiasing to limit GPU load                
    glFragColor = vec4(pow(abs(color.rgb), vec3(1.0 / gamma)), color.a);
}
