#version 420

// original https://www.shadertoy.com/view/WdcfWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Ray marching parameters
const int MAX_MARCHING_STEPS = 256;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.001; // closest you get to the surface
const bool USE_ORBIT = true;

/*
TODO Test values for BAILOUT
TODO Get shadows and better colors
TODO Movement of camera
TODO Camera zoom
TODO Colors and  shadows (orbit coloring)
TODO cync it to music, music with a beat, and the mandelbulb shrinks / grows with beat (or just the view)
TODO other shapes
*/
const float BAILOUT = 16.0; // Distance at which mandelbulb will diverge
const int MAX_ITER = 100; // for generating the mandelbulb
const float BULB_DEGREE = 8.0; // this is the typical one used
const float PI = 3.1415926535;

struct paletteConfig {
    vec3 a;
    vec3 b;
    vec3 c;
    vec3 d;
};

// cosine based palette, 4 vec3 params
// https://iquilezles.org/www/articles/palettes/palettes.htm
vec3 palette(float t, paletteConfig p) {
    return p.a + p.b*cos(6.28318*(p.c*t+p.d) );
}

// Constructive Solid Geometry (CSG) operations
float intersectSDF(float distA, float distB) {
    return max(distA, distB);
}

float unionSDF(float distA, float distB) {
    return min(distA, distB);
}

float differenceSDF(float distA, float distB) {
    return max(distA, -distB);
}

// SDF (sign distance function) for a sphere centered at the origin
float sphereSDF(vec3 p, float radius) {
    return length(p) - radius;
}

// estimates distance to mandelbulb
vec2 mandelbulbDF(vec3 pos) {
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;

    // Used to color fractal
    // Tracks the minimum distance from orbitCenter (arbitrary point)
    float minOrbitDist = 256.0;
    int orbit = 0;

    for (int i = 0; i < MAX_ITER ; i++) {
        r = length(z);
        orbit = i;

        // r is diverging
        if (r>BAILOUT) break;

        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);

        // Next term in Mandelbrot iteration
        dr = pow(r, BULB_DEGREE-1.0)*BULB_DEGREE*dr + 1.0;

        // scale and rotate the point
        float zr = pow(r, BULB_DEGREE);
        theta = theta*BULB_DEGREE;
        phi = phi*BULB_DEGREE;

        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z += pos;
    }
    // x: distance
    // y: orbit (used for color)
    return vec2(0.5*log(r)*r/dr, orbit);
}

// distance function (0 inside +ive outside)
//float sphereSDF(vec3 p,)

// Absolute of the return value is distance to surface
// Sign indicates if point is inside (-) or outside (+) surface
vec2 sceneSDF(vec3 p) {
    //float sA = sphereSDF((p)-vec3(-3,0,0) / 1.2, 1.0) * 1.2;
    //float sB = sphereSDF((p)-vec3(3,0,0) / 1.2, 1.0) * 1.2;
    //return unionSDF(sA, sB);
    return mandelbulbDF(p);
}

// Return shortest distance from the eye to the scene surface along ray
vec2 shortestDistanceToSurface(vec3 eye, vec3 marchingDirection,
                                float initialDepth, float maxDepth) {
    float depth = initialDepth;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        // dist is distance from surface
        // Negative dist indicates surface intersection
        vec2 dist = sceneSDF(eye + depth * marchingDirection);
        if (dist.x < EPSILON) {
            return vec2(depth, dist.y);
        }
        depth += dist.x;
        if (depth >= maxDepth) {
            return vec2(maxDepth, 0);
        }
    }
    return vec2(maxDepth, 0);
}

// Return normalized direction to march in from the
// eye point for a single pixel
vec3 getRayDirection(float fov, vec2 resolution) {
    // Move origin from bottom left to center of screen
    vec2 xy = gl_FragCoord.xy - resolution / 2.0;

    // Get the z-distance from pixel given resolution
    // and vertical FoV (field of view)
    // Diagram shows that:
    // tan(radians(fov)/2) == (resolution.y * 0.5) / z
    // Diagram: https://stackoverflow.com/a/10018680
    // Isolating for z gives
    float z = (resolution.y * 0.5) / tan(radians(fov) / 2.0);
    return normalize(vec3(xy, -z));
}

// eye: looking from
// center: looking at
mat4 getLookAtMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye); // f is the direction you are looking
    vec3 s = normalize(cross(f, up)); // s is to the right, if up is (kindof) the direction that's up
    vec3 u = cross(s, f); // u is the 'real' up

    return mat4(vec4(s, 0),
                vec4(u, 0),
                vec4(-f, 0),
                vec4(0, 0, 0, 1)); // 'fourth componant is just used for perspective divide'
}

vec3 getNormal(vec3 p) {
    // compute the gradient
    float eps = EPSILON*0.1;
    vec3 px = p + vec3(eps,0,0);
    vec3 py = p + vec3(0,eps,0);
    vec3 pz = p + vec3(0,0,eps);
    float f = sceneSDF(p).x;
    float fx = sceneSDF(px).x;
    float fy = sceneSDF(py).x;
    float fz = sceneSDF(pz).x;
    vec3 normal = normalize(vec3((fx - f)/eps , (fy - f)/eps , (fz - f)/eps));
    return normal;
}

vec3 addLighting(vec3 p, vec3 color) {
    vec3 lightSource = vec3(0,0,5); //
    vec3 lightDir = normalize(lightSource-p);
    vec3 normal = getNormal(p);
    float dotp = max(0.1,dot(lightDir, normal));
    vec3 newColor = color * dotp;

    return newColor;
}

void main(void) {
    vec2 resolution = resolution.xy;

    // Define position of observer
    // spherical coordinates
    float r = 4.0-abs(sin(time*0.1)*3.0);
    float theta = sin(0.2*time)*0.08*PI; // from 0 to PI
    float phi = time*0.06*PI; // from 0 to 2 PI
    vec3 eye = vec3(r*sin(theta)*cos(phi), r*sin(theta)*sin(phi), r*cos(theta));

    // Shoot a ray from the eye through each pixel
    // Get the direction of that ray
    vec3 viewDir = getRayDirection(45.0, resolution);

    // Transform from view to world space
    // TODO Review this
    mat4 viewToWorld = getLookAtMatrix(eye, vec3(0), vec3(0, 1, 0));
    vec3 worldDir    = (viewToWorld * vec4(viewDir, 0.0)).xyz;

    // Return shortest distance from the eye to the scene surface along ray
    vec2 dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);

    // Didn't hit anything
    if (dist.x > MAX_DIST) {
        glFragColor = vec4(0);
        return;
    }

    // Point of intersection of view ray with surface
    vec3 p = eye + dist.x * worldDir;

    // Procedural color palette parameters
    paletteConfig pc;
    pc.a = vec3(0.5, 0.5, 0.5);
    pc.b = vec3(0.5, 0.5, 0.5);
    pc.c = vec3(2.0, 1.0, 0.0);
    pc.d = vec3(0.50, 0.20, 0.25);

    vec3 outColor = palette(dist.y*0.1, pc);
    if (dist.x < 16.0) {
        outColor = addLighting(p, outColor);
    }

    if (dist.x >= BAILOUT) {
        outColor = vec3(0.0);
    }
    //outColor = vec3(dist.y*0.1);

    glFragColor = vec4(outColor, 1);
}
