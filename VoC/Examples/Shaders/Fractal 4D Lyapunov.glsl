#version 420

// original https://www.shadertoy.com/view/lcj3Rd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 3D/4D Markus-Lyapunov fractal, using ray-marching
//
// by Tom Gidden <tom@gidden.net> 
//
// Creative Commons CC BY-SA 4.0
//
// Original OpenCL: 2010
// This version: 2024
//
// Adaptation of the familiar 2D Markus-Lyapunovs that render a 2D plane (A,B) where 0 = A = 4, 0 = B = 4
// and A & B come from a looping sequence of As and Bs, like "AABAB".
//
// Here, we add third and fourth axes, C (spatial) and D (temporal) on the sequence B,C,A,D,A.
// Each frame is a 3D "slice" of a 4D fractal.
//
// Rather than rendering the 2D slice showing colour for both chaos and order (and deep within order),
// we have to show chaos as transparent and the boundary between chaos and order as a shaded solid.
// This is done using a simple ray-marcher (like a ray-tracer but without bouncing on reflections)
//
// As the "solid" areas are fractal, we can't skip through the transparent space quickly,
// as it's stuffed with tiny pockets of order. Instead, the ray has to march through the
// space until it hits real order.  Then it refines the location with a back-and-forth,
// then determines an approximate surface normal for shading.  There's some noise added
// to the marching to avoid banding and other artefacts (change "jitter" in params)
//
// This is a rudimentary conversion of CUDA code used to render offline -- seconds per frame, if not more
// and do it in a relatively efficient way. Getting this stuff to run in real-time involves a significant
// quality drop.
//
// A better render using OpenCL: https://www.youtube.com/watch?v=6JFgkIvIxnM
// and a playlist of other renders and testing: https://www.youtube.com/playlist?list=PLHAv-hHDbuoIjVlc0APEfLoBr3cyUWMy0
//
// For more info: https://gidden.net/lyapunov
//

const float LYAP_INF = 1.0e+30;
const float LYAP_NAN = -1.0e+30;
const float LYAP_NINF = LYAP_NAN;
const float LYAP_EPSILON = 1.0e-29;

bool isNAN(float f) {
    return f <= LYAP_NAN;
}

bool isnotfinite(float f) {
    return f <= LYAP_NAN || f >= LYAP_INF || f <= LYAP_NINF;
}

bool isfinite(float f) {
    return f > LYAP_NAN && f < LYAP_INF;
}

//// Requires #version 330 or greater to work :(
//
// const float LYAP_NAN = intBitsToFloat(int(0xFFC00000u));
// const float LYAP_INF = intBitsToFloat(int(0x7F800000u));
// const float LYAP_NINF = intBitsToFloat(int(0xFF800000u));
// const float LYAP_EPSILON = 1.0e-29;
// 
// bool isNAN(float f) {
//     return isnan(f);
// }
// 
// bool isnotfinite(float f) {
//     return isnan(f) || isinf(f);
// }
// 
// bool isfinite(float f) {
//     return !isnan(f) && !isinf(f);
// }

vec3 null3 = vec3(0.0, 0.0, 0.0);
vec4 null4 = vec4(0.0, 0.0, 0.0, 0.0);

vec4 quat_from_axisangle(vec3 axis, float ang, bool inDegrees)
{
    ang = inDegrees ? (ang*3.1415926f/360.0f) : (ang*0.5f);
    return normalize(vec4(axis * sin(ang), cos(ang)));
}

vec4 quat_nlerp(vec4 q0, vec4 q1, float t)
{
    if (t==0.0 || (t<LYAP_EPSILON)) {
        return q0;
    }
    else if (t==1.0f || (t>1.0f-LYAP_EPSILON)) {
        return q1;
    }
    else {
        float dp = dot(q0, q1);
        float tA = dp>=0.0 ? t : -t;
        float tI = 1.0f-t;
        return normalize(vec4(q0*tI + q1*tA));
    }
}

vec3 transform_with_quat(vec4 q, vec3 v)
{
    return vec3(
        q.w*q.w*v.x + 2.0*q.y*q.w*v.z - 2.0*q.z*q.w*v.y + q.x*q.x*v.x + 2.0*q.y*q.x*v.y + 2.0*q.z*q.x*v.z - q.z*q.z*v.x - q.y*q.y*v.x,
        2.0*q.x*q.y*v.x + q.y*q.y*v.y + 2.0*q.z*q.y*v.z + 2.0*q.w*q.z*v.x - q.z*q.z*v.y + q.w*q.w*v.y - 2.0*q.x*q.w*v.z - q.x*q.x*v.y,
        2.0*q.x*q.z*v.x + 2.0*q.y*q.z*v.y + q.z*q.z*v.z - 2.0*q.w*q.y*v.x - q.y*q.y*v.z + 2.0*q.w*q.x*v.y - q.x*q.x*v.z + q.w*q.w*v.z
    );
}

