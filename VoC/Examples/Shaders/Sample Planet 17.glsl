#version 420

// original https://www.shadertoy.com/view/wtc3Wj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Ecosphere - the procedural creation of a planet like sphere.
//
// Patrik Sandahl, 2019 - patrik.sandahl@gmail.com
//
// 3D noise algorithm by Ian McEwan, Ashima Arts.

#define EPSILON 0.001
#define DEFAULT_ZOOM 1.0

#define PI 3.141592653589

// Material for nothing. I.e. the empty space.
#define MAT_NOTHING 0

// Material for the colored sphere.
#define MAT_COLOR_SPHERE 1

// Material for the sea water.
#define MAT_WATER_SPHERE 2

// World seed - skew the input for the noise.
#define WORLD_SEED 47.159

// Initial scene - base sphere goes from dark to light and
// gradually morphs into the naked ecosphere.
#define SCENE0 0

// Second scene - the colored ecosphere.
#define SCENE1 1

// Third scene - sea level rises.
#define SCENE2 2

// Forth scene - one day and night cycle.
#define SCENE3 3

// A ray object with origin and direction.
struct Ray {
    vec3 origin;
    vec3 direction;
};
    
// Force normalization of direction when creating a ray.
Ray ray(vec3 origin, vec3 direction);

// Calculate a point at distance d along the ray.
vec3 point(Ray r, float d);

// Generate a primary camera ray given:
// eye - the camera position.
// at - the position where the camera is looking.
// up - the world up position.
// focalLength - the zoom value for the camera. A greater value zoom in.
// uv - the uv coordinate for which the ray is produced. It is assumed
// that uv zero is in the middle of the projection.
// The camera is assuming an OpenGL like coordinate system.
Ray cameraRay(vec3 eye, vec3 at, vec3 up, float focalLength, vec2 uv);

// An intersection object with distance along the ray, an displacement
// offset for the object and the material id for the object.
struct Intersection {
    float dist;
    float offset;
    int material;
};

// Produce the closest intersection from the scene given the position.
Intersection intersectScene(int sceneId, vec3 pos);

// March the ray for an intersection with the scene.
Intersection march(int sceneId, Ray r, float far);
    
// Calculate a normal through central difference. It's very expensive
// though. Consider a noise function with analytical derivatives as
// future improvement.
vec3 calcNormal(int sceneId, vec3 pos);

// Calculate a 2D rotations matrix.
mat2 calcRotate2d(float theta);

// Distance function for the base sphere.
float baseSphere(vec3 pos);

// Distance function for a shere. The position - relative origin - and
// the radius for the sphere.
float sphere(vec3 pos, float radius);

// Get the sun's position.
vec3 sunPosition(int sceneId);

// Normalize the height offset from ~[-1 : 1] to ~[0 : 1].
float normalizeOffset(float offset);

// Get the terrain color the given height offset.
vec3 terrainColor(float offset);

// Noise functions.
float fbm(vec3 pos, int numOctaves);
float snoise(vec3 v);

// Entry point for generating the image.
void main(void)
{
    // Normalized pixel coordinate where origo is in the
    // middle and compensation is made for aspect ratio.
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    
    // Make a primary ray for the uv position.
    vec3 eye = vec3(0.0, 0.0, 25.0);
    vec3 at = vec3(0.0);
    vec3 up = normalize(vec3(0.5, 1.0, 0.0)); // Tilt the view a little.
    
    Ray primaryRay = cameraRay(eye, at, up, DEFAULT_ZOOM, uv);
            
    // Determine scene id from time.   
    int sceneId = SCENE0;
    if (time >= 24.0) {
          sceneId = SCENE3;
    } else if (time >= 16.0) {
        sceneId = SCENE2;
    } else if (time >= 12.0) {
        sceneId = SCENE1;
    }
    
    // Perform the ray marching, keep the far plane near ;-)
    Intersection intersection = march(sceneId, primaryRay, 45.0);
    
    // Create a default color for the current pixel.
    vec3 color = vec3(0.0);
    
    switch (intersection.material) {
        // A sphere colored using its height offset.
        case MAT_COLOR_SPHERE:
        {
             vec3 pos = point(primaryRay, intersection.dist);
            vec3 lightDirection = normalize(sunPosition(sceneId) - pos);
            vec3 normal = calcNormal(sceneId, pos);                
            float light = max(0.0, dot(normal, lightDirection));            
                            
            vec3 graySphere = vec3(normalizeOffset(intersection.offset));
            vec3 colorSphere = terrainColor(intersection.offset);
            color = mix(graySphere, colorSphere, smoothstep(12.0, 16.0, time));
                
            color = color * light;
        }
           break;
        
        // A sphere with ocean color.
        case MAT_WATER_SPHERE:
        {
            vec3 pos = point(primaryRay, intersection.dist);
            vec3 lightDirection = normalize(sunPosition(sceneId) - pos);
            vec3 normal = calcNormal(sceneId, pos);                
            float light = max(0.0, dot(normal, lightDirection));
            
            vec3 ocean = vec3(0.0, 67.0 / 255.0, 123.0 / 255.0);
            color = ocean * light;
        }
        break;
        
        default:
            // Just rendering the black void with default color.
            break;
    }

    // Output to screen.
    glFragColor = vec4(color, 1.0);
}

