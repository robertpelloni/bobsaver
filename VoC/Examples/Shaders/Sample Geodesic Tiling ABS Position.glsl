#version 420

// original https://www.shadertoy.com/view/XtKSWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Geodesic tiling, with absolute positions
    ----------------------------------------

    Similar to https://www.shadertoy.com/view/llGXWc
    except with the full absolute position of each
    point.

*/

// --------------------------------------------------------
// Icosahedron faces and vertices
// --------------------------------------------------------

#define PHI (1.618033988749895)

// Return a or b, depending if p is in front of,
// or behind the plane normal
vec3 splitPlane(vec3 a, vec3 b, vec3 p, vec3 plane) {
    float split = max(sign(dot(p, plane)), 0.);
    return mix(a, b, split);
}

// An icosahedron vertex for the nearest face,
// a bit like finding the nearest icosahedron vertex,
// except we only need one per face
vec3 icosahedronVertex(vec3 p) {
    vec3 sp, v1, v2, result, plane;
    sp = sign(p);
    v1 = vec3(PHI, 1, 0) * sp;
    v2 = vec3(1, 0, PHI) * sp;
    plane = vec3(1, PHI, -PHI - 1.) * sp;
    result = splitPlane(v2, v1, p, plane);
    return normalize(result);
}

// Nearest dodecahedron vertex (nearest icosahrdron face)
vec3 dodecahedronVertex(vec3 p) {
    vec3 sp, v1, v2, v3, v4, result, plane;
    sp = sign(p);
    v1 = sp;
    v2 = vec3(0, 1, PHI + 1.) * sp;
    v3 = vec3(1, PHI + 1., 0) * sp;
    v4 = vec3(PHI + 1., 0, 1) * sp;
    plane = vec3(-1. - PHI, -1, PHI);
    result = splitPlane(v1, v2, p, plane * sp);
    result = splitPlane(result, v3, p, plane.yzx * sp);
    result = splitPlane(result, v4, p, plane.zxy * sp);
    return normalize(result);
}

// --------------------------------------------------------
// Triangle tiling
// Adapted from mattz https://www.shadertoy.com/view/4d2GzV
//
// Finds the closest triangle center on a 2D plane 
// --------------------------------------------------------

const float sqrt3 = 1.7320508075688772;
const float i3 = 0.5773502691896258;

const mat2 cart2tri = mat2(1, 0, i3, 2. * i3);
const mat2 tri2cart = mat2(1, 0, -.5, .5 * sqrt3);

vec2 closestTri(vec2 p) {
    p = cart2tri * p;
    vec2 pf = fract(p);
    vec2 v = vec2(1./3., 2./3.);
    vec2 tri = mix(v, v.yx, step(pf.y, pf.x));
    tri += floor(p);
    tri = tri2cart * tri;
    return tri;
}

// --------------------------------------------------------
// Geodesic tiling
//
// Finds the closest triangle center on the surface of a
// sphere:
// 
// 1. Intersect position with the face plane
// 2. Convert that into 2D uv coordinates
// 3. Find the closest triangle center (tile the plane)
// 4. Convert back into 3D coordinates
// 5. Project onto a unit sphere (normalize)
//
// You can use any tiling method, such as one that returns
// hex centers or adjacent cells, so you can create more
// interesting geometry later.
// --------------------------------------------------------

#define PI 3.14159265359

vec3 facePlane = vec3(0);
vec3 uPlane = vec3(0);
vec3 vPlane = vec3(0);

// Intersection point of vector and plane
vec3 intersection(vec3 n, vec3 planeNormal, float planeOffset) {
    float denominator = dot(planeNormal, n);
    float t = (dot(vec3(0), planeNormal) + planeOffset) / -denominator;
    return n * t;
}

// 3D position -> 2D (uv) coordinates on the icosahedron face
vec2 icosahedronFaceCoordinates(vec3 p) {
    vec3 i = intersection(normalize(p), facePlane, -1.);
    return vec2(dot(i, uPlane), dot(i, vPlane));
}

// 2D (uv) coordinates -> 3D point on a unit sphere
vec3 faceToSphere(vec2 facePoint) {
    return normalize(facePlane + (uPlane * facePoint.x) + (vPlane * facePoint.y));
}

// Edge length of an icosahedron with an inscribed sphere of radius of 1
float edgeLength = 1. / ((sqrt(3.) / 12.) * (3. + sqrt(5.)));
// Inner radius of the icosahedron's face
float faceRadius = (1./6.) * sqrt(3.) * edgeLength;