vec4 quat_from_vectors(vec3 v0, vec3 v1, float scale, bool _normalize)
{
    vec3 m0 = _normalize ? normalize(v0) : v0;
    vec3 m1 = _normalize ? normalize(v1) : v1;

    vec3 c = cross(m0, m1);
    float d = dot(m0, m1);
    float s = sqrt((1.0 + d) * 2.0);
    vec4 p = vec4(c / s, s * 0.5);
    if (scale != 1.0) p *= scale;
    return p;
}

// Use 1 (old method) or 2 (new method); handles when camera is inside the volume
// differently: haven't found bug yet.
#define determineBoundsIntersections determineBoundsIntersections2

const int sequence[5] = int[](2, 3, 1, 4, 1); // 4D: BCADA
//const int sequence[5] = int[](2, 3, 1, 2, 1); // 3D: BCABA

const float t1 = 10.0;            // Animation duration
const float camPanDegrees = 30.0; // Angle to pan the camera
const float camDistance = 8.0;    // Distance of the camera from the point of interest
const float camZoom = 0.5;        // Zoom of lens (reciprocal)
const vec3 lookAt = vec3(3.0, 3.0, 3.0);  // The point of interest

// Try changing these to o=0.0, d=4.0 to see the full range. A bit too weird for my taste
const float originD = 3.25;  // Base value of "D" in 4D fractals
const float deltaD = 0.5;    // such that D(t) = originD + t*deltaT

// Iterations: 
// 1. "settle": an initial run of iterations to get started;
// 2. "accum": subsequent iterations that contribute.
//
// These numbers should be in the hundreds or more for proper
// renders.

const int settle = 5, accum = 10;       // "Fast" quality
//const int settle = 10, accum = 20;    // "High" quality

//const int settle = 500, accum = 1000; // Offline rendering. DO NOT USE

struct LyapParams {
    int settle;             // Initialisation iterations to allow exponent to settle (avoiding noise)
    int accum;              // Subsequent iterations to accumulate the exponent
    int stepMethod;         // Ray-marching method. 1=bad, 2=good.
    float D;                // Value of "D" for sequences that include "D". Can be tied to time for 4D Lyaps
    float nearThreshold;    // What constitutes near vs. far, so ray slows down (finer steps) when close.
    float nearMultiplier;   // And the multiplier when near (um... yeah, bad explanation)
    float opaqueThreshold;  // Below what exponent constitutes "order", ie. opaque
    float chaosThreshold;   // Below what exponent constitutes "visible" chaos, ie. corona
    float hitOpacity;       // Alpha of a "solid" hit, so the first apparent order doesn't stop the ray dead
    float depth;            // Rough depth of a typical ray, ie. number of expected steps.
    float jitter;           // Fraction of ray step length to randomise
    float refine;           // Back-and-forth subdivisions to zero-in on surface (eg. 32)
    float gradient;         // Fraction of ray length to use for the cardinal box around a hit point to estimate surface normal
};

LyapParams params = LyapParams(
    /*settle=*/settle,
    /*accum=*/accum,
    /*stepMethod=*/2,
    /*D=*/originD,          // Will be replaced in main()
    /*nearThreshold=*/0.5,
    /*nearMultiplier=*/8.0,
    /*opaqueThreshold=*/-0.5,
    /*chaosThreshold=*/-0.25,
    /*hitOpacity=*/0.25,
    /*depth=*/128.0,  // should be 512 or more, really!
    /*jitter=*/0.75,
    /*refine=*/8.0,  // should be 32 or more
    /*gradient=*/0.01
);

struct LyapCam {
    float M;
    vec3 C;
    vec4 Q;
    vec3 S0;
    vec3 SDX;
    vec3 SDY;
    vec4 ambient;
    vec4 chaosColor;
};

LyapCam cam;

