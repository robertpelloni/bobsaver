#version 420

// original https://www.shadertoy.com/view/lttXRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SNOW_INTENSITY .05
#define SNOW_FALL_SPEED 1.0

float map(vec3 p, float time)
{
    vec3 q = fract(p) * 2.0 - 1.0;
    
    // length of the point minus the radius of the sphere...
    float radius = 0.25;
    
    // spheres get bigger and smaller depending on time
    radius = (sin(time)*.05 + .1);
    
    return length(q) - radius;  //0.25;
}

float trace(vec3 origin, vec3 ray, float time)
{
    float t = 0.0;
    for(int i = 0; i < 32; i++)
    {
        vec3 p = origin + ray*t;
        float d = map(p, time);
        t+= d * 0.5;
    }
    return t;
}

float snowMap(vec3 p)
{
    vec3 q = fract(p) * 2.0 - 1.0;
    
    // length of the point minus the radius of the sphere...
    float radius = 0.25;
    
    // spheres get bigger and smaller depending on time
    radius = SNOW_INTENSITY;

    return length(q) - radius;  //0.25;
}

float snowTrace(vec3 origin, vec3 ray)
{
    float t = 0.0;
    for(int i = 0; i < 32; i++)
    {
        vec3 p = origin + ray*t;
        float d = snowMap(p);
        t+= d * 0.5;
    }
    return t;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv*2.0 - 1.0; // between -1 and +1
    
    uv.x *= resolution.x / resolution.y;
    
    vec3 ray = normalize(vec3(uv, 1.0));
        
    vec3 origin = vec3(0., 0.7, 0.); // camera location
    
    // GREEN LIGHTS
    // rotation
    float the = .7;
    ray.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));

    float t = trace(origin, ray, time);
    
    float fog1 = 1.0/ (1. + t*t*0.1);
    
    // RED LIGHTS
    // rotation
    the = .2;
    ray.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
    origin = vec3(0., 0.4, 0.);

    t = trace(origin, ray, time + 1.5);
    
    float fog2 = 1.0/ (1. + t*t*0.1);
    
    // BLUE LIGHTS
    // rotation
    the = .4;
    ray.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
    origin = vec3(0., 0.2, 0.);
    
    t = trace(origin, ray, time + 3.5);
    
    float fog3 = 1.0/ (1. + t*t*0.1);
    
    
    // combine all of the colors
    vec3 fc = vec3(fog2, fog1,fog3);
    if(uv.y > 1. - 2.5*uv.x || uv.y > 1. + 2.5*uv.x)
    {
        fc = vec3(0.);
    }
    
    // now let's do the 2 snow things
    uv = gl_FragCoord.xy / resolution.xy;
    uv = uv*2.0 - 1.0; // between -1 and +1
    uv.x *= resolution.x / resolution.y;
    
    //snow 1
    ray = normalize(vec3(uv, 1.0));
    
    the = 1.0;
    ray.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
    
    origin = vec3(0., time*.75*SNOW_FALL_SPEED, time*.75*SNOW_FALL_SPEED); // camera location
    
    t = snowTrace(origin, ray);
    
    float fogSnow1 = 1.0/ (1. + t*t*0.1);
    
    //snow 2
    ray = normalize(vec3(uv, 1.0));
    
    the = -2.0;
    ray.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
    
    origin = vec3(0., time*0.5*SNOW_FALL_SPEED, time*0.5*SNOW_FALL_SPEED); // camera location
    
    t = snowTrace(origin, ray);
    
    float fogSnow2 = 1.0/ (1. + t*t*0.1);
    
    
    
    vec3 snowFogColor = vec3(fogSnow1) + vec3(fogSnow2);
    
    
    fc += snowFogColor;
    
    
    
    
    glFragColor = vec4(fc,1.0);
}
