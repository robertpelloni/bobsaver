#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/4dlfzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float NearClip         = 0.0;
const float FarClip          = 150.0;
const float Epsilon          = 0.0001;
const vec3  AmbientLight     = vec3(0.8);
const float SoftShadowFactor = 1024.0;
const float SoftShadowOffset = 0.3;
const uint  MultiSamples     = 4u;

const float PiUnderOne       = 0.31830988;
const float PiTwoUnderOne    = 0.15915494;

const vec3 PinkColor         = vec3(1.0, 0.40, 0.65);
const vec3 ChocolateColor    = vec3(0.415, 0.207, 0.085);

const vec3 SprinkleColors[3] = vec3[](
    vec3(0.0, 1.0, 1.0),
    vec3(0.7, 1.0, 0.0),
    vec3(0.5, 0.0, 0.9));

uint PRNGSeed = 1337u;

vec3 BoxOrigin = vec3(0.0);
const float TimeLimit = 8.0;

//------------------------------------------------------------------------------------------
// Misc Math Functions
//------------------------------------------------------------------------------------------

/**
 * if(a > b) { return ra; } else { return rb; }
 */
vec3 StepValue(float a, float b, vec3 ra, vec3 rb)
{
    float s = step(a, b);
    return (ra * abs(s - 1.0)) + (rb * s);
}

float StepValue(float a, float b, float ra, float rb)
{
    float s = step(a, b);
    return (ra * abs(s - 1.0)) + (rb * s);
}

//------------------------------------------------------------------------------------------
// Noise
//------------------------------------------------------------------------------------------

/**
 * Naive PRNG seeding function.
 */
void Seed(vec2 coord)
{
    coord = abs(coord);
    
    float x = floor(coord.x * 1000.0);
    float y = floor(coord.y * 1000.0);
    
    //PRNGSeed = uint(floor(length(coord) * 100.0));
    PRNGSeed = uint((x * 63.0) + (y * 84.0));
}

/**
 * XorShift32 PRNG
 * Adapted from: https://github.com/ssell/noisegen/blob/master/scripts/noise.js
 *
 * \return PRNG value on range [-1.0, 1.0]
 */
float NoiseXorShift32()
{
    uint x = PRNGSeed;
    
    x = x ^ (x << 13u);
    x = x ^ (x >> 17u);
    x = x ^ (x << 5u);
    
    PRNGSeed = x;
    
    return (float(x % 200u) - 100.0) * 0.01;
}

//------------------------------------------------------------------------------------------
// Ray Structures and Functions
//------------------------------------------------------------------------------------------
    
struct Ray
{
    vec3 origin;
    vec3 direction;
};
    
struct RayHit
{
    bool  hit;
      vec3  surfPos;
    vec3  surfNorm;
    float material;
};

//------------------------------------------------------------------------------------------
// Camera Structures and Functions
//------------------------------------------------------------------------------------------

struct Camera
{
    vec3 right;
    vec3 up;
    vec3 forward;
    vec3 origin;
};

Ray Camera_GetRay(in Camera camera, vec2 uv)
{
    Ray ray;
    
    uv    = (uv * 2.0) - 1.0;
    uv.x *= (resolution.x / resolution.y);
    
    ray.origin    = camera.origin;
    ray.direction = normalize((uv.x * camera.right) + (uv.y * camera.up) + (camera.forward * 2.5));

    return ray;
}

Camera Camera_LookAt(vec3 origin, vec3 lookAt)
{
    Camera camera;
    
    camera.origin  = origin;
    camera.forward = normalize(lookAt - camera.origin);
    camera.right   = normalize(cross(camera.forward, vec3(0.0, 1.0, 0.0)));
    camera.up      = normalize(cross(camera.right, camera.forward));
    
    return camera;
}

//------------------------------------------------------------------------------------------
// Model Torus
//------------------------------------------------------------------------------------------

struct ModelTorus
{
    vec3  origin;
    float radius;
    float thickness;
};
    
