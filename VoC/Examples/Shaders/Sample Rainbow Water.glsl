#version 420

// original https://www.shadertoy.com/view/WlfXzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Copyright (c) 2019-07-02 - 2019-07-17 by Angelo Logahd
//Portfolio: https://angelologahd.wixsite.com/portfolio
//My orginal version: http://glslsandbox.com/e#55788.0

//Latest version of my water with sky shader:
//Copyright (c) 2019-06-23 - 2019-07-17 by Angelo Logahd
//http://glslsandbox.com/e#56195.1

const float PI         = 3.1415;
float EPSILON_NRM    = 0.001;

const vec3 up = vec3(0.0, 1.0, 0.0);

#define true                              1
#define false                             0

#define saturate(x)                        clamp(x, 0.0, 1.0)
#define mul3x(x)                         x * x * x

#define SIMULATE                         0
#define SIMULATE2x                        1
#define SIMULATE3x                        2
#define SIMULATE4x                        3
#define SIMULATE5x                        4
#define PAUSED                            5
#define SLOW_MOTION                        6

#define WAVES_WATER                        0
#define CALM_WATER                        1

#define SIMULATE_MODE                    SIMULATE
#define WATER_TYPE                        CALM_WATER
#define RAINBOW_WATER                    true
#define FANTASY_WATER_PATH                false
#define FLIP_WATER_AND_SKY                false
#define DAY_AND_NIGHT                    false
#define SUN_LIGHT                        true

//...........................................................
//            Weathers
//...........................................................
#define    RAIN                            true
#define RAINBOW                            true

#if RAINBOW
#define RAINBOW_START_Y                    0.0

const float RAINBOW_BRIGHTNESS          = 1.0;
const float RAINBOW_INTENSITY           = 0.30;
const vec3  RAINBOW_COLOR_RANGE         = vec3(50.0, 53.0, 56.0);  // The angle for red, green and blue
vec3 RAINBOW_POS                        = vec3(4.5, 0.0, 0.5);
vec3 RAINBOW_DIR                         = vec3(-0.2, -0.1, 0.0);
    
vec3 rainbow_pos;
vec3 rainbow_camera_dir;
vec3 rainbow_up; 
vec3 rainbow_vertical;
vec3 rainbow_w;
#endif
//...........................................................

//...........................................................
//            Post Processing
//...........................................................
#define APPLY_LUMINANCE                    true
#define APPLY_TONEMAP                    true
#define APPLY_GAMMA_CORRECTION            true

const float INTENSITY                    = 1.0;
const float CONTRAST                    = 1.0;

#if APPLY_TONEMAP
const float TONEMAP_EXPOSURE            = 1.5;
#endif

#if APPLY_GAMMA_CORRECTION
const float GAMMA                        = 2.2;
#endif
//...........................................................

//Day and night properties
#if DAY_AND_NIGHT
#define DAY_AND_NIGHT_TIME                0.1
#define DAY_AND_NIGHT_MIN_BRIGHTNESS    0.2
#define DAY_AND_NIGHT_MAX_BRIGHTNESS    1.0
#endif

//Sun light properties
#if SUN_LIGHT
vec3  SEA_SUN_DIRECTION                    = vec3(0.0, -1.0, -0.5);
vec3  SEA_SUN_COLOR                     = vec3(1.0, 1.0, 1.0);    //vec3(1.0, 1.0, 0.0) to use a yellow reflection color
float SEA_SUN_DIFFUSE                      = 0.65; 
vec3  SEA_SUN_SPECULAR                  = vec3(0.65);
#endif

//Geometry / Fragment properties
const int SEA_GEOMETRY_ITERATIONS       = 8;
const int SEA_FRAGMENT_ITERATIONS       = 10;

