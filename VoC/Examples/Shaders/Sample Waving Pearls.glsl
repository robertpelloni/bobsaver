#version 420

// original https://www.shadertoy.com/view/ltccRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//============================================================================
// Constants.
//============================================================================
const int NUM_LIGHTS = 1;
const int NUM_MATERIALS = 4;
const int NUM_PLANES = 6;
const int NUM_SPHERES = 7;
const int NUM_BOXES = 1;
const float PI = 3.1415926535;
const vec3 BACKGROUND_COLOR = vec3( 0.1, 0.2, 0.6 );

 // Vertical field-of-view angle of camera. In radians.
const float FOVY = 50.0 * 3.1415926535 / 180.0; 

// Use this for avoiding the "epsilon problem" or the shadow acne problem.
const float DEFAULT_TMIN = 10.0e-4;

// Use this for tmax for non-shadow ray intersection test.
const float DEFAULT_TMAX = 10.0e6;

// Equivalent to number of recursion levels (0 means ray-casting only).
// We are using iterations to replace recursions.
const int NUM_ITERATIONS = 3;

//============================================================================
// Define new struct types.
//============================================================================

struct Triangle_t {
    vec3 A,B,C;     // Barycentric Coordinates
    
    // Arbitrary point P in triangle
    // P = (1-beta-gamma)A + betaB + gammaC
};

struct Box_t {
    float xLen, yLen, zLen;     // Length, width and height
    vec3 center;                // Center coordinates in world space
    float xAngle, yAngle, zAngle;       // Rotation angles about 3 axes
    vec3 vertices[8];           // Pre-compute 8 vertices to reduce cost
    int materialID;
};

struct Ray_t {
    vec3 o;  // Ray Origin.
    vec3 d;  // Ray Direction. A unit vector.
};

struct Plane_t {
    // The plane equation is Ax + By + Cz + D = 0.
    float A, B, C, D;
    int materialID;
};

struct Sphere_t {
    vec3 center;
    float radius;
    int materialID;
};

struct Light_t {
    vec3 position;  // Point light 3D position.
    vec3 I_a;       // For Ambient.
    vec3 I_source;  // For Diffuse and Specular.
};

struct Material_t {
    vec3 k_a;   // Ambient coefficient.
    vec3 k_d;   // Diffuse coefficient.
    vec3 k_r;   // Reflected specular coefficient.
    vec3 k_rg;  // Global reflection coefficient.
    vec3 k_t;
    float n;    // The specular reflection exponent. Ranges from 0.0 to 128.0. 
    float m; 
};

//----------------------------------------------------------------------------
// The lighting model used here is similar to that on Slides 8 and 12 of 
// Lecture 11 (Ray Tracing). Here it is computed as
//
//     I_local = SUM_OVER_ALL_LIGHTS { 
//                   I_a * k_a + 
//                   k_shadow * I_source * [ k_d * (N.L) + k_r * (R.V)^n ]
//               }
// and
//     I = I_local  +  k_rg * I_reflected
//----------------------------------------------------------------------------

//============================================================================
// Global scene data.
//============================================================================
Plane_t Plane[NUM_PLANES];
Sphere_t Sphere[NUM_SPHERES];
Light_t Light[NUM_LIGHTS];
Material_t Material[NUM_MATERIALS];
Box_t Box[NUM_BOXES];

// In total, 12 vertex combinations of triangle
ivec3 TriIndices[12];