float Torus_SDF(vec3 point, ModelTorus t)
{
    vec2 q = vec2(length(point.xz - t.origin.xz) - t.radius, point.y - t.origin.y);
    return length(q) - t.thickness;
}

//------------------------------------------------------------------------------------------
// Model Ellipsoid
//------------------------------------------------------------------------------------------

struct ModelEllipsoid
{
    vec3 origin;
    vec3 radius;
};
    
float Ellipsoid_SDF(vec3 point, ModelEllipsoid e)
{
    return (length((point - e.origin) / e.radius) - 1.0) * min(min(e.radius.x, e.radius.y), e.radius.z);
}

//------------------------------------------------------------------------------------------
// Model Box
//------------------------------------------------------------------------------------------

struct ModelBox
{
    vec3 origin;
    vec3 bounds;
};
    
float Box_SDF(vec3 point, ModelBox box)
{
    return length(max(abs(point - box.origin) - box.bounds, 0.0));   
}

//------------------------------------------------------------------------------------------
// Sprinkles
//------------------------------------------------------------------------------------------

float Sprinkle_SDF(vec3 point, float i, float a, float y, ModelTorus doughnut, ModelEllipsoid sprinkle)
{
    float sR = doughnut.radius + (doughnut.thickness * 0.5 * i);
    vec3  sOrigin = doughnut.origin + vec3(sR * sin(a), y, sR * cos(a));
    
    sprinkle.origin = sOrigin;
    
    NoiseXorShift32();
    
    return Ellipsoid_SDF(point, sprinkle);
}

float Sprinkles_SDF(vec3 point, float s, ModelTorus doughnut, inout float material)
{
    float final = s;
    float sdf = s;
    
    Seed(vec2(1337.0, 797.0));
    
    ModelEllipsoid sprinkle;
    sprinkle.radius = vec3(0.35, 0.075, 0.075);
    
    for(float angle = 0.0; angle < 6.20; angle += 0.5)
    {
        sdf = Sprinkle_SDF(point,  0.0, angle, 1.85, doughnut, sprinkle);
        material = StepValue(sdf, final, material, (8.0 + float(PRNGSeed % 3u)));
        final = min(final, sdf);
        
        sdf = Sprinkle_SDF(point,  1.0, angle, 1.55, doughnut, sprinkle);
        material = StepValue(sdf, final, material, (8.0 + float(PRNGSeed % 3u)));
        final = min(final, sdf);
        
        sdf = Sprinkle_SDF(point, -1.0, angle, 1.55, doughnut, sprinkle);
        material = StepValue(sdf, final, material, (8.0 + float(PRNGSeed % 3u)));
        final = min(final, sdf);
    }
    
    return final;
}

//------------------------------------------------------------------------------------------
// Scene Structures and Functions
//------------------------------------------------------------------------------------------