// Calculate camera position and rotation for a given time, 0 = t = 1
void cam_init(float t) {
    float dist = camDistance;
    
    // Interactivity!!
    //if (mouse*resolution.xy.z > 10.0) {
        dist = 3.0 + 8.0 * mouse.y*resolution.y / resolution.y;
        t = 1.0 - mouse.x*resolution.x / resolution.x;
    //}
    
    cam = LyapCam(
        /*M=*/camZoom,   // "zoom"
        /*C=*/vec3(dist, dist, dist), // Nominal camera location (ie. when t=0.5)
        /*Q=*/null4,  // will be calculated
        /*S0=*/null3, // will be calculated
        /*SDX=*/null3,// will be calculated
        /*SDY=*/null3,// will be calculated
        /*ambient=*/vec4(0.001, 0.0, 0.0, 0.0),
        /*chaosColor=*/vec4(1.0, 0.25, 0.0, 0.2)
    );

    // Move C on a curved path around target (interesting feature)
    
    vec3 dir = cam.C - lookAt;                // cam relative to lookAt
    vec3 upIsh = vec3(0.0, 1.0, 0.0);         // roughly up
    vec3 axis = normalize(cross(dir, upIsh)); // roughly sideways
    
    // Get a rotation quat around the axis for the current frame
    vec4 rot0 = quat_from_axisangle(axis, camPanDegrees/2.0,/*inDegrees=*/true);
    vec4 rot1 = quat_from_axisangle(axis, camPanDegrees/-2.0,/*inDegrees=*/true);
    vec4 rotT = quat_nlerp(rot0, rot1, t);
    
    // Rotate the relative camera position using the quat
    vec3 dirT = transform_with_quat(rotT, dir);

    // Move the camera
    cam.C = lookAt + dirT;
    
    // Recalculate the camera's rotation quat to point to lookAt
    cam.Q = quat_from_vectors(vec3(0.0, 0.0, -1.0), normalize(dirT), 1.0, false);

 
    // Determine the projection frustum vectors: S0 is centre of "screen", SDX and SDY
    // are axis vectors for screen X and screen Y within 3-Lyapunov space
    cam.S0 = transform_with_quat(cam.Q, vec3(0.0, 0.0, 1.0));
    cam.SDX = transform_with_quat(cam.Q, vec3(cam.M, 0.0, 0.0));
    cam.SDY = transform_with_quat(cam.Q, vec3(0.0, cam.M, 0.0));
}

struct LyapLight {
    float M;  // Magnitude / Intensity
    vec3 C;   // Location of light
    vec4 Q;   // Direction quat
    vec3 V;   // Absolute direction vector from Q [via lights_init()]
    
    float lightInnerCone, lightOuterCone; // "Spotlight" cone
    float lightRange;  // Range of light.

    vec4 diffuseColor;
    float diffusePower;

    vec4 specularColor;
    float specularPower;
    float specularHardness;
};

LyapLight lights[2] = LyapLight[](
    LyapLight(
        /*M=*/1.0,
        /*C=*/vec3(5.0, 7.0, 3.0),
        /*Q=*/vec4(0.710595, 0.282082, -0.512168, 0.391368),
        /*V=*/vec3(0.0, 0.0, 0.0), // will get recalculated from C,Q
        /*lightInnerCone=*/0.0,    // will get recalculated from lightRange
        /*lightOuterCone=*/0.0,    // will get recalculated from lightRange
        /*lightRange=*/5.0,
        /*diffuseColor=*/vec4(0.4, 0.45, 0.6, 1.0),
        /*diffusePower=*/5.0,
        /*specularColor=*/vec4(0.5, 0.8, 1.0, 1.0),
        /*specularPower=*/100.0,
        /*specularHardness=*/500.0
    ),

    LyapLight(
        /*M=*/1.0,
        /*C=*/vec3(3.0, 7.0, 5.0),
        /*Q=*/vec4(0.039640, 0.840027, -0.538582, -0.052093),
        /*V=*/vec3(0.0, 0.0, 0.0), // will get recalculated from C,Q
        /*lightInnerCone=*/0.0,    // will get recalculated from lightRange
        /*lightOuterCone=*/0.0,    // will get recalculated from lightRange
        /*lightRange=*/1.5,
        /*diffuseColor=*/vec4(0.2, 0.25, 0.45, 1.0),
        /*diffusePower=*/5.0,
        /*specularColor=*/vec4(0.5, 0.8, 1.0, 1.0),
        /*specularPower=*/100.0,
        /*specularHardness=*/500.0
    )
);

// Phases
// (Note, these are mainly from the distributed CUDA-based version. Unnecessary now)

const int LYAP_NULL = 0;        // Uninitialised
const int LYAP_OUTSIDE = 1;     // Ray is outside volume
const int LYAP_INITIALIZED = 2; // Ray is starting
const int LYAP_MARCH1 = 3;      // Ray is doing initial march
const int LYAP_MARCH1_END = 4;  // Ray has completed initial march
const int LYAP_MARCH2 = 5;      // Ray has hit and is now going to backtrack/zero-in on hit point
const int LYAP_MARCH2_END = 6;  // Ray has completed zero-in
const int LYAP_MARCH3 = 7;      // Ray has stopped and needs to identify surface normal using 3D gradient
const int LYAP_MARCH3_END = 8;  // Ray has completed surface normal.

struct LyapPoint {
    vec3 V;       // direction vector
    vec3 P;       // Point under consideration: will become the final hit point.
    vec3 N;       // Surface normal at the hit point.

    float a;      // high-low alpha
    float c;      // chaos alpha
    float l;      // Lyapunov exponent

    float t;      // Progress along ray
    float t0, t1; // t-values of primary intersections of ray against back and front of volume
    float dt, Ndt, Fdt;  // step delta: current, and "near" and "far" for different phases.

    int state;    // State of ray
    bool near;    // Is the ray possibly near a hit?
};