Ray ray(vec3 origin, vec3 direction)
{
    return Ray(origin, normalize(direction));
}

vec3 point(Ray r, float d)
{
    return r.origin + r.direction * d;
}

Ray cameraRay(vec3 eye, vec3 at, vec3 up, float focalLength, vec2 uv)
{
    vec3 z = normalize(at - eye);
    vec3 x = normalize(cross(z, up));
    vec3 y = cross(x, z);
    
    vec3 center = eye + z * focalLength;
    vec3 xy = center + uv.x * x + uv.y * y;
    
    return ray(eye, xy - eye);
}

Intersection intersectScene(int sceneId, vec3 pos)
{
    // The sphere shall be rotated in all scenes.
    pos.xz = calcRotate2d(time * 0.05) * pos.xz;
    
    // And there always be a base sphere.
    float sphereDist = baseSphere(pos - vec3(0.0));
    
    // There shall always be height offset.
    float offset = fbm((pos + WORLD_SEED) * 0.13, 9);
    
    if (sceneId == SCENE0) {
        
        // Mix between the base sphere and the ecosphere.
        float factor = smoothstep(4.0, 10.0, time);
        float dist = mix(sphereDist, sphereDist - offset, factor);
        
        return Intersection(dist, offset, MAT_COLOR_SPHERE);      
    }  else if (sceneId == SCENE1) {
        
        // Just the ecosphere.
        return Intersection(sphereDist - offset, offset, MAT_COLOR_SPHERE);      
    } else {
        
        // The ecosphere and sea.
        float seaDist = sphere(pos - vec3(0.0), mix(9.00, 9.88, smoothstep(16.0, 24.0, time)));        
        if (seaDist < sphereDist - offset) {
            return Intersection(seaDist, 0.0, MAT_WATER_SPHERE);
        } else {
            return Intersection(sphereDist - offset, offset, MAT_COLOR_SPHERE);
        }
    }
}

Intersection march(int sceneId, Ray r, float far)
{
    float rayDistance = 0.0;
    Intersection intersection = Intersection(0.0, 0.0, MAT_NOTHING);
    
    for (int i = 0; i < 100; ++i) {       
        intersection = intersectScene(sceneId, point(r, rayDistance));
        
        rayDistance += intersection.dist;
        if (intersection.dist < EPSILON) break;
        if (rayDistance > far) {
            intersection.material = MAT_NOTHING;
            break;
        }
    }
    
    intersection.dist = rayDistance;
    return intersection;
}

vec3 calcNormal(int sceneId, vec3 pos)
{
    float d = intersectScene(sceneId, pos).dist;
    vec2 e = vec2(EPSILON, 0.0);
    
    vec3 n = d - vec3(
        intersectScene(sceneId, pos - e.xyy).dist,
        intersectScene(sceneId, pos - e.yxy).dist,
        intersectScene(sceneId, pos - e.yyx).dist
    );
    
    return normalize(n);
}

mat2 calcRotate2d(float theta)
{
    return mat2(vec2(cos(theta), -sin(theta)), vec2(sin(theta), cos(theta)));
}

float baseSphere(vec3 pos)
{
    return sphere(pos, 10.0);
}

float sphere(vec3 pos, float radius)
{
    return length(pos) - radius;
}