float Doughnuts_SDF(vec3 point, inout RayHit hit, float shadow)
{
    float final = FarClip;
    float sdf   = FarClip;
    float time  = mod(time, TimeLimit);
    
    time *= step(time, TimeLimit - 2.0);
    
    ModelTorus doughnutA;
    doughnutA.origin    = vec3(0.0);
    doughnutA.radius    = 4.0;
    doughnutA.thickness = 1.75;
    
    ModelEllipsoid doughnutB;
    doughnutB.radius = vec3(5.75, 3.5, 5.75);
    
    doughnutA.origin = vec3(-12.0, 1.75, 0.0);
    sdf = Torus_SDF(point, doughnutA) + (FarClip * step(time, 1.5));
    hit.material = StepValue(sdf, final, hit.material, 0.0);
    final = min(final, sdf);
    
    doughnutA.origin = vec3(-12.0, 1.75, 12.0);
    sdf = Torus_SDF(point, doughnutA) + (FarClip * step(time, 2.0));
    hit.material = StepValue(sdf, final, hit.material, 1.0);
    final = min(final, sdf);
    
    doughnutB.origin = vec3(0.0, 1.75, 0.0);
    sdf = Ellipsoid_SDF(point, doughnutB) + (FarClip * step(time, 2.5));
    hit.material = StepValue(sdf, final, hit.material, 2.0);
    final = min(final, sdf);
    
    doughnutB.origin = vec3(0.0, 1.0, 12.0);
    sdf = Ellipsoid_SDF(point, doughnutB) + (FarClip * step(time, 3.0));
    hit.material = StepValue(sdf, final, hit.material, 3.0);
    final = min(final, sdf);
    
    doughnutA.origin = vec3(12.0, 1.75, 0.0);
    sdf = Torus_SDF(point, doughnutA) + (FarClip * step(time, 3.5));
    hit.material = StepValue(sdf, final, hit.material, 5.0);
    final = min(final, sdf);
    
    doughnutA.origin = vec3(12.0, 1.75, 12.0);
    sdf = Torus_SDF(point, doughnutA) + (FarClip * step(time, 4.0));
    hit.material = StepValue(sdf, final, hit.material, 4.0);
    final = min(final, sdf);
    
    if(sdf > Epsilon && sdf < 0.5 && shadow < Epsilon)
    {
        final = min(final, Sprinkles_SDF(point, final, doughnutA, hit.material));
    }
    
    return final;
}

const vec3 BoxOrigins[10] = vec3[](
    vec3(   0.0, -89.9,    6.0),  vec3(  0.0, -0.1,  6.0),   // Bottom
    vec3(-108.0,   2.4,    6.0),  vec3(-18.0,  2.4,  6.0),   // Left
    vec3( 108.0,   2.4,    6.0),  vec3( 18.0,  2.4,  6.0),   // Right
    vec3(   0.0,   2.4, -107.95), vec3(  0.0,  2.4, -7.95),  // Back
     vec3(  0.0,   2.4,  109.95), vec3(  0.0,  2.4, 19.95)   // Front
    );

const vec3 BoxBounds[5] = vec3[](
    vec3(17.95, 0.1, 13.95),
    vec3(0.05, 2.6, 14.0),
    vec3(0.05, 2.6, 14.0),
    vec3(18.0, 2.6, 0.05),
    vec3(18.0, 2.6, 0.05)
    );

float DoughnutBoxBottom_SDF(vec3 point, inout RayHit hit)
{
    float sdf  = FarClip;
    float lerp = clamp((mod(time, TimeLimit) * 0.85f), 0.0, 1.0);
    
    // Box Base
    
    ModelBox box;
    
    box.origin = mix(BoxOrigins[0], BoxOrigins[1], lerp) + BoxOrigin;
    box.bounds = BoxBounds[0];
    
    sdf = Box_SDF(point, box);
    
    if(sdf < Epsilon)
    {
        hit.material = 7.0;
        return sdf;
    }
    
    // Box Left Side
    
    box.origin = mix(BoxOrigins[2], BoxOrigins[3], lerp) + BoxOrigin;
    box.bounds = BoxBounds[1];
    
    sdf = min(sdf, Box_SDF(point, box));
    
    // Box Right Side
    
    box.origin = mix(BoxOrigins[4], BoxOrigins[5], lerp) + BoxOrigin;
    box.bounds = BoxBounds[2];
    
    sdf = min(sdf, Box_SDF(point, box));
    
    // Box Back Side
    
    box.origin = mix(BoxOrigins[6], BoxOrigins[7], lerp) + BoxOrigin;
    box.bounds = BoxBounds[3];
    
    sdf = min(sdf, Box_SDF(point, box));
    
    // Box Front Side
    
    box.origin = mix(BoxOrigins[8], BoxOrigins[9], lerp) + BoxOrigin;
    box.bounds = BoxBounds[4];
    
    sdf = min(sdf, Box_SDF(point, box));
    
    hit.material = StepValue(sdf, Epsilon, hit.material, 6.0);
    
    return sdf;
}

