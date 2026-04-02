#version 420

// original https://www.shadertoy.com/view/7lyGRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Infinite zoom of a snowflake-esque fractal constructed from tetrahedrons. The self-
// similarity is exploited to appear as an infinite zoom despite never zooming beyond
// two iterations.
// Created by Anthony Hall

const float pi = radians(180.0);
const float twoPi = radians(360.0);
const vec3 rgbWavelengths = vec3(0.612, 0.549, 0.464) / pi;

const float maxDistance = 40.0;
const float epsilon = 0.003;

vec3 cameraPos = vec3(0.0, 0.0, 4.0);
vec3 cameraDest = vec3(0.0);
const float fov = radians(50.0);

// The base number of iterations at no zoom, and the amount each iteration scales
// the size down. The bound lobes in the SDF were crafted for these values, so raising
// baseLevels or lowering levelScale will cause glitches. See scene for details/fixes
float baseLevels = 7.0;
const float levelScale = 2.0;

const float zoomPeriod = 4.0; // Time to zoom through one level
float zoomTotal; // Number of levels it looks like we have zoomed
float zoomBase; // Percentage of the first level we have zoomed
float zoomRepeat; // Percentage of the second level we have zoomed
float zoom; // Number of levels we have actually zoomed (zoomBase + zoomRepeat)

// Transforms the point evaluating the SDF (only rotation/scale)
mat3 sceneTransform = mat3(1.0);

// The amount the scene is zoomed in
float sceneScale;

// Translation component of the SDF point transformation. It's separate because
// mat3 * vec3 + vec3 is slightly cheaper than mat4 * vec4 (please correct me if wrong)
vec3 sceneOffset;

float linestep(float a, float b, float x)
{
    return clamp((x - a) / (b - a), 0.0, 1.0);
}

mat2 rotate(float theta)
{
    vec2 cs = vec2(cos(theta), sin(theta));
    return mat2(
        cs.x, cs.y,
        -cs.y, cs.x);
}

// Tetrahedron's vertices
const vec3[4] vertices = vec3[4](
    vec3(1, 1, 1),
    vec3(-1, 1, -1),
    vec3(-1, -1, 1),
    vec3(1, -1, -1));

// Tetrahedron bound SDF by yx
// https://www.shadertoy.com/view/Ws23zt
float sdTetrahedron(vec3 p)
{
    return (max(
        abs(p.x+p.y)-p.z,
        abs(p.x-p.y)+p.z
    )-1.)/sqrt(3.);
}

// Arbitrarily oriented flat disk
float sdDisk(vec3 point, vec3 normal, float radius)
{
    float dist = dot(point, normal);
    vec3 planePoint = point - dist * normal;
    float l = length(planePoint);
    float r = min(l, radius);
    planePoint = planePoint / l * r;
    return distance(point, planePoint);
}

// Folds space about a plane, and scales only the mirrored side without branching.
// scale returns how much the space was scaled
vec3 scaleFold(vec3 point, vec3 planePoint, vec3 normal, out float scale)
{
    float planeDist = dot(point - planePoint, normal);
    float reflected = float(planeDist < 0.0);
    scale = 1.0 - reflected + levelScale * reflected;
  
    // min(0.0, planeDist) seems to be slightly faster than reflected * planeDist
    point -= 2.0 * min(0.0, planeDist) * normal;
    point -= planePoint;
    point *= scale;
    point += planePoint;
    return point;
}