// Closest geodesic point (triangle center) on unit sphere's surface
vec3 geodesicTri(vec3 p, float subdivisions) {
    
    vec3 dv = dodecahedronVertex(p);
    vec3 iv = icosahedronVertex(p);
    
    facePlane = dv;
    vPlane = normalize(cross(iv, dv));
    uPlane = normalize(cross(vPlane, dv));
    
    // faceRadius is used as a scale multiplier so that our triangles
    // always stop at the edge of the face
    float uvScale = subdivisions / faceRadius / 2.;

    vec2 uv = icosahedronFaceCoordinates(p);
    vec2 tri = closestTri(uv * uvScale);
    return faceToSphere(tri / uvScale);
}

// --------------------------------------------------------
// Modelling
// --------------------------------------------------------

struct Model {
    float dist;
    vec3 color;
};

void spin(inout vec3 p) {
    float r = time / 6.;
    mat2 rot = mat2(cos(r), -sin(r), sin(r), cos(r));
       p.xz *= rot;
    p.zy *= rot;
}

// Smooth transition between subdivisions
float animSubdivitions(float start, float end) {
    
    float t = mod(time, 2.) - 1. + .5;
    t = clamp(t, 0., 1.);
    t = cos(t * PI + PI) * .5 + .5;
    
    float n = floor(time / 2.);

    float diff = end - start;
    n = mod(n, diff + 1.);

    if (n == diff) {
        return end - diff * t;
    }

    return n + start + t;
} 

// The actual model
Model map(vec3 p) {
    
    // Spin the whole model
    spin(p);
    
    float subdivisions = animSubdivitions(1., 10.);
    vec3 point = geodesicTri(p, subdivisions);

    float sphere = length(p - point) - .195 / subdivisions; 
    
    // Indicate point's position
    vec3 color = point * .5 + .5;

    return Model(sphere, color);
}

// --------------------------------------------------------
// Ray Marching
// Adapted from cabbibo https://www.shadertoy.com/view/Xl2XWt
// --------------------------------------------------------

const float MAX_TRACE_DISTANCE = 8.;
const float INTERSECTION_PRECISION = .001;
const int NUM_OF_TRACE_STEPS = 100;

struct CastRay {
    vec3 origin;
    vec3 direction;
};

struct Ray {
    vec3 origin;
    vec3 direction;
    float len;
};

struct Hit {
    Ray ray;
    Model model;
    vec3 pos;
    bool isBackground;
    vec3 normal;
    vec3 color;
};

vec3 calcNormal( in vec3 pos ){
    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 nor = vec3(
        map(pos+eps.xyy).dist - map(pos-eps.xyy).dist,
        map(pos+eps.yxy).dist - map(pos-eps.yxy).dist,
        map(pos+eps.yyx).dist - map(pos-eps.yyx).dist );
    return normalize(nor);
}
    
Hit raymarch(CastRay castRay){

    float currentDist = INTERSECTION_PRECISION * 2.0;
    Model model;
    
    Ray ray = Ray(castRay.origin, castRay.direction, 0.);

    for( int i=0; i< NUM_OF_TRACE_STEPS ; i++ ){
        if (currentDist < INTERSECTION_PRECISION || ray.len > MAX_TRACE_DISTANCE) {
            break;
        }
        model = map(ray.origin + ray.direction * ray.len);
        currentDist = model.dist;
        ray.len += currentDist;
    }
    
    bool isBackground = false;
    vec3 pos = vec3(0);
    vec3 normal = vec3(0);
    vec3 color = vec3(0);
    
    if (ray.len > MAX_TRACE_DISTANCE) {
        isBackground = true;
    } else {
        pos = ray.origin + ray.direction * ray.len;
        normal = calcNormal(pos);
    }

    return Hit(ray, model, pos, isBackground, normal, color);
}

// --------------------------------------------------------
// Rendering
// --------------------------------------------------------

vec3 render(Hit hit){
    if (hit.isBackground) {
        return vec3(0);
    }
    vec3 color = hit.model.color;
    color += sin(dot(hit.normal, vec3(0,1,0))) * .2; // lighting
    color *= 1. - clamp(hit.ray.len * .4 - .8, 0., 1.); // fog
    return color;
}

// --------------------------------------------------------
// Camera
// https://www.shadertoy.com/view/Xl2XWt
// --------------------------------------------------------

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

void main(void)
{
    
    vec2 p = (-resolution.xy + 2. * gl_FragCoord.xy) / resolution.y;

    vec3 camPos = vec3(0, 0, 2.5);
    vec3 camTar = vec3(0);
    float camRoll = 0.;
    mat3 camMat = calcLookAtMatrix(camPos, camTar, camRoll);
    
    vec3 rd = normalize(camMat * vec3(p.xy, 2.));
    Hit hit = raymarch(CastRay(camPos, rd));

    vec3 color = render(hit);
    glFragColor = vec4(color,1.0);
}
