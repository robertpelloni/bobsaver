#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ltdBR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* By Andrew "teessider" Bell
Made for my talk at Digital Art Conference Frankfurt 2018.
Link to talk slides/youtube will come soon :)
This is based on the dac-fra.com website graphic.

Some improvements I would like to make (After the talk):
- Floating Pyramid inside shapes
- DAC-FRA text
- Make the Floating Pyramid spin a cool way!

*/

// A couple of helper macros - coming from HLSL ;) and others too!
#define mad(m, a, b) m*a+b
#define rcp(x) 1.0/x
#define saturate(a) clamp( a, 0.0, 1.0 ) // It seems that (not sure if this is a WebGL thing) the whitespace matters in macros!
#define testMask(x) vec3( x )

#define PI 3.1415
#define TAU 6.2831

// RAYMARCH LOOP PARAMS
#define MAX_STEPS 64
#define MAX_DIST 30.0
#define EPSILON 0.001
////

// OBJECT IDs
#define BACKGROUND -1.0
#define FLOOR 1.0
#define PYRAMID 2.0

#define UV_SCALE 150.0
#define SPEED 6.0
#define GRID_SIZE 0.75

////// IQ STUFF
// IQ DISTANCE FUNCTIONS
float sdSphere(vec3 point, float radius)
{
    return length(point) - radius;
}

float sdPlane2(vec3 point, vec4 normal)
{
    return dot(point, normal.xyz) + normal.w;
}

float sdBox( vec3 point, vec3 b )
{
    vec3 d = abs(point) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float sdPryamid4(vec3 p, vec3 h ) // h = { cos a, sin a, height }
{
    // Tetrahedron = Octahedron - Cube
    float box = sdBox( p - vec3(0,-2.0*h.z,0), vec3(2.0*h.z) );
 
    float d = 0.0;
    d = max( d, abs( dot(p, vec3( -h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, vec3(  h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, vec3(  0, h.y, h.x )) ));
    d = max( d, abs( dot(p, vec3(  0, h.y,-h.x )) ));
    float octa = d - h.z;
    //return max(-box,octa); // Subtraction
    return max(box,octa); // Subtraction, opposite
 }

// Operator - Union
// Includes support for the IDs
vec2 opU(vec2 d1, vec2 d2)
{
    // the < operator can only deal with scalars so just the DF is used. NEED IT LIKE THIS BECAUSE OF IDs
    return(d1.x < d2.x) ? d1 : d2;
}

// More info here: http://iquilezles.org/www/articles/voronoise/voronoise.htm
vec3 hash3( vec2 p )
{
    vec3 q = vec3( dot(p,vec2(127.1,311.7)), 
                   dot(p,vec2(269.5,183.3)), 
                   dot(p,vec2(419.2,371.9)) );
    return fract(sin(q)*43758.5453);
}

float iqnoise( in vec2 x, float u, float v )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
        
    float k = 1.0+63.0*pow(1.0-v,4.0);
    
    float va = 0.0;
    float wt = 0.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = vec2( float(i),float(j) );
        vec3 o = hash3( p + g )*vec3(u,u,1.0);
        vec2 r = g - f + o.xy;
        float d = dot(r,r);
        float ww = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), k );
        va += o.z*ww;
        wt += ww;
    }
    
    return va/wt;
}
////// END IQ STUFF

// This is where all the Distance Fields (DFs) are added into the scene
// also know as map() in iq's shaders :D
vec2 scene(in vec3 point)
{
    // To make the sphere move along with the camera, for now it has the same speed added to it plus an offset
    // Z is depth in this case ;)
    vec2 pyramid = vec2(sdPryamid4(point - vec3(0.0, sin(time*PI)+4.0, time*20.0+1.0), vec3(0.65,0.33,1.0)), PYRAMID);

    // vec2 sphere1 = vec2(sdSphere(point - vec3(0.0, 5.0, 4.0), 3.0), 1.0);
    // // LOOK FOR SCALING/DISAPPEARING
    // vec2 sphere2 = vec2(sdSphere(point - vec3(0.0, 6.0, 16.0), fract(time* 0.5)+6.0), 2.0);
    // return opU(sphere1, sphere2);

    // FOR TESTING
    vec2 sphere1 = vec2(sdSphere(point-vec3(0.0, sin(time*PI)+4.0, time*20.0+15.0), 8.0), PYRAMID);

    float mountainsHeight = mix(1.0, smoothstep(-.05, 1., iqnoise(point.xz*.75, 1.0, 1.0)*.25), saturate(abs(point.x)-3.0));
    vec2 floor = vec2(sdPlane2(point, vec4(0.0, mountainsHeight, 0.0, 0.0)), FLOOR);

    vec2 result = opU(floor, pyramid);

    return result;
}