/////////////////////////////////////////////////////////////////////////////
// Initializes the scene.
/////////////////////////////////////////////////////////////////////////////
void InitBoxVertices(int i)
{
    Box[i].vertices[0] = vec3(-0.5*Box[i].xLen, -0.5*Box[i].yLen, -0.5*Box[i].zLen);
    Box[i].vertices[1] = vec3(0.5*Box[i].xLen, -0.5*Box[i].yLen, -0.5*Box[i].zLen);
    Box[i].vertices[2] = vec3(0.5*Box[i].xLen, 0.5*Box[i].yLen, -0.5*Box[i].zLen);
    Box[i].vertices[3] = vec3(-0.5*Box[i].xLen, 0.5*Box[i].yLen, -0.5*Box[i].zLen);
    Box[i].vertices[4] = vec3(-0.5*Box[i].xLen, -0.5*Box[i].yLen, 0.5*Box[i].zLen);
    Box[i].vertices[5] = vec3(0.5*Box[i].xLen, -0.5*Box[i].yLen, 0.5*Box[i].zLen);
    Box[i].vertices[6] = vec3(0.5*Box[i].xLen, 0.5*Box[i].yLen, 0.5*Box[i].zLen);
    Box[i].vertices[7] = vec3(-0.5*Box[i].xLen, 0.5*Box[i].yLen, 0.5*Box[i].zLen);  
}
void InitScene()
{

    TriIndices[0] = ivec3(1, 0, 2);
    TriIndices[1] = ivec3(0, 3, 2);
    TriIndices[2] = ivec3(4, 5, 7);
    TriIndices[3] = ivec3(5, 6, 7);
    TriIndices[4] = ivec3(0, 7, 3);
    TriIndices[5] = ivec3(0, 4, 7);
    TriIndices[6] = ivec3(1, 2, 6);
    TriIndices[7] = ivec3(1, 6, 5);
    TriIndices[8] = ivec3(0, 1, 4);
    TriIndices[9] = ivec3(1, 5, 4);
    TriIndices[10] = ivec3(2, 3, 7);
    TriIndices[11] = ivec3(2, 7, 6);

    // Horizontal plane.
    Plane[0].A = -1.0;
    Plane[0].B = 0.0;
    Plane[0].C = 0.0;
    Plane[0].D = 8.0;
    Plane[0].materialID = 0;

    // Vertical plane.
    Plane[1].A = 1.0;
    Plane[1].B = 0.0;
    Plane[1].C = 0.0;
    Plane[1].D = 8.0;
    Plane[1].materialID = 0;
    
    // Vertical plane.
    Plane[2].A = 0.0;
    Plane[2].B = 0.0;
    Plane[2].C = 1.0;
    Plane[2].D = 8.0;
    Plane[2].materialID = 0;
    
    // Vertical plane.
    Plane[3].A = 0.0;
    Plane[3].B = 1.0;
    Plane[3].C = 0.0;
    Plane[3].D = 0.0;
    Plane[3].materialID = 1;
    
    Plane[4].A = 0.0;
    Plane[4].B = -1.0;
    Plane[4].C = 0.0;
    Plane[4].D = 16.0;
    Plane[4].materialID = 0;
    
    Plane[5].A = 0.0;
    Plane[5].B = 0.0;
    Plane[5].C = -1.0;
    Plane[5].D = 8.0;
    Plane[5].materialID = 0;
    // Center bouncing sphere.
    Sphere[0].center = vec3( 0.0, sin(4.0 * (time - (3.0 * PI / 12.0))) + 5.0, 0.0 );
    Sphere[0].radius = 0.8;
    Sphere[0].materialID = 2;

    // Circling sphere.
    Sphere[1].center = vec3( 1.8, sin(4.0 * (time - (4.0 * PI / 12.0))) + 5.0, 0.0 );
    Sphere[1].radius = 0.5;
    Sphere[1].materialID = 3;

    Sphere[2].center = vec3( 3.2, sin(4.0 * (time - (5.0 * PI / 12.0))) + 5.0, 0.0 );
    Sphere[2].radius = 0.4;
    Sphere[2].materialID = 3;

    Sphere[3].center = vec3( 4.4, sin(4.0 * (time - (6.0 * PI / 12.0))) + 5.0, 0.0 );
    Sphere[3].radius = 0.3;
    Sphere[3].materialID = 3;

    Sphere[4].center = vec3( -1.8, sin(4.0 * (time - (2.0 * PI / 12.0))) + 5.0, 0.0 );
    Sphere[4].radius = 0.5;
    Sphere[4].materialID = 3;

    Sphere[5].center = vec3( -3.2, sin(4.0 * (time - (PI / 12.0))) + 5.0, 0.0 );
    Sphere[5].radius = 0.4;
    Sphere[5].materialID = 3;

    Sphere[6].center = vec3( -4.4, sin(4.0 * time) + 5.0, 0.0 );
    Sphere[6].radius = 0.3;
    Sphere[6].materialID = 3;

    // Wall material.
    Material[0].k_d = vec3( 0.59, 0.52, 0.3685 );
    Material[0].k_a = 0.2 * Material[0].k_d;
    Material[0].k_r = 1.0 * Material[0].k_d;
    Material[0].k_rg = 0.5 * Material[0].k_r;
    Material[0].k_t = 0.5 * Material[0].k_d;
    Material[0].n = 64.0;
    Material[0].m = 64.0;
    
    // Floor material.
    Material[1].k_d = vec3( 0.533, 0.484, 0.424 );
    Material[1].k_a = 0.2 * Material[1].k_d;
    Material[1].k_r = 2.0 * Material[1].k_d;
    Material[1].k_rg = 0.5 * Material[1].k_r;
    Material[1].k_t = 2.0 * Material[1].k_d;
    Material[1].n = 64.0;
    Material[1].m = 64.0;

    // Middle sphere material.
    Material[2].k_d = vec3( 0.5, 0.8, 0.9 );
    Material[2].k_a = 0.2 * Material[2].k_d;
    Material[2].k_r = 1.0 * Material[2].k_d;
    Material[2].k_rg = 0.5 * Material[2].k_r;
    Material[2].k_t = 2.0 * Material[2].k_d;
    Material[2].n = 64.0;
    Material[2].m = 128.0;

    // Little sphere material.
    Material[3].k_d = vec3( 0.6, 0.8, 0.6 );
    Material[3].k_a = 0.2 * Material[3].k_d;
    Material[3].k_r = vec3( 1.0, 1.0, 1.0 );
    Material[3].k_rg = 0.5 * Material[3].k_r;
    Material[3].k_t = 2.0 * Material[3].k_d;
    Material[3].n = 128.0;
    Material[3].m = 32.0;

    // Light 1.
    Light[0].position = vec3( -4.0, 8.0, 0.0 );
    //Light[0].I_a = vec3( 0.5, abs(sin(time) * cos(time)) , abs(cos(time)) );
    Light[0].I_a = vec3( 0.1, 0.1 , 0.1 );
    Light[0].I_source = vec3( 1.0, 1.0, 1.0 );

    Box[0].center = vec3(0.0, (cos(4.0 * (time - (3.0 * PI / 12.0))) + 2.74)/2.0, 0.0);
    Box[0].xLen = 1.6;
    Box[0].yLen = cos(4.0 * (time - (3.0 * PI / 12.0))) + 2.74;
    Box[0].zLen = 1.6;
    Box[0].xAngle = 0.0;
    Box[0].yAngle = 2.0 * PI * sin(0.15 * time);
    Box[0].zAngle = 0.0;
    InitBoxVertices(0);
    Box[0].materialID = 2;
     
}

