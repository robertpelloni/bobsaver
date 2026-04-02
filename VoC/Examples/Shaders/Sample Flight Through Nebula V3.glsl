#version 420

// original https://www.shadertoy.com/view/tsK3Rd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// also see 
// voronoi  version, https://www.shadertoy.com/view/tdyGzK
// simplex version, https://www.shadertoy.com/view/WsG3zd
// box version, https://www.shadertoy.com/view/tsK3Rd

#define RAY_MAX_STEPS 100
#define RAY_MAX_DISTANCE 20.0

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

//Wrap around for id generation
float wrap(float x) {
    return mod289((34.0 * x + 1.0) * x);
}

float random2(in vec2 st) {
   return fract(sin(dot(st,vec2(12.9898,78.2333)))* 458.5453123);
}

float random3(in vec3 st) {
   return fract(sin(dot(st,vec3(12.9898,79.233,96.9723)))* 437.5453123);
}

//Quintic interpolation curve
vec3 quinticInterpolation(vec3 x) {
    return x*x*x*(x*(x*6.-15.)+10.);
}

float boxNoise(vec3 samplePoint) {
    vec3 pointI =floor(samplePoint);
    vec3 pointF = fract(samplePoint);
    
    float bbl = random3(pointI + vec3(0.0,0.0,0.0) );
    float bbr = random3(pointI + vec3(1.0,0.0,0.0) );
    float btl = random3(pointI + vec3(0.0,1.0,0.0) );
    float btr = random3(pointI + vec3(1.0,1.0,0.0) );
    
    float fbl = random3(pointI + vec3(0.0,0.0,1.0) );
    float fbr = random3(pointI + vec3(1.0,0.0,1.0) );
    float ftl = random3(pointI + vec3(0.0,1.0,1.0) );
    float ftr = random3(pointI + vec3(1.0,1.0,1.0) );
    
    //vec3 u =smoothstep(0.0,1.0,pointF);
    //vec3 u =quinticInterpolation(pointF);
    vec3 u =pointF;
    
    float bb = mix(bbl,bbr,u.x);
    float bt = mix(btl,btr,u.x);
    
    float b = mix(bb,bt,u.y);
    
    float fb = mix(fbl,fbr,u.x);
    float ft = mix(ftl,ftr,u.x);
    
    float f = mix(fb,ft,u.y);
    
    return mix(b,f,u.z);
}

vec3 RayMarch(ray ray, float maxDistance, int maxSteps)
{
    float maxStepsf = float(maxSteps);
    float stepSize = maxDistance/maxStepsf;
    vec3 total = vec3(0.0);
    float currentDistance = 1.0;
    
    float strike = 1.0+smoothstep(0.5,1.0,sin(ray.direction.z+time*20.0)*sin(ray.direction.x +time*30.0)*cos(ray.direction.y +time*40.0)*(wrap(time)/289.0));
    
    for(float i=0.0; i<maxStepsf; i++) {
        vec3 project = (ray.direction* currentDistance);
        //Add some offsets to hide the aligned features in the box noise.
        project.x +=sin(project.y*0.5);
        project.y +=cos(project.z*0.2);
        project.z +=cos(project.x*0.3);
        vec3 currentPoint = ray.origin + project  ;
        
        float stepf = ((maxStepsf - i)/maxStepsf);
        float s = 1.0-(abs(boxNoise(currentPoint)-0.5)*2.0);
        s=smoothstep(0.7,1.1, s);

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

    vec3 cloudColour = RayMarch(ray, RAY_MAX_DISTANCE, RAY_MAX_STEPS);
    
    //Stars
    float starBase = random3(floor(ray.direction*resolution.x*0.5));
    float stars = smoothstep(0.1,1.0,fract(starBase*starBase*10000000000.0));
    stars *= clamp(pow(length(cloudColour)+0.2,2.0),0.0,1.0)*0.7;
    
    //Sun
//    vec3 sunDir = normalize(vec3(1.0,1.0,1.0));
    vec2 facing = vec2(time*0.01+1.2,time*0.03+0.3);
    vec3 sunDir = normalize(vec3(
        sin(facing.x),
        sin(facing.y),
        cos(facing.x)+sin(facing.y)
     ));
    float sunBright = clamp(dot(sunDir,ray.direction),0.0,1.0);
    sunBright = pow(sunBright,5.0)* 2.0; //blow it right out
    vec3 suncolour = vec3(0.9, 0.85, 0.8); //nice orange/yellow

    vec3 colour = mix(cloudColour,suncolour,max(suncolour*sunBright, stars));//mix it in, causes nice 'shadows'
   //vec3 colour=vec3(stars); 
    //Harsh gamma gives it a nicer look.
    float gamma = 0.8;
    colour = pow(colour, vec3(1.0/gamma));
    glFragColor = vec4(colour,1.0);
}