float DoughnutBoxTop_SDF(vec3 point, inout RayHit hit)
{
    float sdf = FarClip;
    vec3 offset = BoxOrigin + mix(vec3(0.0, 90.0, 0.0), vec3(0.0, 1.0, 0.0), clamp((mod(time, TimeLimit) - 4.0) * 0.65, 0.0, 1.0));
    
    // Box Top
    
    ModelBox box;
    
    box.origin = BoxOrigins[1] + vec3(0.0, 5.0, 0.0) + offset;
    box.bounds = BoxBounds[0];
    
    sdf = Box_SDF(point, box);
    
    // Box Left Side
    
    box.origin = BoxOrigins[3] + offset;
    box.bounds = BoxBounds[1];
    
    sdf = min(sdf, Box_SDF(point, box));
    
    // Box Right Side
    
    box.origin = BoxOrigins[5] + offset;
    box.bounds = BoxBounds[2];
    
    sdf = min(sdf, Box_SDF(point, box));
    
    // Box Back Side
    
    box.origin = BoxOrigins[7] + offset;
    box.bounds = BoxBounds[3];
    
    sdf = min(sdf, Box_SDF(point, box));
    
    // Box Front Side
    
    box.origin = BoxOrigins[9] + offset;
    box.bounds = BoxBounds[4];
    
    sdf = min(sdf, Box_SDF(point, box));
    
    hit.material = StepValue(sdf, Epsilon, hit.material, 6.0);
    
    return sdf;
}

/**
 * Performs SDF test for the entire scene.
 * The scene is defined within this function and follows the pattern of:
 *
 *     - Test SDF of Object 0
 *         - If SDF 0 < Nearest Hit
 *         - Set RayHit nearest and position
 *         - Calculate RayHit normal for Object 0
 *     - Test SDF of Object 1
 *         - If SDF 1 < Nearest Hit
 *         - Set RayHit nearest and position
 *         - Calculate RayHit normal for Object 1
 *     - Continue for rest of Scene Objects
 */
float Scene_SDF(vec3 point, inout RayHit hit, float shadow)
{
    float sdf = FarClip;
    
    float doughnutsSDF = Doughnuts_SDF(point, hit, shadow);
    float boxBottomSDF = DoughnutBoxBottom_SDF(point, hit);
    float boxTopSDF    = DoughnutBoxTop_SDF(point, hit);
    
    sdf = min(sdf, min(doughnutsSDF, min(boxBottomSDF, boxTopSDF)));
    
    return sdf;
}

/**
 * Calculates the normal of a given surface point.
 *
 * In essence it tests multiple points around the surface and uses those SDF
 * values to generate a normal vector.
 *
 * For example, if SDF(vec3(x + e, y, z)) is smaller than SDF(vec3(x - e, y, z))
 * then we know vec3(x + e, y, z) lies further within the surface and thus opposite
 * of the normal's x-component.
 */
vec3 Scene_Normal(vec3 point)
{
    RayHit hit;

    return normalize(vec3(
        (Scene_SDF(vec3(point.x + Epsilon, point.y, point.z), hit, 0.0) - Scene_SDF(vec3(point.x - Epsilon, point.y, point.z), hit, 0.0)),
        (Scene_SDF(vec3(point.x, point.y + Epsilon, point.z), hit, 0.0) - Scene_SDF(vec3(point.x, point.y - Epsilon, point.z), hit, 0.0)),
        (Scene_SDF(vec3(point.x, point.y, point.z + Epsilon), hit, 0.0) - Scene_SDF(vec3(point.x, point.y, point.z - Epsilon), hit, 0.0))));
}

//------------------------------------------------------------------------------------------
// Light Structures and Functions
//------------------------------------------------------------------------------------------

struct LightDirectional
{
    vec3 color;
    vec3 direction;  
};
    
struct LightPoint
{
      vec3 color;
    vec3 position;
    vec3 attenuation;
};