/////////////////////////////////////////////////////////////////////////////
// Computes intersection between a plane and a ray.
// Returns true if there is an intersection where the ray parameter t is
// between tmin and tmax, otherwise returns false.
// If there is such an intersection, outputs the value of t, the position
// of the intersection (hitPos) and the normal vector at the intersection 
// (hitNormal).
/////////////////////////////////////////////////////////////////////////////
bool IntersectPlane( in Plane_t pln, in Ray_t ray, in float tmin, in float tmax,
                     out float t, out vec3 hitPos, out vec3 hitNormal ) 
{
    vec3 N = vec3( pln.A, pln.B, pln.C );
    float NRd = dot( N, ray.d );
    float NRo = dot( N, ray.o );
    float t0 = (-pln.D - NRo) / NRd;
    if ( t0 < tmin || t0 > tmax ) return false;

    // We have a hit -- output results.
    t = t0;
    hitPos = ray.o + t0 * ray.d;
    hitNormal = normalize( N );
    return true;
}

/////////////////////////////////////////////////////////////////////////////
// Computes intersection between a plane and a ray.
// Returns true if there is an intersection where the ray parameter t is
// between tmin and tmax, otherwise returns false.
/////////////////////////////////////////////////////////////////////////////
bool IntersectPlane( in Plane_t pln, in Ray_t ray, in float tmin, in float tmax )
{
    vec3 N = vec3( pln.A, pln.B, pln.C );
    float NRd = dot( N, ray.d );
    float NRo = dot( N, ray.o );
    float t0 = (-pln.D - NRo) / NRd;
    if ( t0 < tmin || t0 > tmax ) return false;
    return true;
}