// The "interesting" volume is 0.0 = a,b,c,d = 4.0
const float LMIN = 0.0;
const float LMAX = 4.0;

// Determine the colour of a point once calculated
/*RGBA*/ vec4 shade(LyapPoint point) 
{
    vec4 color;
    
    if(point.state == LYAP_OUTSIDE) {
        // This is almost definitely the wrong thing to do.
        return cam.chaosColor / log(point.c);
    }

    if(0.0 == point.a) {
        color.w = 0.0;
        return color;
    }

    // For each defined light
    for(int l = 0; l < lights.length(); l++) {
        vec3 camV;
        vec3 lightV, halfV;
        vec4 diffuse, specular, phong;
        float lightD2, i, j;

        vec3 P = point.P;
        vec3 N = point.N;
        //      float a = point.a;

        camV = cam.C - P;

        // Light vector (from point on surface to light source)
        lightV = lights[l].C - P;

        // Get the length^2 of lightV (for falloff)
        lightD2 = dot(lightV, lightV);

        // but then normalize lightV.
        lightV = normalize(lightV);

        // i: light vector dot surface normal
        i = dot(lightV, N);

        // j: light vector dot spotlight cone
        j = dot(lightV, lights[l].V);
        j = -j;

        if(j > lights[l].lightOuterCone) {

            // Diffuse component: k * (L.N) * colour
            i = clamp(i, 0.0, 1.0);
            diffuse = lights[l].diffuseColor * (i * lights[l].diffusePower);

            // Halfway direction between camera and light, from point on surface
            halfV = normalize(camV + lightV);

            // Specular component: k * (R.N)^alpha * colour
            // R is natural reflection, which is at 90 degrees to halfV (?)
            // (or is it?  Hmmm.  https://en.wikipedia.org/wiki/Phong_reflection_model)
            i = clamp(dot(N, halfV), 0.0, 1.0);
            i = pow(i, lights[l].specularHardness);

            specular = lights[l].specularColor * (i * lights[l].specularPower);

            phong = (specular + diffuse) * lights[l].lightRange / lightD2;

            if(j < lights[l].lightInnerCone)
                phong *= ((j - lights[l].lightOuterCone) / (lights[l].lightInnerCone - lights[l].lightOuterCone));

            phong += cam.ambient;
        } else {
            phong = cam.ambient;
        }

        color += phong;
    }

    if(point.c > 0.0)  // Chaos
        color += vec4(cam.chaosColor.xyz * cam.chaosColor.a, 1.0) / log(point.c);

    return color;
}

// Calculate Lyapunov exponent for sequence where A=P.x, B=P.y, C=P.z, D=d
float lyap4d(vec3 P) 
{
    float abcd[5] = float[](0.0, P.x, P.y, P.z, params.D);

    int seqi = 0; // Position in the sequence loop
    const int seqL = sequence.length();

    float r;       // Iteration value
    float v = 0.5; // Iterating value
    float l = 0.0; // Result accumulator
    
    // Settle by running the iteration without accumulation
    for(int n = 0; n < params.settle; n++) {
        r = abcd[sequence[seqi++]];
        if(seqi >= seqL) seqi = 0;
        v = r * v * (1.0 - v);
    }
    
    r = LYAP_NAN;

    if((v - 0.5 <= -1e-8) || (v - 0.5 >= 1e-8)) {
        // Now calculate the value by running the iteration with accumulation
        for(int n = 0; n < params.accum; n++) {
            r = abcd[sequence[seqi++]];
            if(seqi >= seqL) seqi = 0;
            v = r * v * (1.0 - v);
            r = r - 2.0 * r * v;

            if(r < 0.0)
                r = -r;

            l += log(r);
            // if (r_prev != LYAP_NAN && (r == r_prev || (r < r_prev*(1.0+LYAP_EPSILON) && r > r_prev*(1.0-LYAP_EPSILON))))
            //     break;

            if(isnotfinite(l))
                return LYAP_NAN;
        }
    }

    return l / float(params.accum);
}

