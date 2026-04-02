#version 420

// original https://www.shadertoy.com/view/WtfcW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Procedural render of "Remember" by Becca Tindol
// Original - https://www.instagram.com/p/CHb3Su8HF6g/
// Check out her other art! https://linktr.ee/alteredmoonart
// Created by Anthony Hall, December 2020

// Supersample more toward the center to reduce aliasing
const bool dynamicSupersample = true;

// The number of extra samples on each axis to take (offsetting the default values)
const int extraSamples = 0;

// Render a border between layers
// Disabling this makes the result more accurate to the original artwork
const bool renderBorder = true;

// Frequency of layer zoom, glow oscillation, DNA rotation, and sky movement
const float zoomFrequency = 0.6667;
const float glowFrequency = 0.5 * zoomFrequency;
const float twistFrequency = -0.75 * zoomFrequency;
const float skyFrequency = 5. * zoomFrequency;

// Raymarching constants
const float maxDistance = 50.0;
const float baseEpsilon = 0.003;
float epsilon; // set in sampleScene - increases with deeper layers

// Other globals
const vec3 cameraPos = vec3(0., 0., 37.5);
const float fov = radians(50.0);
vec3 lightPos = vec3(16.0, 3.0, 20.0);

// Colors taken directly from the source
const vec3 glowColor = vec3(6, 202, 227) / 255.0;
const vec3 purple = vec3(125, 39, 239) / 255.0;
const vec3 blue = vec3(69 /* nice */, 46, 250) / 255.0;

// 2D rotation in radians
mat2 getRotationMatrix(float angle) {
    return mat2(
        cos(angle), sin(angle),
        -sin(angle), cos(angle));
}

// Folds point across a line through origin with specified normal
vec2 fold(vec2 point, vec2 normal)
{
    float dist = min(dot(point, normal), 0.0);
    return point - 2. * dist * normal;
}

float sdCircle(vec2 point, vec2 center, float radius) {
    return distance(point, center) - radius;
}

// Distance to a segment of specified length on the x-axis
float sdSegmentX(vec3 point, vec3 center, float len)
{
    float r = len/2.0;
    point = abs(point - center);
    return length(max(point - vec3(r, 0., 0.), 0.0));
}

const float helixRadius = 0.19;
const float helixSpacing = 2.;
const float ladderRadius = 0.1;
const float ladderSpacing = 0.67;
const float angleScale = 0.9;
const float angleDistort = 1.0; // 1.0 for perfect helix

// Infinite DNA traversing Y axis
float sdDna(vec3 point, vec2 center, float time) {
    // Spiral about the Y axis
    point.xz -= center * angleDistort;
    point.xz = getRotationMatrix(-point.y * angleScale + time) * point.xz;
    point.xz += center * angleDistort;
    
    float leftHelix = sdCircle(point.xz, center + vec2(-helixSpacing/2.0, 0.0), helixRadius);
    float rightHelix = sdCircle(point.xz, center + vec2(helixSpacing/2.0, 0.0), helixRadius);
    float helix = min(leftHelix, rightHelix);
    
    // Repeat ladder along z axis
    point.y -= ladderSpacing/2.0;
    point.y = mod(point.y, ladderSpacing);
    point.y += ladderSpacing/2.0;
    float ladder = sdSegmentX(point, vec3(center.x, 0.5, center.y), helixSpacing) - ladderRadius;
    
    // iq's smooth minimum
    float k = .175;
    float h = max(k - abs(helix - ladder), 0.0) / k;
    return min(helix, ladder) - h*h*h*k/6.0;
}

float dnaX = 15.0;
float borderX = 13.0;
float borderRadius = 0.25;

// Returns the distance to the scene
float scene(vec3 point)
{
    // Fold the space twice to create a square around the center
    point.xy = fold(point.xy, normalize(vec2(1., -1.)));
    point.xy = fold(point.xy, normalize(vec2(1., 1.)));
    
    float time = time * twistFrequency * radians(180.0);
    
    // Scale DNA distance down because the space distortions sometimes result in overstepping
    float dna = 0.75 * sdDna(point, vec2(dnaX, 0.), time);
    float dist = dna;
    
    if (renderBorder)
    {
        float border = sdCircle(point.xz, vec2(borderX, -0.), borderRadius);
        dist = min(dist, border);
    }
    return dist;
}

// Approximates the normal at an intersection by calculating the gradient of the map
vec3 estimateNormal(vec3 point) {
    return normalize(vec3(
        scene(vec3(point.x + epsilon, point.y, point.z)) - scene(vec3(point.x - epsilon, point.y, point.z)),
        scene(vec3(point.x, point.y + epsilon, point.z)) - scene(vec3(point.x, point.y - epsilon, point.z)),
        scene(vec3(point.x, point.y, point.z  + epsilon)) - scene(vec3(point.x, point.y, point.z - epsilon))));
}