// Distance to the scene
float scene(vec3 point)
{
    point = sceneTransform * point + sceneOffset;
    float dist = 1e10;
    float scaleAcc = 1.0;
    float levels = baseLevels + zoom;

    for (float i = 0.0; i < ceil(levels); i += 1.0)
    {
        // The magic here is that each vertex of the tetrahedrons has an even number
        // of negative signs. This means we can easily transform the vertex octants to
        // the [+, +, +] octant and leave the others alone.
        
        float signs = (sign(point.x) * sign(point.y) * sign(point.z));
        point = mix(point, abs(point), 0.5 + 0.5 * signs);
        
        float scale;
        point = scaleFold(point, vertices[0], -vertices[0] / sqrt(3.0), scale);
        scaleAcc *= scale;

        // When the level is fractional, blend the last and second to last distances
        if (levels - i < 1.0)
        {
            float newDist = min(dist, sdTetrahedron(point) / scaleAcc);
            dist = mix(dist, newDist, levels - i);
        }
        // Take the initial distance when we are at the final whole level
        else if (levels - i < 2.0)
            dist = min(dist, sdTetrahedron(point) / scaleAcc); // TODO
    }
    // The SDF is now super messed up because the transformations above are not uniformly
    // applied to space. A point may not know it is near something because it's in a "less"
    // transformed region of space. To fix this, we will add lobe bounds that fully cover
    // the regions that may be overestimated. 
    
    // Slight optimization: by mapping every non-vertex octant to the [-, +, +] octant,
    // we only need to check the neighboring three lobes instead of all four. This also
    // maps all vertex octants to [+, +, +], so they're covered by the first lobe check.
    
    // It's not perfect, there are still viewing conditions in which glitching can occur
    // and I'm stumped
    
    float signs = sign(point.x) * sign(point.y) * sign(point.z);
    point = mix(vec3(-abs(point.x), abs(point.yz)), abs(point), 0.5 + 0.5 * signs);
    float boundDist = 1e10;
    
    for (int i = 0; i < 3; i++)
    {
        boundDist = min(boundDist, sdDisk(point - (1.205 + 1.0 / levelScale) * vertices[i],
            vertices[i] / sqrt(3.0), 1.3));
    }
    // Lower the epsilon multiplier to raise baseLevels over 7
    // Raise the disk size (0.95) to lower levelScale below 2
    dist = min(dist, abs((boundDist - 0.95) / scaleAcc) + 3.0 * epsilon);
    return dist * sceneScale;
}

vec3 estimateNormal(vec3 point, float distAtIntersect)
{
    const vec2 k = vec2(0.0, epsilon);
    return normalize(vec3(
        scene(point + k.yxx),
        scene(point + k.xyx),
        scene(point + k.xxy)) - distAtIntersect);
}

// Rather than use the depth and refractive index ratio, "incident distance"
// is used to save a couple operations. I define it as double the depth of the film
// multiplied by the speed of light outside the film over the speed of light inside
// the film. Think of it as the distance the light wave travels when hitting the
// film straight on,  accounting for the fact that the wavelength changes while
// inside the different medium.

vec3 filmInterference(vec3 incident, vec3 normal, float incidentDist)
{
    // Extra distance traveled by the light that goes through the film
    float dist = incidentDist / dot(-incident, normal);
    return abs(cos(dist / rgbWavelengths));
}

// Rainbow sky
vec3 sky(vec3 normal)
{
    float y = 2.0 * asin(normal.y) / pi; // Phi normalized to [-1, 1] 
    float phase = 1.3 * (y + 1.0) - 0.01;
    vec3 color = 0.5 + 0.5 * cos(phase / rgbWavelengths);
    
    // Wave-like function for changing brightness and color exponent
    float theta = atan(normal.z, normal.x);
    float intensity = cos(5.0 * theta - 0.7 * time)
        * cos(6.0 * theta)
        * cos(3.0 * theta + 0.82 * time);
        
    // Push values away from 0 a little
    intensity = sign(intensity) * pow(abs(intensity), 0.875);
    
    // Get rid of the weirdness at the poles
    intensity = mix(intensity, 0.4, linestep(0.5, 0.85, abs(y)));
    
    return (0.8 + 0.2 * intensity) * pow(color, vec3(pow(2.0, -2.0 * intensity)));
}