// New implementation: unrolled, slightly more efficient, buggy
bool determineBoundsIntersections2(inout LyapPoint p) {
    
    // Find where the ray intersects the sides of the bounding cube
    // [0…4, 0…4, 0…4] and determine the smallest and largest finite values of
    // 't' for the ray equation for these intersections. Any planes that are
    // parallel to the ray will meet the ray at Infinity.
    //
    // Zero, one or two of these intersections will occur at a point
    // where all x, y and z are between 0 and 4 (ie. inside the cube)
    //
    // Actually, all six might occur within the cube, but
    // only if the points are equal. So, zero, one or two _unique_
    // intersections will occur. This is because zero, one or two
    // points on a line intersect a cube.
    //
    // So, for each one, eliminate it if the intersection point lies
    // outside the bounds of the other two axes.
    //
    // If it's valid, then find the smallest and largest finite 't' 
    // values for all the intersections.  This identifies which of the 
    // bounding planes the ray hits first and last.  The others can be ignored.

    p.t0 = LYAP_INF;
    p.t1 = LYAP_NINF;

    // If the ray isn't running along the x-axis (and thus intersects the x-planes at ±Infinity)...
    if (p.V.x != 0.0) {
        float t;
        vec3 _P;
        
        // Calc the value of t where the ray intersects the x-min plane
        t = (LMIN - cam.C.x) / p.V.x;

        // Calc the corresponding point for the value t
        _P = cam.C + p.V * t;

        // If the x-min axis intersection is outside 0<=y<=4, 0<=z<=4, eliminate it.
        if(_P.y >= LMIN && _P.y <= LMAX && _P.z >= LMIN && _P.z <= LMAX)  {

            // Set it as our best bound on both axes, as it's the first.
            p.t0 = t;
            p.t1 = t;
            p.P = _P;
        }
    
        // Calc the value of t where the ray intersects the x-max plane
        t = (LMAX - cam.C.x) / p.V.x;

        // Calc the corresponding point for the value t
        _P = cam.C + p.V * t;

        // If the x-max axis intersection is outside 0<=y<=4, 0<=z<=4, eliminate it.
        if(_P.y >= LMIN && _P.y <= LMAX && _P.z >= LMIN && _P.z <= LMAX)  {

            // If it's more extreme than either current bound, set it as the new bound.
            if (t < p.t0) { p.t0 = t; p.P = _P; }
            if (t > p.t1) p.t1 = t;
        }
    }

    // If the ray isn't running along the y-axis (and thus intersects the y-planes at ±Infinity)...
    if (p.V.y != 0.0) {
        float t;
        vec3 _P;

        // Calc the value of t where the ray intersects the y-min plane
        t = (LMIN - cam.C.y) / p.V.y;

        // Calc the corresponding point for the value t
        _P = cam.C + p.V * t;

        // If the y-min axis intersection is outside 0<=x<=4, 0<=z<=4, eliminate it.
        if(_P.x >= LMIN && _P.x <= LMAX && _P.z >= LMIN && _P.z <= LMAX)  {

            // If it's more extreme than either current bound, set it as the new bound.
            if (t < p.t0) { p.t0 = t; p.P = _P; }
            if (t > p.t1) p.t1 = t;
        }
    
        // Calc the value of t where the ray intersects the y-max plane
        t = (LMAX - cam.C.y) / p.V.y;

        // Calc the corresponding point for the value t
        _P = cam.C + p.V * t;

        // If the y-max axis intersection is outside 0<=x<=4, 0<=z<=4, eliminate it.
        if(_P.x >= LMIN && _P.x <= LMAX && _P.z >= LMIN && _P.z <= LMAX)  {

            // If it's more extreme than either current bound, set it as the new bound.
            if (t < p.t0) { p.t0 = t; p.P = _P; }
            if (t > p.t1) p.t1 = t;
        }
    }

    // If the ray isn't running along the z-axis (and thus intersects the z-planes at ±Infinity)...
    if (p.V.z != 0.0) {
        float t;
        vec3 _P;

        // Calc the value of t where the ray intersects the z-min plane
        t = (LMIN - cam.C.z) / p.V.z;

        // Calc the corresponding point for the value t
        _P = cam.C + p.V * t;

        // If the z-min axis intersection is outside 0<=x<=4, 0<=y<=4, eliminate it.
        if(_P.x >= LMIN && _P.x <= LMAX && _P.y >= LMIN && _P.y <= LMAX)  {

            // If it's more extreme than either current bound, set it as the new bound.
            if (t < p.t0) { p.t0 = t; p.P = _P; }
            if (t > p.t1) p.t1 = t;
        }
    
        // Calc the value of t where the ray intersects the z-max plane
        t = (LMAX - cam.C.z) / p.V.z;

        // Calc the corresponding point for the value t
        _P = cam.C + p.V * t;

        // If the z-max axis intersection is outside 0<=x<=4, 0<=y<=4, eliminate it.
        if(_P.x >= LMIN && _P.x <= LMAX && _P.y >= LMIN && _P.y <= LMAX)  {

            // If it's more extreme than either current bound, set it as the new bound.
            if (t < p.t0) { p.t0 = t; p.P = _P; }
            if (t > p.t1) p.t1 = t;
        }
    }

    // If failed to find a moving ray within the volume, then terminate the ray
    // before it starts
    if(p.t1 == 0.0) {
        p.state = LYAP_OUTSIDE;
        return false;
    }

    if(p.t0 < 0.0) {
        p.t0 = 0.0;
        p.P = cam.C;
    }

    // At this point, p.P should equal cam.C + p.V * p.t0

    // If only one point matched, then the ray must(?) start in
    // the volume and exit it, so we can start at zero instead.
    if(p.t0 == p.t1) {
        p.t1 = p.t0;
        p.t0 = 0.0;
    }

    // So, we start at t=t0
    p.t = p.t0;

    return true;
}