/////////////////////////////////////////////////////////////////////////////
// Computes intersection between a sphere and a ray.
// Returns true if there is an intersection where the ray parameter t is
// between tmin and tmax, otherwise returns false.
// If there is one or two such intersections, outputs the value of the 
// smaller t, the position of the intersection (hitPos) and the normal 
// vector at the intersection (hitNormal).
/////////////////////////////////////////////////////////////////////////////
bool IntersectSphere( in Sphere_t sph, in Ray_t ray, in float tmin, in float tmax,
                      out float t, out vec3 hitPos, out vec3 hitNormal ) 
{
    /////////////////////////////////
    // TASK: WRITE YOUR CODE HERE. //
    /////////////////////////////////

    // Generate temporary objects with 'test' prefix
    Sphere_t testSphere = sph;
    Ray_t testRay = ray;
    
    // Translate the temporary objects to sphere's local space
    testRay.o = testRay.o - testSphere.center;
    testSphere.center = vec3(0.0, 0.0, 0.0);
    
    // Components of the test quadratic equation
    float a = 1.0;
    float b = 2.0 * dot(testRay.d, testRay.o);
    float c = dot(testRay.o, testRay.o) - dot(testSphere.radius, testSphere.radius);
    
    // Discriminant
    float d = b * b - 4.0 * a * c;
    
    // No intersection
    // Includes the case of tangency, when d = 0.0
    if (d <= 0.0)
        return false;
    
    // They have a intersection
    float tMinor = (-b - sqrt(d)) / (2.0 * a);
    float tMajor = (-b + sqrt(d)) / (2.0 * a);
    
    // Choose the minimal positive solution
    float t0;
    if (tMinor > tmin) {
        t0 = tMinor;
    /*} else if (tMajor > tmin) {
        // tMinor <= 0 but tMajor > 0
        t0 = tMajor;*/
    } else {
        // tMinor, tMajor <= 0
         return false;
    }

    // Hit position and normal vector
    if ( tmin < t0 && t0 < tmax ) {
        t = t0;
        hitPos = ray.o + t * ray.d;
        hitNormal = normalize(hitPos - sph.center);
        return true;
    } else {
        // the "epsilon" problem
        return false;
    }
}

/////////////////////////////////////////////////////////////////////////////
// Computes intersection between a sphere and a ray.
// Returns true if there is an intersection where the ray parameter t is
// between tmin and tmax, otherwise returns false.
/////////////////////////////////////////////////////////////////////////////
bool IntersectSphere( in Sphere_t sph, in Ray_t ray, in float tmin, in float tmax )
{
    /////////////////////////////////
    // TASK: WRITE YOUR CODE HERE. //
    /////////////////////////////////

    // Just used to cater for parameter list
    float t;
    vec3 hitPos, hitNormal;
    
    // Some redundant calculations of the precise hit position
    // for keeping the consistency of the same code
    return IntersectSphere(sph, ray, tmin, tmax, t, hitPos, hitNormal);
}