/**
 * Calculates the shadow factor on range [0.0, 1.0] for the given surface and light point.
 *
 * To determine if our light source is being occluded by scene geometry, we simply march
 * through the scene as we would for calculating the geometry SDF values.
 *
 * The only difference is that instead of using a ray originating from our camera, we
 * instead use a ray being projected from the light source.
 *
 * If our Scene_SDF returns a hit, then we know the light projecting from the point
 * onto the surface is occluded and in shadow.
 *
 * \param[in] surfPos     Surface position to calculate the shadow factor for.
 * \param[in] lightOrigin Origin of the light source.
 *
 * \return Shadow factor value on range [0.0, 1.0]
 */
float CalculateShadow(vec3 surfPos, vec3 lightOrigin)
{
    RayHit hit;
    
    float result   = 1.0;
    vec3  lightRay = normalize(surfPos - lightOrigin);
    
    for(float depth = NearClip; depth < FarClip - Epsilon; )
    {
        vec3  point = (lightOrigin + (lightRay * depth));
        float sdf   = Scene_SDF(point, hit, 1.0);
        
        if(sdf < Epsilon)
        {
            return 0.0;
        }
        
        // http://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
        result = min(result, (SoftShadowFactor * sdf) / depth);
        
        depth += sdf;
    }
    
    return result;
}

vec3 CalculatePhongBRDF(
    vec3  surfNorm, 
    vec3  toLight, 
    vec3  toView, 
    vec3  diffColor,
    vec3  specColor,
    float roughness)
{
    vec3  diffuse   = diffColor * PiUnderOne;
    float halfAngle = dot(normalize(-toLight + toView), surfNorm);
    float schlick   = (halfAngle / (roughness - (roughness * halfAngle) + halfAngle));
    vec3  specular  = ((roughness + 2.0) * PiTwoUnderOne) * specColor * schlick;

    return (diffuse + specular);
}

vec3 CalculateDynamicLight(
    vec3  surfPos,
    vec3  surfNorm,
    vec3  toView,
    vec3  lightDir,
    vec3  lightColor,
    vec3  diffColor,
    vec3  specColor,
    float roughness)
{
    vec3  origin   = surfPos + (lightDir * (FarClip + SoftShadowOffset));
    float shadow   = CalculateShadow(surfPos, origin);
    vec3  brdf     = CalculatePhongBRDF(surfNorm, -lightDir, toView, diffColor, specColor, roughness);
    float cosAngle = clamp(dot(surfNorm, lightDir), 0.0, 1.0);
    
    return (lightColor * brdf * shadow * cosAngle);
}

/**
 * Calculates total lighting (including shadows) for the given surface.
 */
vec3 CalculateLighting(
    vec3 surfPos, 
    vec3 surfNorm, 
    vec3 toView,
    vec3 diffColor,
    vec3 specColor, 
    float roughness)
{
    vec3 dynamicLighting = vec3(0.0, 0.0, 0.0);
    
    LightDirectional light;
    
    light.color     = vec3(0.85, 0.85, 0.8);
    light.direction = normalize(vec3(1.0, 1.0, -0.8));
    
    dynamicLighting += CalculateDynamicLight(surfPos, surfNorm, toView, light.direction, light.color, diffColor, specColor, roughness);

    return (AmbientLight + dynamicLighting * 1.25);
}

//------------------------------------------------------------------------------------------
// Material Structures and Functions
//------------------------------------------------------------------------------------------

/**
 * Applies the base doughnut material.
 * The base material consists of:
 *
 *     * Base color
 *     * Middle lighter ring due to frying
 *     * Noise for texture
 */
vec3 Material_DoughnutBase(vec3 surfNorm)
{
    // Base doughnut color
    vec3 color = vec3(0.9637, 0.6853, 0.2904);
    
    // Color of the lighter ring due to frying on each side
    vec3 centerColor = color + vec3(0.03, 0.10, 0.10);
    
    // Calculate the relative surface y-angle. We clamp to [-0.25, 0.25] where the value is cos(angle)
    float angle = max(min(dot(surfNorm, vec3(0.0, 1.0, 0.0)), 0.25), -0.25);
    
    // Interpolate to the center ring color
    color  = mix(centerColor, color, abs(angle * 4.0));
   // color += vec3(0.025, 0.025, 0.025) * NoiseXorShift32();
    
    return color;
}