// Original implementation: cleaner, less efficient, less buggy
bool determineBoundsIntersections1(inout LyapPoint p) {

    // Find values for 't' for intersections with the six bounding
    // planes x=0, x=4, y=0, y=4, z=0, and z=4.  Any planes that are
    // parallel to the ray will meet the ray at Infinity.
    //
    // Zero, one or two of these intersections will occur at a point
    // where all x, y and z are between 0 and 4 (ie. inside the cube)
    // Actually, all six might occur within the cube, but
    // only if the points are equal. So, zero, one or two _unique_
    // intersections will occur. This is because zero, one or two
    // points on a line intersect a cube.

    // Find start and end point of ray within the cube
    p.t0 = LYAP_INF;
    p.t1 = 0.0;

    // First, find values for 't' for intersections with the six bounding
    // planes x=0, x=4, y=0, y=4, z=0, and z=4.  Any planes that are
    // parallel to the ray will meet the ray at Infinity.
    float ts[6] = float[](
        (p.V.x != 0.0) ? ((LMIN - cam.C.x) / p.V.x) : LYAP_INF,
        (p.V.x != 0.0) ? ((LMAX - cam.C.x) / p.V.x) : LYAP_INF,
        (p.V.y != 0.0) ? ((LMIN - cam.C.y) / p.V.y) : LYAP_INF,
        (p.V.y != 0.0) ? ((LMAX - cam.C.y) / p.V.y) : LYAP_INF,
        (p.V.z != 0.0) ? ((LMIN - cam.C.z) / p.V.z) : LYAP_INF,
        (p.V.z != 0.0) ? ((LMAX - cam.C.z) / p.V.z) : LYAP_INF
    );

    // Zero, one or two of these intersections will occur at a point
    // where all x, y and z are between 0 and 4 (ie. inside Lyapunov
    // space). Actually, all six might occur within Lyapunov space, but
    // only if the points are equal. So, zero, one or two _unique_
    // intersections will occur. This is because zero, one or two
    // points on a line intersect a cube.
    //
    // So, for each one, eliminate it if the intersection point lies
    // outside the bounds of the other two axes.
    vec3 _P;
    if(isfinite(ts[0])) {
        _P = cam.C + p.V * ts[0];
        // If the x-min axis intersection is outside 0<=y<=4, 0<=z<=4, eliminate it.
        if(_P.y < LMIN || _P.y > LMAX || _P.z < LMIN || _P.z > LMAX) ts[0] = LYAP_INF;
    }

    if(isfinite(ts[1])) {
        _P = cam.C + p.V * ts[1];
        // If the x-max axis intersection is outside 0<=y<=4, 0<=z<=4, eliminate it.
        if(_P.y < LMIN || _P.y > LMAX || _P.z < LMIN || _P.z > LMAX) ts[1] = LYAP_INF;
    }

    if(isfinite(ts[2])) {
        _P = cam.C + p.V * ts[2];
        // If the y-min axis intersection is outside 0<=x<=4, 0<=z<=4, eliminate it.
        if(_P.x < LMIN || _P.x > LMAX || _P.z < LMIN || _P.z > LMAX) ts[2] = LYAP_INF;
    }

    if(isfinite(ts[3])) {
        _P = cam.C + p.V * ts[3];
        // If the y-max axis intersection is outside 0<=x<=4, 0<=z<=4, eliminate it.
        if(_P.x < LMIN || _P.x > LMAX || _P.z < LMIN || _P.z > LMAX) ts[3] = LYAP_INF;
    }

    if(isfinite(ts[4])) {
        _P = cam.C + p.V * ts[4];
        // If the z-min axis intersection is outside 0<=x<=4, 0<=y<=4, eliminate it.
        if(_P.x < LMIN || _P.x > LMAX || _P.y < LMIN || _P.y > LMAX) ts[4] = LYAP_INF;
    }

    if(isfinite(ts[5])) {
        _P = cam.C + p.V * ts[5];
        // If the z-max axis intersection is outside 0<=x<=4, 0<=y<=4, eliminate it.
        if(_P.x < LMIN || _P.x > LMAX || _P.y < LMIN || _P.y > LMAX) ts[5] = LYAP_INF;
    }

    // Find the smallest and largest finite 't' values for all the
    // intersections.  This identifies which of the bounding planes the
    // ray hits first and last.  The others can be ignored.
    int i0 = -1, i1 = -1;
    for(int i = 0; i < 6; i ++) {
        if(isfinite(ts[i])) {
            if(i0 == - 1 || ts[i] < p.t0) p.t0 = ts[i0 = i];
            if(i1 == - 1 || ts[i] > p.t1) p.t1 = ts[i1 = i];
        }
    }

    // If both failed, then the ray didn't intersect Lyapunov space at
    // all, so exit: noise.
    if(i0 == -1 && i1 == -1) {
        p.state = LYAP_OUTSIDE;
        return false;
    }

    // If only one point matched, then the ray must(?) start in
    // Lyapunov space and exit it, so we can start at zero instead.
    else if(i1 == -1 || i0 == i1) {
        i1 = i0;
        p.t1 = p.t0;
        i0 = 0;
        p.t0 = 0.0;
    }

    // I'm not sure this is necessary, but just to make sure the
    // ray doesn't start behind the camera...
    if(p.t0 < 0.0)
        p.t0 = 0.0;

    // So, we start at t=t0
    p.t = p.t0;

    // Find P:  P = C + t.V
    p.P = cam.C + p.V * p.t;

    return true;
}