// sea base properties
const vec3  SEA_BASE_COLOR                 = vec3(0.15, 0.19, 0.25);
const vec3  SEA_WATER_COLOR             = vec3(0.1, 0.1, 0.15);
const vec3  SEA_ORI                        = vec3(0.0, 3.5, 0.0);        
const float SEA_HEIGHT                    = 0.9;
const float SEA_SPEED                     = 1.6;
const float SEA_FREQ                      = 0.15;
const float SEA_GEOMETRY_FREQ_MUL        = 1.9;
const float SEA_GEOMETRY_AMPLITUDE_MUL     = 0.22;
const float SEA_FREQ_MUL                  = 2.0;
const float SEA_AMPLITUDE_MUL             = 0.22;
const float SEA_REFRACTION_MUL_VALUE    = 0.12;
const float SEA_ATTENUATION             = 0.001;
const float SEA_ATTENUATION_MUL_FACTOR  = 0.18;
const float SEA_CHOPPY                    = 5.2;
const float SEA_CHOPPY_MIX_VALUE        = 1.0;
const float SEA_CHOPPY_MIX_FACTOR        = 0.4;

// sea heightmap
const int HEIGHTMAP_NUM_STEPS             = 20;

// sea direction
const float SEA_DIR_Z_SCALE             = 0.02;

//.................................................
//         sea PBR properties
//.................................................
const float SEA_SPECULAR_FACTOR            = 60.0;
const float FRESNEL_POW_FACTOR            = 3.0;
const float FRESNEL_MUL_FACTOR            = 0.65;
const float DIFFUSE_POW_FACTOR            = 80.0;
//.................................................

const float SEA_PAUSED_SPEED            = 0.0;
const float SEA_SLOWMOTION_SPEED        = 0.5;

#if RAINBOW_WATER
const float RAINBOW_WATER_SATURATION    = 0.35;
const float RAINBOW_WATER_LIGHTNESS        = 0.1; //0.2
const float RAINBOW_WATER_SPEED         = 0.1;
#endif

#if FANTASY_WATER_PATH
const float UV_START_X                    = -5.0;
const float UV_END_X                    =  5.0;
#endif

mat2 octave_matrix                         = mat2(1.6, 1.2, -1.2, 1.6);

float SEA_CURRENT_TIME                    = 0.0;

//Color mixing
const float SMOOTH_MIX_Y                = -1.2; 
const float MIX_SEA_AND_SKY_FACTOR        = 0.11;
const vec3  COLOR_GRADING                = vec3(0.0, 0.0, 0.01);

//..................................................................
//                Fog
//..................................................................
#define ALWAYS_FOG            0
#define NEVER_FOG            1

#define FOG_MODE                NEVER_FOG
const vec3  FOG_COLOR              = vec3(0.15, 0.15, 0.15);
const float FOG_START             = 0.04;
const float FOG_END             = 500.0;
const float FOG_DENSITY         = 0.2;
//..................................................................

vec3 hsv(float hue, float saturation, float value)
{
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(hue) + t.xyz) * 6.0 - vec3(t.w));
    return value * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), saturation);
}

float rand(float n)
{
    return fract(sin(n) * 43758.5453123);
}

float hash(vec2 p)
{    
    return rand(dot(p, vec2(12.9898, 78.233)));
}

vec2 _smoothstep(in vec2 p)
{
    vec2 f = fract(p);
    return f * f * (3.0 - 2.0 * f);
}

vec3 _smoothstep(in vec3 p)
{
     return p * p * 3.0 - 2.0 * mul3x(p);
}

float noise(in vec2 p) 
{
    vec2 i = floor(p);    
    vec2 sp = _smoothstep(p);
    return -1.0 + 2.0 * mix(mix(hash(i + vec2(0.0, 0.0)), 
                                hash(i + vec2(1.0, 0.0)), sp.x),
                            mix(hash(i + vec2(0.0, 1.0)), 
                                hash(i + vec2(1.0, 1.0)), sp.x), sp.y);
}

vec3 sky(vec3 e) 
{
    e.y = max(e.y, 0.0);
    vec3 ret;
    ret.x = pow(1.0 - e.y, 2.0) * 2.5;
    ret.y = 1.0 - e.y;
    ret.z = 0.8;
    return ret;
}

float sea_octave(vec2 uv, float choppy) 
{    
    #if WATER_TYPE == WAVES_WATER 
    uv += noise(uv);
    vec2 wv = 1.0 - abs(sin(uv));   
    wv = mix(wv, abs(cos(uv)), wv);
    return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy);
    #elif WATER_TYPE == CALM_WATER
    //Author: Angelo Logahd 
    //2019-06-29
    float noise = noise(uv);
    float x = cos(noise);
    float y = sin(noise);
    return pow(pow(abs(x * y), 0.65), choppy);
    #endif
}