vec3 sunPosition(int sceneId)
{
    // The base position for the sun.
    vec3 basePosition = vec3(100.0, 0.0, 100.0);
    
    if (sceneId == SCENE0) {
        // Let the sun travel one half orbit from back of sphere to base.
        float theta = mix(-PI, 0.0, smoothstep(0.0, 10.0, time));
        basePosition.xz = calcRotate2d(theta) * basePosition.xz;
    } else if (sceneId == SCENE3) {
        // Let the sun orbit. 20 seconds for a full circle.
        float theta = mix(0.0, PI * 2.0, smoothstep(24.0, 34.0, time));
        basePosition.xz = calcRotate2d(theta) * basePosition.xz;
    }
    
    return basePosition;
}

float normalizeOffset(float offset)
{
    return offset * 0.75 + 0.5;
}

vec3 terrainColor(float offset)
{
    offset = normalizeOffset(offset);
    
    vec3 clay = vec3(127.0 / 255.0, 95.0 / 255.0, 63.0 / 255.0);
    vec3 fern = vec3(79.0 / 255.0, 121.0 / 255.0, 66.0 / 255.0);
    vec3 forest = vec3(11.0 / 255.0, 102.0 / 255.0, 35.0 / 255.0);
    vec3 granite = vec3(97.0 / 255.0, 97.0 / 255.0, 97.0 / 255.0);
    vec3 snow = vec3(1.0, 250.0 / 255.0, 250.0 / 255.0);
    
    vec3 color = mix(clay, fern, smoothstep(0.0, 0.4, offset));
    color = mix(color, forest, smoothstep(0.4, 0.55, offset));
    color = mix(color, granite, smoothstep(0.55, 0.65, offset));
    color = mix(color, snow, smoothstep(0.65, 1.0, offset));
    
    return vec3(color);
}

float fbm(vec3 pos, int numOctaves) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100);
    for (int i = 0; i < numOctaves; ++i) {
        v += a * snoise(pos);
        pos = pos * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

//    Simplex 3D Noise 
//    by Ian McEwan, Ashima Arts
//
vec4 permute(vec4 x) {return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r) {return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v)
{ 
      const vec2 C = vec2(1.0/6.0, 1.0/3.0) ;
      const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
      vec3 i = floor(v + dot(v, C.yyy) );
      vec3 x0 = v - i + dot(i, C.xxx) ;

    // Other corners
      vec3 g = step(x0.yzx, x0.xyz);
      vec3 l = 1.0 - g;
      vec3 i1 = min( g.xyz, l.zxy );
      vec3 i2 = max( g.xyz, l.zxy );

      //  x0 = x0 - 0. + 0.0 * C 
      vec3 x1 = x0 - i1 + 1.0 * C.xxx;
      vec3 x2 = x0 - i2 + 2.0 * C.xxx;
      vec3 x3 = x0 - 1. + 3.0 * C.xxx;

    // Permutations
      i = mod(i, 289.0 ); 
      vec4 p = permute( permute( permute( 
                      i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
                         + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
                      + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

    // Gradients
    // ( N*N points uniformly over a square, mapped onto an octahedron.)
      float n_ = 1.0/7.0; // N=7
      vec3  ns = n_ * D.wyz - D.xzx;

      vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

      vec4 x_ = floor(j * ns.z);
      vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

      vec4 x = x_ *ns.x + ns.yyyy;
      vec4 y = y_ *ns.x + ns.yyyy;
      vec4 h = 1.0 - abs(x) - abs(y);

      vec4 b0 = vec4( x.xy, y.xy );
      vec4 b1 = vec4( x.zw, y.zw );

      vec4 s0 = floor(b0)*2.0 + 1.0;
      vec4 s1 = floor(b1)*2.0 + 1.0;
      vec4 sh = -step(h, vec4(0.0));

      vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
      vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

      vec3 p0 = vec3(a0.xy,h.x);
      vec3 p1 = vec3(a0.zw,h.y);
      vec3 p2 = vec3(a1.xy,h.z);
      vec3 p3 = vec3(a1.zw,h.w);

    //Normalise gradients
      vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
      p0 *= norm.x;
      p1 *= norm.y;
      p2 *= norm.z;
      p3 *= norm.w;

    // Mix final noise value
      vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
      m = m * m;
      return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                  dot(p2,x2), dot(p3,x3) ) );
}