vec3 Material_Powdered(vec3 surfPos, vec3 base)
{
    Seed(surfPos.xz);
    
    float powderChance = step(0.0, NoiseXorShift32() + 0.85);
    vec3  powderColor  = vec3(1.0 - (NoiseXorShift32() + 1.0) * 0.01) * powderChance;
    
    return max(base, powderColor);
}

vec3 Material_Jelly(vec3 surfPos, vec3 surfNorm, vec3 base)
{
    Seed(surfPos.xz); 
    
    float angle = dot(vec2(0.0, surfNorm.y), vec2(0.0, 1.0)) * 1.75 - 0.75;
    
    float powderChance = step(0.0, NoiseXorShift32() + angle);
    vec3  powderColor  = vec3(1.0 - (NoiseXorShift32() + 1.0) * 0.01) * powderChance;
    
    return max(base, powderColor);
}

vec3 Material_Frosted(vec3 surfNorm, vec3 base, vec3 color, float crests, inout float r)
{
    /** 
     * Here we calculate the surfNorm.y angle that the frosting begins at.
     *
     * We have a baseline angle of 0.3 (remember this is angle=acos(dot(surfNorm, vec3(0,1,0))).
     * Then we modulate up and down (via cos) 8 times around the doughnut and 
     * the angle varies between 0.2 and 0.4.
     *
     *     (a) Convert surfNorm.xz to an angle where ( 1.0,  0.0) -> 0, 2pi       (think graph with axis X/Z)
     *                                               ( 0.0,  1.0) -> pi/2
     *                                               (-1.0,  0.0) -> pi
     *                                               ( 0.0, -1.0) -> 3pi/2
     *     (b) Modulate 8 times over the full circle
     *     (c) Vary angle (surfNorm.y) by +/- 0.1
     *
     *     angle = 0.30 - cos((a) * (b)) * (c)
     */
    
    float angle = 0.30 - cos(acos(dot(normalize(surfNorm.xz), vec2(1.0, 0.0))) * crests) * 0.1;
    float iced  = step(angle, dot(surfNorm, vec3(0.0, 1.0, 0.0)));
    
    r = 4.0 * iced;
    
    return StepValue(iced, Epsilon, color, base);
}

vec3 Material_Stripes(vec3 surfPos, vec3 surfNorm, vec3 base, vec3 color, inout float r)
{
    float iced    = step(1.0, r);
    float striped = step(0.65, cos(surfPos.z * 6.0) * iced);  // 0.65 = stripe thickness; 6.0 = stripe count
    
    return StepValue(striped, 0.65, color, base);
}

vec3 Material_Glazed(vec3 base, inout float r)
{
    r = 0.0;
    return base;
}

vec3 Material_BoxInterior()
{
    return vec3(0.9, 0.9, 0.9);
}

vec3 Material_BoxExterior()
{
    return vec3(1.0, 0.84, 0.94);
}