float sea_geometry_map(vec3 p) 
{
    #if WATER_TYPE == WAVES_WATER
    vec2 uv = p.xz * vec2(0.85, 1.0);
    
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    
    float d = 0.0;
    float h = 0.0;    
    for (int i = 0; i < SEA_GEOMETRY_ITERATIONS; ++i) 
    {   
        #if FANTASY_WATER_PATH
           if (uv.x > UV_START_X && uv.x < UV_END_X)
        {
            continue;
        }
        #endif

        d =  sea_octave((uv + SEA_CURRENT_TIME) * freq, choppy);
        d += sea_octave((uv - SEA_CURRENT_TIME) * freq, choppy);
        h += d * amp; 
        
        freq *= SEA_GEOMETRY_FREQ_MUL; 
        amp  *= SEA_GEOMETRY_AMPLITUDE_MUL;
        
        choppy = mix(choppy, SEA_CHOPPY_MIX_VALUE, SEA_CHOPPY_MIX_FACTOR);
        
        uv *= octave_matrix; 
    }
    return p.y - h;
    #else
    return p.y;
    #endif
}

float sea_fragment_map(vec3 p) 
{
    vec2 uv = p.xz * vec2(0.85, 1.0); 
    
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;  
    float choppy = SEA_CHOPPY;
    
    float d = 0.0;
    float h = 0.0;    
    for(int i = 0; i < SEA_FRAGMENT_ITERATIONS; ++i) 
    {        
        d =  sea_octave((uv + SEA_CURRENT_TIME) * freq, choppy);
        d += sea_octave((uv - SEA_CURRENT_TIME) * freq, choppy); 
        h += d * amp;
    
        freq *= SEA_FREQ_MUL; 
        amp  *= SEA_AMPLITUDE_MUL;
    
        choppy = mix(choppy, SEA_CHOPPY_MIX_VALUE, SEA_CHOPPY_MIX_FACTOR);
    
        uv *= octave_matrix;
    }
    return p.y - h;
}

float diffuse(vec3 normal, vec3 light, float powFactor) 
{
    return pow(dot(normal, light) * 0.4 + 0.6, powFactor);
}

vec3 normal(vec3 p, vec3 dist) 
{
    float eps = dot(dist, dist) * EPSILON_NRM;
    vec3 n;
    n.y = sea_fragment_map(p); 
    n = vec3(sea_fragment_map(vec3(p.x + eps, p.y, p.z)) - n.y,
         sea_fragment_map(vec3(p.x, p.y, p.z + eps)) - n.y,
         eps);
    return normalize(n);
}

float specular(vec3 eye, vec3 normal, vec3 light) 
{    
    float nrm = (SEA_SPECULAR_FACTOR + 8.0) / (PI * 8.0);
    return pow(max(dot(reflect(eye, normal), light), 0.0), SEA_SPECULAR_FACTOR) * nrm;
}

float fresnel(vec3 normal, vec3 eye) 
{  
    float fresnel = 1.0 - max(dot(normal, -eye), 0.0);
    fresnel = pow(fresnel, FRESNEL_POW_FACTOR) * FRESNEL_MUL_FACTOR;
    return fresnel;
}

vec3 sea(vec3 p, vec3 l, vec3 eye) 
{  
    vec3 dist = p - SEA_ORI;  
    vec3 normal = normal(p, dist);
    float diffuse = diffuse(normal, l, DIFFUSE_POW_FACTOR);
    float fresnel = fresnel(normal, eye);
    
    vec3 reflected = sky(reflect(eye, normal));    
    vec3 refracted = SEA_BASE_COLOR + diffuse * SEA_WATER_COLOR * SEA_REFRACTION_MUL_VALUE; 
    
    vec3 color = mix(refracted, reflected, fresnel);
    
    float atten = max(0.0, 1.0 - dot(dist, dist) * SEA_ATTENUATION) * SEA_ATTENUATION_MUL_FACTOR;
    color += SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * atten;
    
    color += vec3(specular(normal, l, eye));
    
    #if SUN_LIGHT
    vec3 sunDiffuseColor = max(dot(SEA_SUN_DIRECTION, normal), 0.0) * SEA_SUN_COLOR * SEA_SUN_DIFFUSE;
    vec3 reflection = normalize(reflect(-SEA_SUN_DIRECTION, normal));
    float direction = max(0.0, dot(eye, reflection));
    vec3 sunSpecular = direction * SEA_SUN_COLOR * SEA_SUN_SPECULAR;
    color = color + sunDiffuseColor + sunSpecular;
    #endif
    
    #if RAINBOW_WATER
    color += hsv((p.z * 0.3) - time * RAINBOW_WATER_SPEED, RAINBOW_WATER_SATURATION, RAINBOW_WATER_LIGHTNESS);
    #endif

    return color;
}