// Phase 0: set up the ray
LyapPoint raymarch0(vec2 uv) 
{
    LyapPoint p;

    // Work out the direction vector: start at C (camera), and
    // find the point on the screen plane (in 3D)
    p.V = normalize(cam.S0 + cam.SDX * uv.x + cam.SDY * uv.y) / cam.M;

    // float thresholdRange = params.opaqueThreshold - params.nearThreshold;

    // Find where the ray intersects the sides of the bounding cube
    // [0…4, 0…4, 0…4] and determine the smallest and largest finite values of
    // 't' for the ray equation for these intersections. Any planes that are
    // parallel to the ray will meet the ray at Infinity.

    // If the ray does not usefully intersect the volume...
    if (!determineBoundsIntersections(p)) {
        p.state = LYAP_OUTSIDE;
        return p;
    }

    // Set the alpha accumulators to zero
    p.a = 0.0;
    p.c = 0.0;

    // dt is the amount to add to 't' for each step in the initial
    // ray progression.  We calculate Fdt for the normal value,
    // and Ndt for the finer value used when close to the threshold
    // (ie. under nearThreshold)

    // There are different methods of progressing along the ray.

    switch(params.stepMethod) {
    case 1:
        // Method 1 divides the distance between the start and the end of
        // the ray equally.
        p.Fdt = (p.t1 - p.t0) / params.depth;
    break;

    case 2: 
    default:
        // Method 2 (default) divides the distance from the camera to the
        // virtual screen equally.
        p.Fdt = length(p.V) / params.depth;
    }

    p.dt = p.Fdt;
    p.Ndt = p.dt / params.nearMultiplier;
    p.near = false;

    p.state = LYAP_INITIALIZED;
    
    return p;
}

// Phase 1: Coarse ray marching
void raymarch1(inout LyapPoint p)
{
    // Okay, now we do the initial ray progression: we trace until the
    // exponent for the point is below a certain value. This value is
    // effectively the transition between transparent and opaque.
    p.state = LYAP_MARCH1;

    // Calculate the exponent at the current point.
    p.l = lyap4d(p.P);
    p.a = 0.0;

    // While the exponent is above the surface threshold (ie. while the
    // current point is in "transparent" space)...
    while(p.a <= 1.0)
    // while (p.l > params.opaqueThreshold)
    {
        // Step along the ray by 'dt' plus/minus a certain amount of
        // jitter (optional). This reduces moire fringes and herringbones
        // resulting from transitioning through thin sheets. Instead we
        // get what looks like noise, but is in fact stochastic sampling
        // of a diaphanous transition membrane.

        if(params.jitter != 0.0) {
            // We use the fractional part of the last Lyapunov exponent
            // as a pseudo-random number. This is then added to 'dt', scaled
            // by the amount of jitter requested.
            float jit = p.l - trunc(p.l);
            if(jit < 0.0) jit = 1.0 - jit * params.jitter;
            else jit = 1.0 + jit * params.jitter;

            if(isfinite(jit)) {
                p.t += p.dt * jit;
                p.P += p.V * p.dt * jit;
            } else {
                p.t += p.dt;
                p.P += p.V * p.dt;
            }
        } else {
            // No jitter, so just add 'dt'.
            p.t += p.dt;
            p.P += p.V * p.dt;
        }

        // If the ray has passed the first exit plane, then bugger it.
        // if (t>t1 || !P.in_lyap_space()) { // Overkill: passing t1 should be the exit of L-space anyway
        if(p.t > p.t1) {
            p.state = LYAP_OUTSIDE;
            return;
        }

        // Calculate this point's exponent
        p.l = lyap4d(p.P);

        // If the ray is still in transparent space, then we may still
        // want to accumulate alpha for clouding.
        if(p.l > params.chaosThreshold) {
            p.c += p.l;
        } else if(p.l > params.opaqueThreshold) {
            // Close-to-surface transparent space (?)
        } else {
            // Opaque
            p.a += params.hitOpacity;
            // p.a += (params.opaqueThreshold-p.l) * params.hitOpacity;
        }

        if(p.l <= params.nearThreshold && ! p.near) {
            p.near = true;
            p.dt = p.Ndt;
        } else if(p.l > params.nearThreshold && p.near) {
            p.near = false;
            p.dt = p.Fdt;
        }
    }

    // Clamp alpha between 0 and 1
    p.a = clamp(p.a, 0.0, 1.0);

    // At this point, the ray has either hit an opaque point, or
    // has exited Lyapunov space.

    p.state = LYAP_MARCH1_END;
    return;
}