/////////////////////////////////////////////////////////////////////////////
// Computes (I_a * k_a) + k_shadow * I_source * [ k_d * (N.L) + k_r * (R.V)^n ].
// Input vectors L, N and V are pointing AWAY from surface point.
// Assume all vectors L, N and V are unit vectors.
/////////////////////////////////////////////////////////////////////////////
vec3 PhongLighting( in vec3 L, in vec3 N, in vec3 V, in bool inShadow, 
                    in Material_t mat, in Light_t light )
{
    if ( inShadow ) {
        return light.I_a * mat.k_a;
    }
    else {
        vec3 R = reflect( -L, N );
        float N_dot_L = max( 0.0, dot( N, L ) );
        float R_dot_V = max( 0.0, dot( R, V ) );
        float R_dot_V_pow_n = ( R_dot_V == 0.0 )? 0.0 : pow( R_dot_V, mat.n );

        return light.I_a * mat.k_a + 
               light.I_source * (mat.k_d * N_dot_L + mat.k_r * R_dot_V_pow_n);
    }
}
mat3 RotateXMat(float a)
{
    return mat3(1.0, 0.0, 0.0, 0.0, cos(a), sin(a), 0.0, -sin(a), cos(a));
}
mat3 RotateYMat(float a)
{
    return mat3(cos(a), 0.0, -sin(a), 0.0, 1.0, 0.0, sin(a), 0.0, cos(a));
}
mat3 RotateZMat(float a)
{
    return mat3(cos(a), sin(a), 0.0,
                -sin(a), cos(a), 0.0,
                0.0, 0.0, 1.0);
}

/////////////////////////////////////////////////////////////////////////////
// Computes intersection between a box and a ray.
// Returns true if there is an intersection where the ray parameter t is
// between tmin and tmax, otherwise returns false.
/////////////////////////////////////////////////////////////////////////////
bool IntersectTriangle(in Triangle_t triangle, in Ray_t ray, in float tmin, in float tmax,
    out float t, out vec3 hitPos, out vec3 hitNormal)
{
    // Equation w.r.t. beta, gamma and t
    mat3 LeftMat = mat3(triangle.A - triangle.B, triangle.A - triangle.C, ray.d);
    vec3 rightVec = vec3(triangle.A - ray.o);

    vec3 solution = inverse(LeftMat) * rightVec;
    float beta = solution.x;
    float gamma = solution.y;
    t = solution.z;

    bool isHit = (beta + gamma < 1.0)
        && (beta > 0.0) && (gamma > 0.0)
        && (tmin < t && t < tmax);
    
    // No intersection
    if ( !isHit )
        return false;
    
    // t has been already updated
    // ......
    
    // Hit Position
    hitPos = ray.o + t * ray.d;
    
    // Hit Normal Vector
    vec3 AB = triangle.B - triangle.A;
    vec3 AC = triangle.C - triangle.A;
    vec3 BC = triangle.C - triangle.B;
    vec3 NormalA = cross(AB, AC);
    vec3 NormalB = cross(AB, BC);
    vec3 NormalC = cross(AC, BC);
    hitNormal = normalize( (1.0-beta-gamma)*NormalA + beta*NormalB + gamma*NormalC );
    
    return true;
}

bool IntersectTriangle(in Triangle_t triangle, in Ray_t ray, in float tmin, in float tmax)
{
    float t;
    vec3 hitPos, hitNormal;
    
    return IntersectTriangle(triangle, ray, tmin, tmax,
        t, hitPos, hitNormal);
}