vec3 shadeSurface(vec3 point, vec3 normal, vec3 incident)
{
    // Make the surface white with a little bit of thin film interference from the
    // sky reflection. I chose the refractive index and "incident distance" arbitrarily
    // for aesthetic reasons. In order to accurately model the phenomenon, incident
    // distance must be caculated as 2 * depth * R_film / R_air (see filmInterference)
    
    vec3 skyColor = sky(reflect(incident, normal));
    vec3 filmRefraction = refract(incident, normal, 0.8);
    vec3 surface = 0.65 + 0.6 * skyColor * filmInterference(filmRefraction, normal, 2.5);
    
    // The lighting model is essentially a ring around the hemisphere that gets dark
    // very fast, with a ton of ambient light. This completely throws the sRGB color space
    // out the window, but the result has enough contrast without overwhelming brightness.
    float diffuse = dot(normal.xz, normal.xz); 
    diffuse = 0.5 + 0.5 * diffuse;
    return min(diffuse * surface, 1.0); // Surface color can exceed 1 so it needs clamping
}

vec3 castRay(vec3 rayOrigin, vec3 rayDir)
{
    vec3 color;
    vec3 point = rayOrigin;
    float t;
    bool hit = false;

    for (t = 0.0; t < maxDistance; point = rayOrigin + t*rayDir)
    {
        float dist = scene(point);
        if (dist <= epsilon)
        {
            vec3 normal = estimateNormal(point, dist);
            color = shadeSurface(point, normal, rayDir);
            hit = true;
            break;
        }
        t += dist;
    }
    if (!hit)
        // There's not quite enough contrast without darkening the sky a bit
        color = 0.75 * sky(rayDir);

    return color;
}

// Changes t [0, 1] to an exponential curve such that its derivative at 0 is levelScale
// times its derivative at 1. That is, its speed exponentially decreases
float expT(float t)
{
    return 1.0 - (pow(levelScale, 1.0 - t) - 1.0) / (levelScale - 1.0);
}

// Given 3 points that lie on an arc, this interpolates between two of them on the arc.
// previous -> start and start -> end must be equidistant on the arc for this to work.
vec3 arcInterp(vec3 previous, vec3 start, vec3 end, float t)
{
    vec3 toPrev = previous - start;
    vec3 toEnd = end - start;
    vec3 toCenter = normalize(toPrev + toEnd);
    float cDot = dot(toPrev, toCenter);
    float radius = dot(toPrev, toPrev) / (2.0 * cDot);
    vec3 center = start + radius * toCenter;

    // Correct t so that the angle change is constant
    float theta = 0.5 * (pi - 2.0 * acos(cDot / length(toPrev)));
    t = 2.0 * t - 1.0;
    t = tan(t * theta) / tan(theta);
    t = 0.5 + 0.5 * t;

    vec3 raw = mix(start, end, t);
    return center + radius * normalize(raw - center);
}

mat3 rotateRay(vec3 camera, vec3 dest, vec3 up)
{
    vec3 forward = normalize(dest - camera);
    vec3 right = normalize(cross(forward, up));
    up = cross(right, forward);
    return mat3(right, up, -forward);
}

