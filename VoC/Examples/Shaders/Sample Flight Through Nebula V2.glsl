#version 420

// original https://www.shadertoy.com/view/WsG3zd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// also see 
// voronoi  version, https://www.shadertoy.com/view/tdyGzK
// simplex version, https://www.shadertoy.com/view/WsG3zd
// box version, https://www.shadertoy.com/view/tsK3Rd
// simplex function taken from https://www.shadertoy.com/view/XsX3zB

#define RAY_MAX_STEPS 100
#define RAY_MAX_DISTANCE 10.0
#define RAY_CAMERA_FADE_START_DISTANCE 0.5
#define RAY_CAMERA_FADE_END_DISTANCE 2.0
#define RAY_MAX_STEPS_SHADOW 15

#define K    0.1428571428571429    // 1/7
#define Ko    0.3571428571428571    // 1/2-(K/2)
#define K2    0.0204081632653061    // 1/(7*7)
#define Kz    0.1666666666666667    // 1/6
#define Kzo    0.4166666666666667    // 1/2-(1/(6*2))
#define Km    0.0034602076124567    // 1/289
#define PI    3.1415926535897932384626433832795
    
struct camera {
   vec3 origin, forward, right, up;
   float zoom; // Distance from screen
};

struct ray {
   vec3 origin, direction;
};
       
camera getCameraDirection(vec3 origin, vec3 direction, float zoom) {
   camera camera;
   camera.origin = origin;
   camera.forward = normalize(direction);
   camera.right = cross(vec3(0.0,1.0,0.0), camera.forward);
   camera.up = cross(camera.forward, camera.right);
   camera.zoom = zoom;
   return camera;
}

ray getRay(vec2 uv, camera camera) {
    ray ray;
    ray.origin = camera.origin;
    vec3 center = ray.origin + camera.forward * camera.zoom;
    vec3 intersection = center + (uv.x * camera.right) + ( uv.y * camera.up );
    ray.direction = normalize(intersection - ray.origin);
    return ray;   
}

float mod289(float x) {
    return x - floor(x * Km) * 289.0;
}

float mod7(float x) {
    //return x;
    return x - floor(x * (1.0 / 7.0)) * 7.0;
}

//Wrap around for id generation
float wrap(float x) {
    //return mod((34.0 * x + 1.0) * x, 289.0);
    return mod289((34.0 * x + 1.0) * x);
}

// --------------------------------------------------
//from https://www.shadertoy.com/view/XsX3zB
vec3 random3(vec3 c) {
    float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}

/* skew constants for 3d simplex functions */
#define F3 0.333333
#define G3 0.1666667

/* 3d simplex noise */
float simplex3d(vec3 p) {
     /* 1. find current tetrahedron T and it's four vertices */
     /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
     /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
     
     /* calculate s and x */
     vec3 s = floor(p + dot(p, vec3(F3)));
     vec3 x = p - s + dot(s, vec3(G3));
     
     /* calculate i1 and i2 */
     vec3 e = step(vec3(0.0), x - x.yzx);
     vec3 i1 = e*(1.0 - e.zxy);
     vec3 i2 = 1.0 - e.zxy*(1.0 - e);
         
     /* x1, x2, x3 */
     vec3 x1 = x - i1 + G3;
     vec3 x2 = x - i2 + 2.0*G3;
     vec3 x3 = x - 1.0 + 3.0*G3;
     
     /* 2. find four surflets and store them in d */
     vec4 w, d;
     
     /* calculate surflet weights */
     w.x = dot(x, x);
     w.y = dot(x1, x1);
     w.z = dot(x2, x2);
     w.w = dot(x3, x3);
     
     /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
     w = max(0.6 - w, 0.0);
     
     /* calculate surflet components */
     d.x = dot(random3(s), x);
     d.y = dot(random3(s + i1), x1);
     d.z = dot(random3(s + i2), x2);
     d.w = dot(random3(s + 1.0), x3);
     
     /* multiply d by w^4 */
     w *= w;
     w *= w;
     d *= w;
     
     /* 3. return the sum of the four surflets */
     return dot(d, vec4(52.0));
}
// --------------------------------------------------

vec3 RayMarch(ray ray, float maxDistance, int maxSteps)
{
    float maxStepsf = float(maxSteps);
    float stepSize = maxDistance/maxStepsf;
    vec3 total = vec3(0.0);
    
    // Stop the shimmering??
    //float currentDistance = stepSize-(ray.origin.z-(floor(ray.origin.z/stepSize)*stepSize));
    float currentDistance = 1.0;
    
    float strike = 1.0+smoothstep(0.5,1.0,sin(ray.direction.z+time*20.0)*sin(ray.direction.x +time*30.0)*cos(ray.direction.y +time*40.0)*(wrap(time)/289.0));
    
    for(float i=0.0; i<maxStepsf; i++) {
        vec3 currentPoint = ray.origin + ray.direction * currentDistance;
        
        float s = (1.0-abs(simplex3d(currentPoint)));
        s=s*s*s;
        s=smoothstep(0.1,2.0, s);
        
        float stepf = ((maxStepsf - i)/maxStepsf);
        s *= stepf;
        vec3 light = sin((currentPoint+vec3(time/10.0,time/13.0,time/15.0))/4.0)*0.5+1.0; //Yes we blow out the colour a little.
        total += light*s;
        currentDistance += stepSize;
    }
    return (total*(3.0/maxStepsf))*strike;
}

void main(void)
{
    // Normalized Pixel coordinates (from -0.5 to +0.5, center at 0,0)
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    // Normalized Mouse coordinates (from -0.5 to +0.5, center at 0,0)
    vec2 mouse = ((mouse*resolution.xy.xy-0.5*resolution.xy)/resolution.y);// - vec2(0.5,0.5)*(mouse*resolution.xy.w*0.1);
    //Snap to center on startup.
    //if(mouse*resolution.xy.x <= 1.0 && mouse*resolution.xy.y <= 1.0) {
    //    mouse = vec2(0.0,0.0);
    //}

    // -- 1st person cammera
    vec3 forward = vec3(
        sin(mouse.x*PI),
        sin(mouse.y*PI),
        cos(mouse.x*PI)
    );
    camera camera = getCameraDirection(vec3(0.0,0.0,time), forward, 0.5);
    
    ray ray = getRay(uv, camera);
    vec3 colour = RayMarch(ray, RAY_MAX_DISTANCE, RAY_MAX_STEPS);
    float gamma = 0.8;
    colour = pow(colour, vec3(1.0/gamma));
    
    glFragColor = vec4(colour,1.0);

}