bool IntersectBox(in Box_t box, in Ray_t ray, in float tmin, in float tmax,
                     out float t, out vec3 hitPos, out vec3 hitNormal)
{
    // Generate temporary objects
    Ray_t testRay = ray;
    
    // Rotation Matrix
    mat3 rotationMat = RotateXMat(box.xAngle) * RotateYMat(box.yAngle) * RotateZMat(box.zAngle);
    // Translation and rotation of points
    testRay.o = inverse(rotationMat) * (ray.o - box.center);
    // Rotation of vectors
    testRay.d = normalize(inverse(rotationMat) * ray.d);
    
    bool hasHitSth = false;
    float nearest_t = DEFAULT_TMAX;   // The ray parameter t at the nearest hit point.
    vec3 nearest_hitPos;              // 3D position of the nearest hit point.
    vec3 nearest_hitNormal;           // Normal vector at the nearest hit point.
    // int nearest_hitMatID;             // MaterialID of the object at the nearest hit point.

    float temp_t;
    vec3 temp_hitPos;
    vec3 temp_hitNormal;
    bool temp_hasHit;

    // Intersection detection for each triangle
    for (int i = 0; i < 12; i++)
    {
        Triangle_t tempTriangle;
        tempTriangle.A = box.vertices[TriIndices[i].x];
        tempTriangle.B = box.vertices[TriIndices[i].y];
        tempTriangle.C = box.vertices[TriIndices[i].z];
        
        // Actual intersection detection
        temp_hasHit = IntersectTriangle(tempTriangle, testRay, tmin, tmax,
            temp_t, temp_hitPos, temp_hitNormal);
        
        if (temp_hasHit)
        {
            hasHitSth = true;
            
            if (temp_t < nearest_t)
            {
                nearest_t = temp_t;
                nearest_hitPos = temp_hitPos;
                nearest_hitNormal = temp_hitNormal;
            }
        }
    }
    
    if (hasHitSth) {
        t = nearest_t;
        
        // Transform points to the world space
        hitPos = box.center + rotationMat * nearest_hitPos;
        
        hitNormal = rotationMat * nearest_hitNormal;
        
        return true;
    } else
        return false;
}

bool IntersectBox(in Box_t box, in Ray_t ray, in float tmin, in float tmax)
{
    float t;
    vec3 hitPos, hitNormal;
    
    return IntersectBox(box, ray, tmin, tmax,
        t, hitPos, hitNormal);
}