// Gets rainbow color based on position around the border, slightly offset each level
vec3 getRainbow(vec3 point, float level)
{
    point = abs(point);
    float t = -min(point.x, point.y) / 15.0 + 0.2;
    t += 0.05 * level;
    
    // Pretty much a hue scalar -> rgb
    vec3 a = vec3(0, 1, 2) / 3.0;
    return 0.5 + 0.5 * clamp(2.0 * cos(radians(360.0) * (t + a)), -1.0, 1.0);
}

// Shades a surface at the given point
vec3 shadeSurface(vec3 point, vec3 rayDir, float level)
{
    vec3 normal = estimateNormal(point);
    vec3 surfaceColor;
    
    // Set the surface color based on whether this is the DNA or the border
    float region = max(abs(point.x), abs(point.y));
    if (region > borderX + borderRadius + epsilon)
    {
        surfaceColor = getRainbow(point, level);
    }
    else
    {
        surfaceColor = purple;
        //surfaceColor = vec3(0.9); // The lighting effects are more apparent with a silver border
        
        // Add rainbow colored highlighting around the edges
        vec3 toEye = -rayDir; 
        float intensity = 1.0 - dot(normal, toEye);
        surfaceColor = mix(surfaceColor, getRainbow(point, level), intensity);
    }
    // Smoothstepped diffuse lighting
    vec3 toLight = normalize(lightPos - point);
    float diffuse = max(dot(normal, toLight), 0.0);
    diffuse = smoothstep(0.6, 0.85, diffuse);
    
    // Add some ambient lighting and return
    diffuse = mix(diffuse, 1.0, 0.4);
    return surfaceColor * diffuse;
}

// Calculates the sky as purple with a bit of cloud-like animation
vec3 getSky(vec3 rayOrigin, vec3 rayDir)
{
    // Calculate coordinates of intersection
    vec3 intersect = abs(rayDir * rayOrigin.z / rayDir.z);
    float x = max(intersect.x, intersect.y);
    float y = min(intersect.x, intersect.y);
    
    // Calculate the fade (colorMix) between the blue glow and purple sky
    // band - the band that runs along the axis of the DNA
    // ellipse - The more pronounced bulge near the center of each edge
    float band = smoothstep(0.6, 1.6, abs(x - dnaX));
    float ellipse = length(vec2((x - dnaX) * 0.7, y * 0.225)) - 1.5;
    float colorMix = min(band, ellipse);
    colorMix = clamp(colorMix, 0.0, 1.0);
    
    const vec3 baseColor = purple * 1.1;
    
    // Get the intensity of the purple sky component
    const float innerSkyStart = renderBorder? -3.0 : -4.0;
    const float innerSkyEnd = renderBorder? -0.5 : -1.25;
    float skyIntensity = smoothstep(innerSkyStart, innerSkyEnd, x - dnaX) * smoothstep(14.0, 0.5, x - dnaX);
    skyIntensity = pow(skyIntensity, 1.4);
    vec3 purpleSky = skyIntensity * baseColor;
    
    // Add some moving textures to the sky to animate it
    float textureScale = 1./90.;
    
    // Use pebble texture to get main "cloud" effect moving outward
    float time = time * skyFrequency;
    vec2 uv = vec2(min(intersect.x, intersect.y), x - time) * textureScale;
    uv.x -= 0.8;
    float coarse = 0.0;//texture(iChannel0, uv).r;
    coarse = mix(coarse, 1.0, 0.7);
    
    // Use another more fine texture with slower outward movement
    uv.y = (x - time * .4) * textureScale;
    uv *= 0.45;
    float fine = 0.0;//texture(iChannel1, uv).r;
    fine = mix(fine, 1.0, 0.875);
    
    float textureIntensity = coarse * fine;
     
    // Add the texture effects weakly to the blue and strongly to the purple
    return mix(blue * textureIntensity,
               purpleSky * textureIntensity * textureIntensity,
               colorMix);
}

// Returns the result color of casting a ray
vec3 castRay(vec3 rayOrigin, vec3 rayDir, float level)
{
    // Time intensity scalar from 0 - 1 of both iteration-based glow (on hit)
    // and distance-based glow (on miss)
    float glowOscillate = 0.5 + 0.5 * cos(time * glowFrequency * radians(360.0) + level * 0.25);
    
    vec3 color = getSky(rayOrigin, rayDir);
    
    vec3 point = rayOrigin;
    float t;
    int iters = 0;
    float minDist = 1e10;
    
    for (t = 0.; t < maxDistance; point = rayOrigin + t*rayDir)
    {
         float dist = scene(point);
        minDist = min(dist, minDist);
        
        if (dist <= epsilon)
        {
            color = shadeSurface(point, rayDir, level);
            
            // Add iteration-based glow
            // Only add glow on DNA, not on border
            if (max(abs(point.x), abs(point.y)) > borderX + borderRadius + epsilon)
            {
                float baseGlow = float(iters) / 50.0;
                float glowIntensity = 0.8 + 1.5 * glowOscillate;
                color += glowColor * glowIntensity * pow(baseGlow, 1.075);
            }
            return color;
        }
        t += dist;
        iters++;
    }
    // On miss, add distance-based glow
    float glowIntensity = 0.4 + 0.4 * glowOscillate;
    float baseGlow = exp2(-2.5 * minDist);
    color += glowColor * glowIntensity * pow(baseGlow, 1.4);
    
    return color;
}