//// MORE IQ STUFF
// http://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
// Normals can be estimated from a gradient!
vec3 calculateNormal(in vec3 point)
{
    vec2 h = vec2(EPSILON, 0.0); // Some small value(s)
    return normalize(vec3(scene(point + h.xyy).x - scene(point - h.xyy).x,
                          scene(point + h.yxy).x - scene(point - h.yxy).x,
                          scene(point + h.yyx).x - scene(point - h.yyx).x));
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = scene( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return saturate(1.0 - 3.0*occ);    
}
//// END IQ STUFF

vec2 raymarch(in vec3 origin, in vec3 ray)
{
    float t = 0.0; // t is the clipping plane where anything below this is removed.
    float id = -1.0; // For the Background
    for (int i = 0; i < MAX_STEPS; i++)
    {
        vec2 dist = scene(origin + ray * t);
        if (dist.x < EPSILON)
        {
            break; // We are inside the surface.
        }
        // Move along the ray in constant steps
        t += dist.x;
        // Since each element has an ID, we want that there too!
        id = dist.y;

        if (t >= MAX_DIST)
        {
            id = BACKGROUND;
            return vec2(MAX_DIST, id); //We are too far away!
        }
    }
    return vec2(t, id);
}

vec4 render(in vec3 rayOrigin, in vec3 rayDirection)
{
    // INITIALISE finalColor so it be used later and fed into 
    vec3 finalColor = vec3(0.0);

    // BACKGROUND
    vec3 bgColor = mix(vec3(0.345,0.212,0.388), vec3(0.145,0.357,0.612), saturate(rayDirection.x));
    float stars = smoothstep(0.745, 1.0, iqnoise(rayDirection.xy*UV_SCALE, 1.0, 1.0)); // ORIGINALLY USED UVs BUT USING RAY DIRECTION IS WAY COOLER
    vec3 scene_background = 0.2*stars + bgColor;

    // SCENE THAT ISNT THE BACKGROUND (BUT BEFORE "POST PROCESS" STUFF)
    vec2 result = raymarch(rayOrigin, rayDirection);
    if (result.y > BACKGROUND)
    {
        // if (result.y == PYRAMID)
        // {
        //     // LOOK FOR SCALING/DISAPPEARING
        //     result.x *= result.y*(fract(time));
        // }
        vec3 point = result.x * rayDirection + rayOrigin;
        vec3 normal = calculateNormal(point);

        vec3 lightDir = normalize(vec3(1.0, 1.0, -4.0));
        float nDotL = saturate(dot(normal, lightDir));

        if (result.y == FLOOR)
        {
            vec2 gridUVs = mod(point.xz, 1.5); //GRID SIZE
            gridUVs = round(mad(GRID_SIZE, 0.5, gridUVs)); // GRID LINE SIZE
            float grid = saturate(mad(-gridUVs.x, gridUVs.y, 1.0));

            vec3 gridColor = vec3(0.345,0.212,0.388);

            float fog = saturate(saturate(1.0-exp(-result.x*0.1)-0.8)*8.0);

            finalColor = mix(gridColor+scene_background, scene_background, saturate(max(fog, 1.-grid)));
            finalColor *= sqrt(calcAO(point, normal)); // Only want AO on FLOOR but not as intense
        }
        else
        {
            /// CURRENTLY ONLY FOR PYRAMID
            vec3 sunColor = vec3(1.0, 0.5, 0.0);
            vec3 ambientColor = vec3(0.0, 0.0, 0.0);
            //finalColor = saturate(mix(nDotL * sunColor, finalColor, 1.0-exp(-result.x*0.1))); // SIMPLE FOG TEST
            finalColor = pow(saturate(nDotL * sunColor +ambientColor), vec3(0.4545));
            //finalColor = -normal.zzz; // FOR INSIDE MASK EVENTUALLY
            //finalColor = (result.yyy-1.5)*fract(-time*0.5)*2.5-0.1; //PULSING TEST
        }
    }
    else
    {
        finalColor = scene_background;
    }
    return vec4(finalColor, 1.0);
}

void main(void)
{
    // Remap from [0-1] to [-1-1] so that 0 is the middle point in
    // Also apply aspect ratio correction too
    vec2 orig_uv = gl_FragCoord.xy / resolution.xy;
    vec2 uv = mad(2.0, orig_uv, -1.0);
    uv.x *= resolution.x / resolution.y;
    
    // RAYMARCH STUFF - THE SCENE
    vec3 ray_orig = vec3(0.0, 3.0, -5.0);
    ray_orig += vec3(0.0, 0.0, time*20.);
    vec3 ray_dir = normalize(vec3(uv, 1.16)); // ray_dir.z is FOV
    vec3 sceneColor = render(ray_orig, ray_dir).xyz;

    // SCANLINES
    vec3 linesColor = vec3(0.0, 0.04, 0.08);
    float linesAlpha = sin(uv.y * UV_SCALE + time * SPEED);
    sceneColor = (linesColor * linesAlpha) + sceneColor;

    // VIGNETTE
    float vignette = sqrt(orig_uv.x * orig_uv.y *(1.0-orig_uv.x) * (1.0-orig_uv.y) * 16.0);
    sceneColor *= vignette;
    glFragColor = vec4(sceneColor, 1.0);
}
