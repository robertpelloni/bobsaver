#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3ljSzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.28318530718

/* --- */
// try hacking around with some of these

#define RENDER_PIXEL_WIDTH 2
#define RENDER_PIXEL_HEIGHT 2

#define DITHER_PIXEL_WIDTH 2
#define DITHER_PIXEL_HEIGHT 2
#define DITHER_CHANNEL_DEPTH 4

#define SKY_TOP vec3(0.8, 0.0, 0.3)
#define SKY_MID vec3(0.0, 0.0, 0.2)
#define SKY_BOT vec3(0.0, 0.7, 0.5)

#define MAX_ITERATIONS 200
#define EPSILON 0.005
/* --- */

vec3 cameraPos = vec3(0.0, -5.0, 0.75);
vec3 cameraDir = vec3(0.0, 1.0, 0.0);
vec3 cameraUp = vec3(0.0, 0.0, 1.0);
float cameraFovX = TAU * 0.28;

vec3 getCameraRay()
{
    vec2 normalizedCoord = gl_FragCoord.xy * 2.0 / resolution.xy - 1.0;
    normalizedCoord.y *= resolution.y / resolution.x;
    
    float cameraDepth = 1.0 / tan(cameraFovX / 2.0);
    
    vec3 cameraX = normalize(cross(cameraDir, cameraUp));
    vec3 cameraY = cross(cameraX, cameraDir);
    
    return normalize(cameraDepth*cameraDir + normalizedCoord.x*cameraX + normalizedCoord.y*cameraY);
}

vec4 sdUnion(vec4 sd1, vec4 sd2)
{
    if (sd1.w <= sd2.w) return sd1;
    else               return sd2;
}

vec4 sdSphere(vec3 s, float r)
{
    return vec4(normalize(s), length(s) - r);
}

vec4 sdHalfspace(vec3 p, vec3 n, float k)
{
    return vec4(n, dot(p, n) - k);
}

vec4 sdWorld(vec3 p)
{
    vec4 sd = vec4(10000000.0);
    float breathe = 1.0 + 0.15 * (1.0 + cos(time));
    sd = sdUnion(sd, sdSphere(p - breathe*vec3(-2.5, 0.0, 0.0), 1.0));
    sd = sdUnion(sd, sdSphere(p - breathe*vec3(-2.5, 1.5, 3.0), 1.5));
    sd = sdUnion(sd, sdSphere(p - breathe*vec3(5.0, 12.0, -1.0), 5.0));
    sd = sdUnion(sd, sdSphere(p - breathe*vec3(-2.0, 36.0, -10.0), 10.0));
    sd = sdUnion(sd, sdHalfspace(p - vec3(0.0, 10.0, -20.0), normalize(vec3(sin(time), 0.2*cos(time), 1.5)), -5.0));
    return sd;
}

float getRayHit(inout vec3 p, inout vec3 v)
{
    for (int i = 0; i < MAX_ITERATIONS; i++)
    {
        vec4 sd = sdWorld(p);
        p += sd.w * v;
        if (sd.w <= EPSILON) 
        {
            v = reflect(v, vec3(sd));
            p += v * 0.01;
            return 1.0;
        }
    }
    return 0.0;
}

vec3 getSkyColor(vec3 v)
{
    if (v.z > 0.0) {
        return mix(SKY_TOP, SKY_MID, 1.0-v.z*2.5);
    } else {
        return mix(SKY_BOT, SKY_MID, 1.0+v.z*2.5);
    }
}

vec3 getRayColor(vec3 p, vec3 v)
{
    vec3 skyColor;
    float factor = 1.0;
    int reflections;
    for (reflections = 0; reflections < 5; reflections++)
    {
        skyColor = getSkyColor(v - vec3(0.0, 0.0, 0.3 - 0.15*cos(1.1*time)));
        if (getRayHit(p, v) > 0.0) {
            factor *= 0.6;
        } else {
            break;
        }
    }
    return skyColor * factor;
}

mat4 dither4Bayer = mat4(
    0.0, 12.0, 3.0, 15.0,
    8.0, 4.0, 11.0, 7.0,
    2.0, 14.0, 1.0, 13.0,
       10.0, 6.0, 9.0, 5.0
) / 16.0;

float dither4Scalar(vec2 position, float value)
{
    float bias = dither4Bayer[(int(position.x)/DITHER_PIXEL_WIDTH)%4]
                             [(int(position.y)/DITHER_PIXEL_HEIGHT)%4];
    return floor(bias + value*float(DITHER_CHANNEL_DEPTH-1)) / float(DITHER_CHANNEL_DEPTH-1);
}

vec3 dither4(vec2 position, vec3 color)
{
    return vec3(dither4Scalar(position, color.r),
                dither4Scalar(position, color.g), 
                dither4Scalar(position, color.b));
}

void main(void)
{
    //cameraDir = vec3(sin(time), cos(time), 0.0);
    ivec2 pixelation = ivec2(RENDER_PIXEL_WIDTH, RENDER_PIXEL_HEIGHT);
    vec2 pixelatedCoord = vec2((ivec2(gl_FragCoord.xy) / pixelation) * pixelation);
    pixelatedCoord += vec2(pixelation) / 2.0;
    cameraPos.y = -7.0 + cos(0.9*time)*3.0;
    cameraPos.x = sin(0.13*time)*5.0;
    glFragColor.rgb = getRayColor(cameraPos, getCameraRay());
    glFragColor.rgb = dither4(gl_FragCoord.xy, glFragColor.rgb);
    glFragColor.a = 1.0;
    //glFragColor = vec4(getCameraRay(gl_FragCoord.xy),1.0);
}