vec3 Material_Apply(in RayHit hit, vec3 toView)
{
    vec3 color = SprinkleColors[int(clamp(hit.material - 8.0, 0.0, 2.0))];
    float r = -2.0;
    
    if(hit.material < Epsilon)      // Powdered 
    {
        color = Material_Powdered(hit.surfPos, Material_DoughnutBase(hit.surfNorm));
    }
    else if(hit.material < 1.1) // Chocolate Frosted w/ White Stripes
    {
        color = Material_Frosted(hit.surfNorm, Material_DoughnutBase(hit.surfNorm), ChocolateColor, 8.0, r);
        color = Material_Stripes(hit.surfPos, hit.surfNorm, color, vec3(0.985, 0.877, 0.755), r);
    }
    else if(hit.material < 2.1) // ?
    {
        color = Material_DoughnutBase(hit.surfNorm);
        color = Material_Frosted(hit.surfNorm, color, ChocolateColor, 4.0, r);
    }
    else if(hit.material < 3.1) // Jelly
    {
        color = Material_DoughnutBase(hit.surfNorm);
        color = Material_Jelly(hit.surfPos, hit.surfNorm, color);
    }
    else if(hit.material < 4.1) // Pink Frosted w/ Sprinkles
    {
        color = Material_Frosted(hit.surfNorm, Material_DoughnutBase(hit.surfNorm), PinkColor, 10.0, r);
    }
    else if(hit.material < 5.1) // Glazed
    {
        color = Material_Glazed(Material_DoughnutBase(hit.surfNorm), r);
    }
    else if(hit.material < 6.1) // Box Exterior
    {
        color = Material_BoxExterior();
    } 
    else if(hit.material < 7.1) // Box Interor
    {
        color = Material_BoxInterior();
    }
    
    vec3 lighting = CalculateLighting(hit.surfPos, hit.surfNorm, toView, color, vec3(1.0), r);
    
    return lighting * color;
}

//------------------------------------------------------------------------------------------
// Raymarching
//------------------------------------------------------------------------------------------

/**
 * Basic Raymarching using SDF objects.
 *
 * For each raymarch step we:
 *
 *     - Find distance to nearest object along the ray
 *         - If distance <= 0, we are on or inside the object
 *         - If distance > 0, we are outside the object and must continue
 *           along the ray for a length of distance to find the next closest object.
 */
RayHit RaymarchScene(in Ray ray)
{
    RayHit hit;
    
    hit.hit      = false;
    hit.material = 0.0;
    
    float sdf = FarClip;
    
    for(float depth = NearClip; depth < FarClip; )
    {
        vec3 pos = ray.origin + (ray.direction * depth);
        
        sdf = Scene_SDF(pos, hit, 0.0);
        
        if(sdf < Epsilon)
        {
            hit.hit      = true;
            hit.surfPos  = pos;
            hit.surfNorm = Scene_Normal(pos);
            
            return hit;
        }
        
        // Continue along the ray to look for the next nearest object
        depth += sdf;
    }
    
    return hit;
}

vec3 Render(vec2 gl_FragCoord, Camera camera)
{
    vec3 final = vec3(0.3, 0.3, 0.3);
    vec2 uv = (gl_FragCoord.xy / resolution.xy);
    
    Seed(uv);
    
    Ray    ray = Camera_GetRay(camera, uv);
    RayHit hit = RaymarchScene(ray);
    
    if(hit.hit)
    {
        final.rgb = Material_Apply(hit, normalize(camera.origin - hit.surfPos));
    }
    
    return final;
}

//------------------------------------------------------------------------------------------
// Main
//------------------------------------------------------------------------------------------

const vec2 SampleCoords[4] = vec2[](
    vec2(0.0, 0.5),
    vec2(0.5, 0.0),
    vec2(0.0, -0.5),
    vec2(-0.5, 0.0));

void main(void)
{
    BoxOrigin = mix(vec3(0.0), vec3(0.0, 0.0, 70.0), clamp((mod(time, TimeLimit) - 6.0) * 0.75, 0.0, 1.0));
    
    // Angled
    vec3 camPos = vec3(40.0, 35.0, 30.0);
    Camera camera = Camera_LookAt(camPos, vec3(0.0, 0.0, 6.0));
    
    // Looking down
    //vec3 camPos = vec3(0.0, 35.0, 5.9);
    //Camera camera = Camera_LookAt(camPos, vec3(0.0, 0.0, 6.0));
    
    glFragColor.rgb = Render(gl_FragCoord.xy, camera);
    
    for(uint i = 0u; i < MultiSamples; ++i)
    {
        glFragColor.rgb += Render(gl_FragCoord.xy + SampleCoords[i], camera);
    }
    
    glFragColor.rgb /= (float(MultiSamples) + 1.0);
}
