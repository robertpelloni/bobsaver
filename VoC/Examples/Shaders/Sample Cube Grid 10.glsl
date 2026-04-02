#version 420

// original https://www.shadertoy.com/view/MsGcDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Shape sizes.
    //Should fit into a 2x2x2 box.
const float CUBE_LENGTH = 0.25;
const vec3 RECT_DIMENSIONS = vec3(CUBE_LENGTH);
const float SPHERE_RADIUS = 0.1;
const vec2 TORUS_RADII = vec2(0.4, 0.2); //inner and outer radii

//Camera.
const float CAMERA_DISTANCE = 2.0;
const float CAMERA_ROTATION_TIMESCALE = 0.25; //2pi = one second per revolution.
const vec3 CAMERA_PAN_TIMESCALE = vec3(0.0, 1.0, 1.0);

//Raymarch.
const float RAY_FUZZ_TIMESCALE = 1.0; //distorts the ray based on time.
const float RAY_FUZZ_MIN = 0.2, RAY_FUZZ_MAX = 1.0; //1.0 = exact.
const int RAYMARCH_STEPS = 32; //raymarch steps. fewer = blurrier.

/// Time ///

/** Sine oscillation.
    x : Input value, in radians.
    ymin, ymax : Minimum and maximum output values.
 */
float oscillate(float x, float ymin, float ymax)
{
    float range = ymax - ymin;
    float x1 = (sin(x)+1.0)/2.0; 
    return ymin + range*x1;
}

/// Geometry ///

//Signed distance to a box.
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

//Sphere
float sdSphere( vec3 p, float radius )
{
    return length(p) - radius; //sphere
}

//Torus around the y axis.
    //Another torus function is here: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdTorus(vec3 p, float r0, float r1)
{
    float c = (r0 + r1) / 2.0; //ring radius
    float a = abs(r0 - r1) / 2.0; //thickness; tube radius
    
    float d0 = abs(c - length(p.xz)); // Horizontal distance from ring.
    vec2 point = vec2(d0, p.y); //Project to cross-plane.
    return length(point) - a; //Distance from ring.
}

/// Marching ///

/** Wraps 3-space "into" a 1x1x1 box, and draws a shape inside it.
    This gives the repetition effect. It's not that there are infinitely many cubes, but that it's the same cube being seen infinitely many times.
    
    Returns distance from p to the shape, measured within the 1x1x1 box.
 */
float map(vec3 p)
{
    //Take the fractional parts of the coordinates.
        //[math] This defines a quotient of R^3 onto T^3.
    //Then send [0,1) to [-1,1), so the shape is centered at 0.
        //Note: This doubles distances and lengths, because [-1,1) is twice as big as [0,1).
        //Notation: [x,y) means "numbers between x and y, including x but not y".
    vec3 q = fract(p) * 2.0 - 1.0;
    
    //return 0.5*sdTorus(q, TORUS_RADII[0], TORUS_RADII[1]);
    //return 0.5*sdSphere(q, SPHERE_RADIUS); //sphere
    return 0.5*sdBox(q, RECT_DIMENSIONS); //rectangle
}

/** March from `origin` in the direction `ray`.
    
    `ray` is possibly not length 1, which would have these effects:
    1. The apparent distance will be wrong, making the object brighter or darker due to distance fog. For example, if the ray is length 2, the returned distance will be half the real distance.
    2. The algorithm may overshoot or undershoot at each step, causing it to not reach the target or overshoot the target.
 */
float trace(vec3 origin, vec3 ray)
{
    float t = 0.0;  //Estimated distance to object.
    for (int i = 0; i < RAYMARCH_STEPS; ++i)
    {
        vec3 p = origin + ray * t;
        float d = map(p);
        t += d;
    }
    return t;
}

void main(void)
{
    // [0, 1] screen coordinates.
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    // [-1, 1] screen coordinates.
    uv = uv * 2.0 - 1.0;
    // Scale x to aspect ratio.
    uv.x *= resolution.x / resolution.y;
    
    //Camera:
    //Puts screen at distance from camera, and r points to current pixel.
    vec3 r = normalize(vec3(uv, CAMERA_DISTANCE));
    //Rotate camera around y-axis over time.
    float the = time * CAMERA_ROTATION_TIMESCALE;
    r.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
    //Pan camera over time.
    vec3 o = time * CAMERA_PAN_TIMESCALE;
    
    //Distortion factor for the ray.
    float st = oscillate(time*RAY_FUZZ_TIMESCALE, RAY_FUZZ_MIN, RAY_FUZZ_MAX);
    
    //Distance to a visible object from this ray.
    float t = trace(o, r * st);
    
    //Distance fog.
    float fog = 1.0 / (1.0 + t * t * 0.1);
    vec3 fc = vec3(fog * 2.0);
    
    //Tint based on distortion factor.
    vec3 tint = vec3(st - 0.5,st,st + 0.5);
    
    glFragColor = vec4(fc * tint, 1.0);
}