/////////////////////////////////////////////////////////////////////////////
// Casts a ray into the scene and returns color computed at the nearest
// intersection point. The color is the sum of light from all light sources,
// each computed using Phong Lighting Model, with consideration of
// whether the interesection point is being shadowed from the light.
// If there is no interesection, returns the background color, and outputs
// hasHit as false.
// If there is intersection, returns the computed color, and outputs
// hasHit as true, the 3D position of the intersection (hitPos), the
// normal vector at the intersection (hitNormal), and the k_rg value
// of the material of the intersected object.
/////////////////////////////////////////////////////////////////////////////
vec3 CastRay( in Ray_t ray, 
              out bool hasHit, out vec3 hitPos, out vec3 hitNormal, out vec3 k_rg,out vec3 k_t ) 
{
    // Find whether and where the ray hits some object. 
    // Take the nearest hit point.

    bool hasHitSomething = false;
    float nearest_t = DEFAULT_TMAX;   // The ray parameter t at the nearest hit point.
    vec3 nearest_hitPos;              // 3D position of the nearest hit point.
    vec3 nearest_hitNormal;           // Normal vector at the nearest hit point.
    int nearest_hitMatID;             // MaterialID of the object at the nearest hit point.

    float temp_t;
    vec3 temp_hitPos;
    vec3 temp_hitNormal;
    bool temp_hasHit;

    /////////////////////////////////////////////////////////////////////////////
    // TASK:
    // * Try interesecting input ray with all the planes and spheres,
    //   and record the front-most (nearest) interesection.
    // * If there is interesection, need to record hasHitSomething,
    //   nearest_t, nearest_hitPos, nearest_hitNormal, nearest_hitMatID.
    /////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////
    // TASK: WRITE YOUR CODE HERE. //
    /////////////////////////////////

    for (int i = 0; i < NUM_PLANES; i++)
    {
        temp_hasHit = IntersectPlane(Plane[i], ray, DEFAULT_TMIN, DEFAULT_TMAX,
                                     temp_t, temp_hitPos, temp_hitNormal);
        if (temp_hasHit)
        {
            hasHitSomething = true;
            
            if (temp_t < nearest_t)
            {
                nearest_t = temp_t;
                nearest_hitPos = temp_hitPos;
                nearest_hitNormal = temp_hitNormal;
                nearest_hitMatID = Plane[i].materialID;
            }
        }   
    }
    
    for (int i = 0; i < NUM_SPHERES; i++)
    {
        temp_hasHit = IntersectSphere(Sphere[i], ray, DEFAULT_TMIN, DEFAULT_TMAX,
                                     temp_t, temp_hitPos, temp_hitNormal);
        if (temp_hasHit)
        {
            hasHitSomething = true;
            
            if (temp_t < nearest_t)
            {
                nearest_t = temp_t;
                nearest_hitPos = temp_hitPos;
                nearest_hitNormal = temp_hitNormal;
                nearest_hitMatID = Sphere[i].materialID;
            }
        }
    }
    for (int i = 0; i < NUM_BOXES; i++)
    {
        temp_hasHit = IntersectBox(Box[i], ray, DEFAULT_TMIN, DEFAULT_TMAX,
            temp_t, temp_hitPos, temp_hitNormal);

        if (temp_hasHit)
        {
            hasHitSomething = true;

            if (temp_t < nearest_t)
            {
                nearest_t = temp_t;
                nearest_hitPos = temp_hitPos;
                nearest_hitNormal = temp_hitNormal;
                nearest_hitMatID = Box[i].materialID;
            }
        }
    }
    // One of the output results.
    hasHit = hasHitSomething;
    if ( !hasHitSomething ) return BACKGROUND_COLOR;

    vec3 I_local = vec3( 0.0 );  // Result color will be accumulated here.

    /////////////////////////////////////////////////////////////////////////////
    // TASK:
    // * Accumulate lighting from each light source on the nearest hit point. 
    //   They are all accumulated into I_local.
    // * For each light source, make a shadow ray, and check if the shadow ray
    //   intersects any of the objects (the planes and spheres) between the 
    //   nearest hit point and the light source.
    // * Then, call PhongLighting() to compute lighting for this light source.
    /////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////
    // TASK: WRITE YOUR CODE HERE. //
    /////////////////////////////////
    for (int i = 0; i < NUM_LIGHTS; i++)
    {
        Ray_t shadowRay;
        // ShadowRay points to the light source
        // from the hit position of ray
        shadowRay.o = nearest_hitPos;
        shadowRay.d = normalize(Light[i].position - nearest_hitPos);
        
        for (int j = 0; j < NUM_PLANES; j++)
        {
            temp_hasHit = IntersectPlane(Plane[j], shadowRay,
                DEFAULT_TMIN, distance(Light[i].position, nearest_hitPos));
            if (temp_hasHit)
                break;
        }
        if ( ! temp_hasHit )
        {
            for (int j = 0; j < NUM_SPHERES; j++)
            {
                temp_hasHit = IntersectSphere(Sphere[j], shadowRay,
                    DEFAULT_TMIN, distance(Light[i].position, nearest_hitPos));
                if (temp_hasHit)
                    break;
            }
        }
        if ( ! temp_hasHit )
        {
            // Check the boxes
            for (int j = 0; j < NUM_BOXES; j++)
            {
                temp_hasHit = IntersectBox(Box[j], shadowRay,
                    DEFAULT_TMIN, distance(Light[i].position, nearest_hitPos));
                if (temp_hasHit)
                    break;
            }

        }
        // Light vector is a unit vector from hit point to the light source
        vec3 L = shadowRay.d;
        // Normal vector
        vec3 N = nearest_hitNormal;
        // View vector
        vec3 V = -normalize(ray.d);
        // shadowRay hits something
        bool inShadow = temp_hasHit;
        
        I_local += PhongLighting(L, N, V, inShadow,
            Material[nearest_hitMatID], Light[i]);
    }

    // Populate output results.
    hitPos = nearest_hitPos;
    hitNormal = nearest_hitNormal;
    k_rg = Material[nearest_hitMatID].k_rg;
    k_t = Material[nearest_hitMatID].k_t;
    return I_local;
}