// Phase 2: Post-hit refinement
void raymarch2(inout LyapPoint p) {
    // Now we've hit the surface, we now need to hone the intersection point 
    // by reversing back along the ray at half the speed.
    p.state = LYAP_MARCH2;

    // If we've gone through then sign is 0. 'sign' is
    // the direction of the progression.
    bool sign = false;
    bool osign = sign;

    // Half speed
    float Qdt = p.dt * - 0.5;
    vec3 QdV = p.V * Qdt;

    // Set the range of the honing to <t-dt, t>.
    float Qt1 = p.t;
    float Qt0 = p.t - p.dt;

    // Honing continues reversing back and forth, halving speed
    // each time. Once dt is less than or equal to dt/refine,
    // we stop: it's close enough.
    float min_Qdt = p.dt / params.refine;

    // While 't' is still in the range <t-dt, t> AND dt is still
    // of significant size...
    while(p.t <= Qt1 && p.t >= Qt0 && (Qdt <= - min_Qdt || Qdt >= min_Qdt)) {
        // Progress along the ray
        p.t += Qdt;
        p.P += QdV;

        // Calculate the exponent
        p.l = lyap4d(p.P);

        // If we've hit the threshold exactly, short-circuit.
        if(p.l == params.opaqueThreshold) break;

        // Work out whether we reverse or not:
        osign = sign;
        sign = (p.l >= params.opaqueThreshold);

        // If we've reversed, then halve the speed
        if(sign != osign) {
            Qdt *= - 0.5;
            QdV *= - 0.5;
        }
    }

    // At this point, we should be practically on the surface, rather
    // than above or through. Anyway, we're close enough.  P is now
    // our hit point.
    p.state = LYAP_MARCH2_END;
}

// Phase 3: Work out surface normal for shading
void raymarch3(inout LyapPoint p) 
{
    // Next, we want to find the surface normal at P. A good approximation
    // is to get the vector gradient by calculating the Lyapunov exponent
    // at the six cardinal points surrounding P +/- a tiny amount, which
    // we assume to be small enough that the Lyapunov exponent approximates
    // to a linear function.
    //
    // Find the difference for each axis, and normalize. The result is
    // pretty close.

    p.state = LYAP_MARCH3;

    float mag = p.dt * params.gradient;
    vec3 Ps[6] = vec3[](p.P, p.P, p.P, p.P, p.P, p.P);
    Ps[0].x -= mag;
    Ps[1].x += mag;
    Ps[2].y -= mag;
    Ps[3].y += mag;
    Ps[4].z -= mag;
    Ps[5].z += mag;

    float ls[6];
    for(int i = 0; i < 6; i ++) {
        ls[i] = lyap4d(Ps[i]);
    }

    p.N = normalize(vec3(
        ls[1] - ls[0],
        ls[3] - ls[2],
        ls[5] - ls[4]
    ));

    // Okay, we've done it. Output the hit point, the normal, the exact
    // exponent at P (not Really needed, but it does signal a hit failure
    // when l is NaN), and the accumulated alpha.

    p.state = LYAP_MARCH3_END;
}

// Calculate the direction of each light using their quat-based rotation, and then their light cone.
void lights_init() {

    for (int l=0; l<lights.length(); ++l) {
        float m = lights[l].M;
        if (m == 0.0) return;

        // Convert the light-local Z direction (0,0,1) to absolute using the light's Q.
        lights[l].V = normalize(transform_with_quat(lights[l].Q, vec3(0.0, 0.0, 1.0)));

        lights[l].lightInnerCone = dot(lights[l].V, normalize(transform_with_quat(lights[l].Q, vec3(-m, -m, 1.5))));
        lights[l].lightOuterCone = dot(lights[l].V, normalize(transform_with_quat(lights[l].Q, vec3(-m, -m, 1))));
    }
}

void main(void) {

    // Animation progress from 0 to 1
    float t = fract(time / t1);

    // Synthesize the "D" axis for 4D renders
    params.D = originD + t*deltaD;

    // Initialise the camera location
    cam_init(t);
    
    // Initialise lights.
    lights_init();

    // Convert to -1 = uv = 1
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
        
    // Ray march
    LyapPoint p = raymarch0(uv);
    if(p.state != LYAP_OUTSIDE) raymarch1(p);
    if(p.state != LYAP_OUTSIDE) raymarch2(p);
    if(p.state != LYAP_OUTSIDE) raymarch3(p);

    // Convert the abstract point structure -- position, surface normal,
    // chaos, etc. -- into a colour, using the lights provided.
    glFragColor = shade(p);
}