// Variables/defaults used for calculating recursion
float borderPercentage;
float scalePerIteration = 441./367.;
float anglePerIteration = radians(7.84);

// Samples the scene at specified pixel coordinate
// Recurses to the proper layer and then calls castRay
vec3 sampleScene(vec2 FC)
{
    // Convert coords to [-1, 1] in minimum dimension
    float minDimension = min(resolution.x, resolution.y);
    vec2 coord = (2.0 * FC.xy - resolution.xy) / minDimension;
    
    // Fake infinite zoom
    float time = time * zoomFrequency;
    float zoom = fract(time);
    float startLevel = floor(time);
    coord /= pow(scalePerIteration, zoom);
    coord = getRotationMatrix(zoom * anglePerIteration) * coord;
    
    // logScale - when there is twisting between the levels, we can still determine
    // the most shallow level the point must be in by inscribing an upright square
    // into the rotated square
    float logScale;
    if (max(abs(coord.x), abs(coord.y)) >= borderPercentage)
    {
        logScale = scalePerIteration / (sin(abs(anglePerIteration)) + cos(abs(anglePerIteration))); 
    } else
    {
        logScale = scalePerIteration * (sin(abs(anglePerIteration)) + cos(abs(anglePerIteration)));
    }
    
    // Optimization - Advance to the point to the most shallow level it is guaranteed to be in
    vec2 logs = ceil(-log(abs(coord  / borderPercentage)) / log(logScale));
    float level = min(logs.x, logs.y);    
    coord *= pow(scalePerIteration, level);
    coord = getRotationMatrix(-level * anglePerIteration) * coord;
    
    // Finish advancing the point to its actual level
    for (int i = 0; i < 25; i++)
    {
        if (max(abs(coord.x), abs(coord.y)) < borderPercentage) {
            coord *= scalePerIteration;
            coord = getRotationMatrix(-anglePerIteration) * coord;
            level += 1.0;
            continue;
        }
        break;
    }
    // Reduce aliasing slightly by reducing LOD in deep levels
    epsilon = baseEpsilon * pow(scalePerIteration, level * 0.9);
    
    // Cast the recalculated ray
    vec3 rayDir = normalize(vec3(coord * tan(fov/2.0), -1.0));
    return castRay(cameraPos, rayDir, startLevel + level);
}

void main(void)
{
    // Calculate border size, scale/angle per iteration
    
    // borderPercentage - the percentage of the scene where the ray is tangent to
    // the inside of the border cylinder (i.e. when to recurse to the next level)
    float r = borderRadius + baseEpsilon;
    float c = length(vec2(cameraPos.z, borderX));
    float theta1 = atan(borderX / cameraPos.z);
    float theta2 = asin(r / c);
    borderPercentage = tan(theta1 - theta2) / tan(fov/2.) + 0.0005; // Add a bit to compensate for slight error
    
    // Overwrite angle/scale defaults by mouse x/y respectively if clicked
    //if (mouse*resolution.xy.z > 0.0)
    //{
        vec2 mouse = min(mouse*resolution.xy.xy, resolution.xy); // So changing resolution doesn't cause unwanted values
        anglePerIteration = -0.15 * (2.0 * mouse.x - resolution.x) / resolution.x;
        scalePerIteration = mix(1.18, 1.5, mouse.y / resolution.y);
    //}

    // Supersample more toward the center
    float minDimension = min(resolution.x, resolution.y);
    vec2 coord = abs((2.0 * gl_FragCoord.xy - resolution.xy) / minDimension);
    float region = max(coord.x, coord.y);
    int samples;
    
    if (dynamicSupersample)
    {
        if (region < 0.15)
            samples = 3 + extraSamples;
        else if (region < 0.45)
            samples = 2 + extraSamples;
        else
            samples = 1 + extraSamples;
    }
    else {
        samples = 1 + extraSamples;
    }

    float increment = 1.0 / float(samples);
    float offset = increment / 2.0 - 0.5;

    // Supersample by accumulating color of all samples
    vec3 color = vec3(0.0);
    
    for(int j = 0; j < samples; j++) {
        for(int i = 0; i < samples; i++)
        {
            vec2 screenCoord = gl_FragCoord.xy + offset + increment * vec2(i, j);
            color += sampleScene(screenCoord);
        }
    }
    
    color /= float(samples * samples);
    glFragColor = vec4(color, 1.0);
}