/////////////////////////////////////////////////////////////////////////////
// Execution of fragment shader starts here.
// 1. Initializes the scene.
// 2. Compute a primary ray for the current pixel (fragment).
// 3. Trace ray into the scene with NUM_ITERATIONS recursion levels.
/////////////////////////////////////////////////////////////////////////////
void main(void)
{
    InitScene();

    // Scale pixel 2D position such that its y coordinate is in [-1.0, 1.0].
    vec2 pixel_pos = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

    // Position the camera.
    // vec3 cam_pos = vec3( 8.0 * sin(0.3 * time), 4.0, 8.0 * cos(0.3 * time) );
    float cam_theta = 4.0 * PI * sin(0.1 * time);
    float cam_radius = 2.0 + 3.0 / (2.0 * PI) * abs(cam_theta);
    vec3 cam_pos = vec3( cam_radius*cos(cam_theta), 4.0, cam_radius*sin(cam_theta) );
    vec3 cam_lookat = vec3( 0.0, 4.0, 0.0 );
    vec3 cam_up_vec = vec3( 0.0, 1.0, 0.0 );

    // Set up camera coordinate frame in world space.
    vec3 cam_z_axis = normalize( cam_pos - cam_lookat );
    vec3 cam_x_axis = normalize( cross(cam_up_vec, cam_z_axis) );
    vec3 cam_y_axis = normalize( cross(cam_z_axis, cam_x_axis));

    // Create primary ray.
    float pixel_pos_z = -1.0 / tan(FOVY / 2.0);
    Ray_t pRay;
    pRay.o = cam_pos;
    pRay.d = normalize( pixel_pos.x * cam_x_axis  +  pixel_pos.y * cam_y_axis  +  pixel_pos_z * cam_z_axis );

    // Start Ray Tracing.
    // Use iterations to emulate the recursion.

    vec3 I_result = vec3( 0.0 );
    vec3 compounded_k_rg = vec3( 0.5 );
    vec3 compounded_k_t = vec3( 0.5 );
    Ray_t nextRay_r = pRay;
    Ray_t nextRay_t = pRay;

    for ( int level = 0; level <= NUM_ITERATIONS; level++ ) 
    {
        bool hasHit_r, hasHit_t;
        vec3 hitPos_r, hitPos_t, hitNormal_r, hitNormal_t, k_rg1, k_t1, k_rg2, k_t2;
        vec3 I_local_r = CastRay( nextRay_r, hasHit_r, hitPos_r, hitNormal_r, k_rg1, k_t1 );
        vec3 I_local_t = CastRay( nextRay_t, hasHit_t, hitPos_t, hitNormal_t, k_rg2, k_t2 );
        I_result += compounded_k_rg * I_local_r + compounded_k_t * I_local_t;

        if ( !hasHit_r && !hasHit_t) break;

        compounded_k_rg *= k_rg1;
        compounded_k_t *= k_t2;
        nextRay_r = Ray_t( hitPos_r, normalize( reflect(nextRay_r.d, hitNormal_r) ) );
        nextRay_t = Ray_t( hitPos_t, normalize( refract(nextRay_t.d, hitNormal_t, 0.8) ) );
    }
    
    glFragColor = vec4( I_result, 1.0 );
}