vec3 seaHeightMap(vec3 dir) 
{
    vec3 p = vec3(0.0);
    float x = 1000.0;
    
    if (sea_geometry_map(SEA_ORI + dir * x) > 0.0)
    {
        return p;
    }
    
    float mid = 0.0;
    float m = 0.0; 
    float heightMiddle = 0.0;
    for(int i = 0; i < HEIGHTMAP_NUM_STEPS; ++i) 
    {
        mid = mix(m, x, 0.5); 
        p = SEA_ORI + dir * mid;                   
        heightMiddle = sea_geometry_map(p);
        if (heightMiddle < 0.0) 
        {
            x = mid;
        } 
        else 
        {
            m = mid;
        }
    }
    
    return p;
}

vec3 fog(vec3 sceneColor, float dist)
{
    vec3 fragRGB = sceneColor;
    const float FogEnd   = FOG_END;
    const float FogStart = FOG_START;
    float distanceF = (FogEnd - dist) / (FogEnd - FogStart);
    float fogAmount = saturate(1.0 - exp(-distanceF * FOG_DENSITY));
    return mix(fragRGB, FOG_COLOR, fogAmount);
}

float rainHash(float p)
{
    vec2 p2 = fract(vec2(p) * vec2(0.16632, 0.17369));
    p2 += dot(p2.xy, p2.yx + 19.19);
    return fract(p2.x * p2.y);
}

float rainNoise(in vec2 x)
{
    vec2 p = floor(x);
    vec2 f = _smoothstep(x);
    float n = p.x + p.y * 57.0;
    return mix(mix(rainHash(n +  0.0), rainHash(n +  1.0), f.x),
               mix(rainHash(n + 57.0), rainHash(n + 58.0), f.x), f.y);
}

float rain(vec2 uv, vec2 xy)
{    
    float travelTime = (time * 0.7) + 0.1;
    
    float x1 = (0.5 + xy.x + 1.0) * 0.3;
    float y1 = 0.01;
    float x2 = travelTime * 0.5 + xy.x * 0.2;
    float y2 = travelTime * 0.2;
    
    vec2 st = uv * vec2(x1, y1) + vec2(x2, y2);
    
    float rain = 0.1;  
    float f = rainNoise(st * 200.5) * rainNoise(st * 125.5);  
    f = clamp(pow(abs(f), 20.0) * 1.5 * (rain * rain * 125.0), 0.0, 0.1);
    return f;
}

vec3 rainbowColor(in vec3 ray_dir) 
{ 
    RAINBOW_DIR = normalize(RAINBOW_DIR);   
        
    float theta = degrees(acos(dot(RAINBOW_DIR, ray_dir)));
    vec3 nd = clamp(1.0 - abs((RAINBOW_COLOR_RANGE - theta) * 0.2), 0.0, 1.0);
    vec3 color = _smoothstep(nd) * RAINBOW_INTENSITY;
    
    return color * max((RAINBOW_BRIGHTNESS - 0.75) * 1.5, 0.0);
}

void rainbowSetup()
{
    rainbow_pos =  RAINBOW_POS;
    rainbow_w   = -normalize(-rainbow_pos);
    rainbow_up  =  normalize(cross(rainbow_w, up));
    rainbow_vertical = normalize(cross(rainbow_up, rainbow_w));
}