void main(void)
{
    // First, there's a whole lot of globals calculation to do
	float time2;    

    float click = 0; //float(mouse*resolution.xy.z > 0.0);
    vec2 mouse = click * mouse*resolution.xy.xy / resolution.xy;
    mouse.y += 1.0 - click;
    
    baseLevels = max(baseLevels - (4.0 - 4.0 * mouse.y), 1.0); // Must be >= 1 for SDF to work
  
    if (time < 2.0)
        time2 = 0.25 * time * time;
    else
        time2 = time - 1.0;

    zoomTotal = time2 / zoomPeriod + 3.0 * mouse.x;
    zoomBase = min(zoomTotal, 1.0);
    zoomRepeat = fract(zoomTotal - zoomBase);
    zoom = zoomBase + zoomRepeat;
    sceneScale = pow(levelScale, zoom);

    // The rotation matrix from one level to the next is calculated from the perspective
    // of directly facing the center tetrahedron (kind of how the camera is at the
    // beginning). Thus, that rotation must be corrected for that orientation.
    // f, u, r = forward, up, right vectors
    
    const vec3 f0 = vertices[3] / sqrt(3.0);
    const vec3 u0Init = vec3(0, 1, 0);
    const vec3 r0 = normalize(cross(f0, u0Init));
    const vec3 u0 = cross(f0, -r0);
    const mat3 correction = transpose(mat3(r0, u0, -f0));

    // Now, rotate from one level to the next
    const vec3 mirrorNormal = vertices[0] / sqrt(3.0);
    const vec3 f1 = f0 - 2.0 * dot(f0, mirrorNormal) * mirrorNormal; // Mirrors f0
    const vec3 u1Init = vertices[0];
    const vec3 r1 = normalize(cross(f1, u1Init));
    const vec3 u1 = cross(f1, -r1);

    const mat3 fullRot = mat3(r1, u1, -f1) * correction;
    const mat3 invRot = transpose(fullRot);
    
    // Directly interpolating the rotation of each axis doesn't work well because 
    // the rotation takes a sharp turn at the border of each level. Considering the
    // original axes and the axes after the first and second rotations, these three
    // points will lie on an arc. When doing partial rotations, we want to figure out
    // where along this arc the new axis should lie. See arcInterp
    
    const vec3 prevU = invRot[1];
    const vec3 prevF = -invRot[2];

    const vec3 destU = fullRot[1];
    const vec3 destF = -fullRot[2];

    float zoomFract = fract(zoom);

    vec3 partialF = arcInterp(
        prevF,
        vec3(0, 0, -1),
        destF,
        zoomFract);

    vec3 partialU = arcInterp(
        prevU,
        vec3(0, 1, 0),
        destU,
        zoomFract);

    vec3 partialR = normalize(cross(partialF, partialU));
    partialU = cross(partialF, -partialR);
    mat3 partialRot = mat3(partialR, partialU, -partialF);

    // The idea for the offset is similar. The actual path of the offset should be a
    // logarithmic spiral centered at wherever the zoom is converging. I don't know how
    // to actually solve for the center of this logarithmic spiral, so we can utilize
    // the fact that logarithmic spirals are closely approximated by tangent arcs of
    // exponentially decreasing size. This approximation isn't perfect, hence you may
    // notice the figure wobble a bit especially when zooming quickly.
    
    const vec3 destOffset = vertices[0] * (1.0 + 1.0 / levelScale);
    const vec3 prevOffset = -invRot * destOffset;
    
    vec3 partialOffset = arcInterp(
        prevOffset,
        vec3(0),
        destOffset,
        expT(zoomFract));
    
    if (zoom < 1.0)
    {
        sceneTransform = partialRot;
        sceneOffset = partialOffset;
    }
    else
    {
        sceneTransform = partialRot * fullRot;
        sceneOffset = destOffset + fullRot * partialOffset / levelScale;
    }
    sceneTransform /= sceneScale;

    // Percentage that approaches 1 as time goes on
    float startExp = 1.0 - exp(-0.1 * time);

    // The camera is placed such that it's never looking toward the part that
    // disappears when the zoom repeats. It also avoids sky reflections that directly
    // face the poles.
    
    float xzTheta = -0.5 + 0.25 * cos(0.1 * time);
    cameraPos = (-6.0 + 1.5 * startExp) * vertices[3];
    cameraPos.xz = rotate(xzTheta) * cameraPos.xz;
    cameraPos.y -= 2.0 * startExp;
    
    // The camera approaches looking close to where the fractal path converges
    cameraDest = startExp * vec3(1.6, 1.6, 1.3);

    // Rotate the up vector around slowly
    vec3 up = vec3(sin(0.12 * time), cos(0.12 * time), 0.0);
    up = rotateRay(cameraPos, cameraDest, vec3(0, 1, 0)) * up;
    
    vec2 point = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 rayDir = normalize(vec3(point * tan(fov/2.0), -1.0));
    rayDir = rotateRay(cameraPos, cameraDest, up) * rayDir;
    
    glFragColor = vec4(castRay(cameraPos, rayDir), 1.0);
}
