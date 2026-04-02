#version 420

// original https://www.shadertoy.com/view/tdyGzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define RAY_MAX_STEPS 30
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
       
camera getCameraLookAt(vec3 origin, vec3 lookAt, float zoom) {
   camera camera;
   camera.origin = origin;
   camera.forward = normalize(lookAt - camera.origin);
   camera.right = cross(vec3(0.0,1.0,0.0), camera.forward);
   camera.up = cross(camera.forward, camera.right);
   camera.zoom = zoom;
   return camera;
}

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

vec3 generateId(vec3 x) {
    vec3 w;
    w.x=wrap(x.x);
    w.y=wrap(w.x + x.y);
    w.z=wrap(w.y + x.z);
    return w;
}

vec3 idToPoint(vec3 id) {
    vec3 point;
    point.x = fract(id.z * K) - Ko;
    //point.y = mod(floor(id.z * K),7.0) * K - Ko;
    point.y = floor(id.z * K) * K - Ko;
    point.z = floor(id.z * K2) * Kz - Kzo;
    return point;
}

float voronoiNoiseDistance(vec3 samplePoint){
    vec3 pointI = mod(floor(samplePoint),289.0);
    vec3 pointF = fract(samplePoint);

    float minDistance= 9999.0;
    vec3 id;
    vec3 offset;
    
    for(float i=-1.0;i<=1.0;i++) {
        offset.x = i;
        id.x= wrap(pointI.x + i);
        for(float j=-1.0;j<=1.0;j++) {
            offset.y=j;
            id.y = wrap(id.x + pointI.y + j);
            for(float k=-1.0;k<=1.0;k++) {
                offset.z=k;
                id.z = wrap(id.y + pointI.z + k);
                vec3 pointFract = fract(idToPoint(id));
                vec3 pointPos = pointFract + offset;
                vec3 dPosition = pointF - pointPos;
                float squareDistance = dot(dPosition,dPosition);
                minDistance = min(minDistance, squareDistance);
            }
        }
    }
    return  clamp(minDistance,0.0,1.0);
}

vec3 RayMarch(ray ray, float maxDistance, int maxSteps)
{
    float currentDistance = 0.1;
    float maxStepsf = float(maxSteps);
    float stepSize = maxDistance/maxStepsf;
    vec3 total = vec3(0.0);
    
    float strike = smoothstep(0.7,1.0,sin(ray.direction.x +time*50.0)*cos(ray.direction.y +time*55.0)*(wrap(time/2.0)/289.0));
    
    for(float i=0.0; i<maxStepsf; i++) {
        vec3 currentPoint = ray.origin + ray.direction * currentDistance;
        float s = voronoiNoiseDistance(currentPoint);
        s=smoothstep(0.1,1.0,s);
        float stepf = ((maxStepsf - i)/maxStepsf);
        s *= stepf;
        vec3 light = sin((currentPoint+vec3(time/10.0,time/13.0,time/15.0))/4.0)*0.5+1.0; //Yes we blow out the colour a little.
        total += light*s*(1.0 + strike);
        currentDistance += stepSize;
    }
    return total*(3.0/maxStepsf);
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
    vec3 forward = normalize(vec3(
        sin(mouse.x*PI),
        sin(mouse.y*PI),
        cos(mouse.x*PI)*cos(mouse.y*PI)));
    camera camera = getCameraDirection(vec3(0.0,0.0,time), forward, 0.5);
    
    ray ray = getRay(uv, camera);
    vec3 colour = RayMarch(ray, RAY_MAX_DISTANCE, RAY_MAX_STEPS);
    float gamma = 0.8;
    colour = pow(colour, vec3(1.0/gamma));
    
    glFragColor = vec4(colour,1.0);

    /*
    float s = voronoiNoiseDistance(vec3(uv.xy*10.0,time));
    s=pow(s, (5.0 + (uv.x*5.0)));
    glFragColor = vec4(vec3(s),1.0); 
*/
}