vec3 rainbow()
{
     vec2 uv = gl_FragCoord.xy / resolution.xy;
     vec2 p = (-1.0 + 2.0 * uv) * vec2(resolution.x / resolution.y, 1.0);

     vec3 color = vec3(0.0);
     if (p.y >= RAINBOW_START_Y)
     {
         vec2 uv = gl_FragCoord.xy / resolution.xy;
    
         rainbowSetup();

          vec3 dir = normalize(vec3(p, 0.0) - vec3(0.0, 0.0, -1.5));
          vec3 wdDir = normalize(dir.x * rainbow_up + dir.y * rainbow_vertical - dir.z * rainbow_w);
         
         color += rainbowColor(wdDir);
     }    
     return clamp(color, 0.0, 1.0);  
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec2 xy = gl_FragCoord.xy / resolution.xy;
    
    float intensity = INTENSITY;
    #if DAY_AND_NIGHT
    intensity *= clamp(sin(time * DAY_AND_NIGHT_TIME) + DAY_AND_NIGHT_MIN_BRIGHTNESS, 
                       DAY_AND_NIGHT_MIN_BRIGHTNESS, 
                       DAY_AND_NIGHT_MAX_BRIGHTNESS);
    #endif
    
    EPSILON_NRM = 0.5 / resolution.x;
    
    #if SIMULATE_MODE == SIMULATE
    SEA_CURRENT_TIME = 0.4 * time * SEA_SPEED;
    #elif SIMULATE_MODE == SIMULATE2x
    SEA_CURRENT_TIME = time * SEA_SPEED * 2.0;
    #elif SIMULATE_MODE == SIMULATE3x
    SEA_CURRENT_TIME = time * SEA_SPEED * 3.0;
    #elif SIMULATE_MODE == SIMULATE4x
    SEA_CURRENT_TIME = time * SEA_SPEED * 4.0;
    #elif SIMULATE_MODE == SIMULATE5x
    SEA_CURRENT_TIME = time * SEA_SPEED * 4.0;
    #elif SIMULATE_MODE == PAUSED
    SEA_CURRENT_TIME = 0.0;
    #elif SIMULATE_MODE == SLOW_MOTION
    SEA_CURRENT_TIME = time * SEA_SLOWMOTION_SPEED;
    #endif
 
    #if FLIP_WATER_AND_SKY
    vec3 dir = normalize(vec3(-uv.xy, -1.0));
    #else
    vec3 dir = normalize(vec3(uv.xy, -1.0));
    #endif
    dir.z += length(uv) * SEA_DIR_Z_SCALE;
    dir = normalize(dir);
 
    vec3 p = seaHeightMap(dir);
    vec3 dirLight = normalize(vec3(0.0, 1.0, 0.0)); 
    
    float smothMixFactor = pow(smoothstep(0.0, SMOOTH_MIX_Y, dir.y), MIX_SEA_AND_SKY_FACTOR);
    
    vec3 sky = sky(dir);
    vec3 sea = sea(p, dirLight, dir);
     
    vec3 color = mix(sky, sea, smothMixFactor);
    
    #if APPLY_LUMINANCE
    float luminance = dot(color, vec3(0.3, 0.59, 0.11));
    luminance = saturate(luminance);
    vec3 resLuminance = vec3(length(color.r * luminance), 
                              length(color.g * luminance), 
                              length(color.b * luminance));

    color.rgb = resLuminance;
    #endif
    
    color = color * CONTRAST + 0.5 - CONTRAST * 0.5;
    
    #if FOG_MODE != NEVER_FOG
    color = fog(color, dir.z);
    #endif
    
    #if RAIN
    vec3 rainColor = vec3(1.0, 1.0, 1.0) * 1.5;
    float rainFactor = rain(uv, xy);
    color = mix(color, rainColor, rainFactor);
    #endif
    
    color = color * intensity + COLOR_GRADING;
    
    #if RAINBOW
    color += rainbow();
    #endif
    
    #if APPLY_TONEMAP
    color = 1.0 -exp2(-color * TONEMAP_EXPOSURE);
    #endif
    
    #if APPLY_GAMMA_CORRECTION
    color = pow(color, vec3(1.0 / GAMMA));
    #endif
    
    glFragColor = vec4(color, 1.0);
}
