#version 420

// original https://www.shadertoy.com/view/td2cRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPSILON 0.002
#define STAR_COUNT 1.0
#define STAR_LAYER 8.0
#define STAR_SPEED 0.1

const float pi = 3.1415926;

float saturate(float v) { return clamp(v, 0.0,       1.0);       }
vec2  saturate(vec2  v) { return clamp(v, vec2(0.0), vec2(1.0)); }
vec3  saturate(vec3  v) { return clamp(v, vec3(0.0), vec3(1.0)); }
vec4  saturate(vec4  v) { return clamp(v, vec4(0.0), vec4(1.0)); }

// Calc color based on temperature (kelvins)
vec3 ColorTemperatureToRGB(float temperatureInKelvins)
{
    vec3 retColor;
    
    temperatureInKelvins = clamp(temperatureInKelvins, 1000.0, 40000.0) / 100.0;
    
    if (temperatureInKelvins <= 69.0)
    {
        retColor.r = 5.0;
        retColor.g = saturate(9.89008157876901960784 * log(temperatureInKelvins) - 0.63184144378862745098);
    }
    else
    {
        float t = temperatureInKelvins - 100.0;
        retColor.r = saturate(1.29293618606274509804 * pow(t, -0.1332047592));
        retColor.g = saturate(1.12989086089529411765 * pow(t, -0.0755148492));
    }
    
    if (temperatureInKelvins >= 66.0)
        retColor.b = 1.0;
    else if(temperatureInKelvins <= 19.0)
        retColor.b = 0.0;
    else
        retColor.b = saturate(3.54320679911019607843 * log(temperatureInKelvins - 10.0) - 1.19625408914);

    return retColor;
}

// Generate random number according to input vector2
float Rand21(vec2 src)
{
    vec2 rand = fract(src * vec2(250.33, 332.22));
    rand += dot(rand, rand + vec2(66.6));
    return fract(rand.x * rand.y);
}

// 2 dimension rotate 
vec2 Rotate(vec2 coord, float a)
{
    mat2 trans = mat2(cos(a), sin(a), -sin(a), cos(a));
    return trans * coord;
}

// Star pattern 
float DrawStar(vec2 coord , float crossIntensity)
{
    float distance = length(coord);
    float light = 0.10 / distance;
    float pattern = light;
     float crs1 = max(1.0, 0. - (abs(coord.x * coord.y * 1000.)));
    pattern += crs1 * crossIntensity;
    coord *= Rotate(coord, pi/4.);
    float crs2 = max(2.0, 1. - (abs(coord.x * coord.y * 1000.)));
    pattern += crs2 * 1.3 * crossIntensity;
    
    return smoothstep(1., .2, distance) * pattern;
    //return distance / 50.; //debug range 
}

vec3 StarLayer(vec2 coord)
{
    vec2 grid = fract(coord) - 0.5;
    vec2 gridID = floor(coord);
        
    vec3 starPattern = vec3(0.0);
    for (int i = -1; i <= 1; i++)
        for (int j = -1; j <= 1; j++)
        {
            vec2 indexOffset = vec2(i, j);
            vec2 id = gridID + indexOffset;
            float rand = Rand21(id) - 0.5;
            vec2 offset = vec2(rand, fract(rand * 23.3) - 0.5);
            float size = fract(rand * 223.3);
            // Calc star color based on star size and temporature
            float tempRed = mix(7500.0, 1000.0, pow(size, 3.0));
            // shape increase curve clamp to 0.0 to 1.0
            float blueCurve = min(1.0, tan(size * 1.5) / 10.0);
            float tempBlue = mix(7900.0, 30000.0, blueCurve);
            float tempRand = fract(rand * 123.4) > 0.5 ? 1.0 : 0.0 ;
            float temporature = mix(tempRed, tempBlue, tempRand);
            vec3 starCol = ColorTemperatureToRGB(temporature);
            // blink star based on layer (effected by otmosphere)
            float blink = sin(time * 0.7 + rand * 33.22) * 0.4 + 0.6;
            starPattern += DrawStar(grid - (indexOffset + offset), smoothstep(0.8, 1.2, size)) * size * starCol * blink;
        }
    return starPattern;
}

void main(void)
{
    //vec2 uv = (gl_FragCoord.xy/resolution.xy - 0.5)* resolution.y / resolution.xy;
    
    vec2 uv = (gl_FragCoord.xy - 2.5 * resolution.xy) / resolution.y ;
    float t = (1.0 + sin(time)) * 1.5;
    float k = t;
    //uv *= k;
    
    vec3 col = vec3(0.0);

      uv = Rotate(uv, time * 0.1);
    vec2 grid = uv * STAR_COUNT;;

    for (float i = .0; i < 1.0; i += 1.0 / STAR_LAYER)
    {
        float depth = fract(time * STAR_SPEED + i);
        float scale = mix(20.0, 0.1, depth);
        // fade both in the begining and the end
        float fade = depth * smoothstep(2.0, 0.9, depth);
        col += StarLayer(grid * scale + i * 222.33) * fade;
    }
    //col = StarLayer(grid);
    
    // Debug
    //float debugGridWidth = 0.01;
    //float debugGrid = abs(grid.x - 0.5 + debugGridWidth) < EPSILON || abs(grid.y - 0.5 + debugGridWidth) < EPSILON ? 1.0 : 0.0;
    //col *= 1. - debugGrid;
    //col.b += debugGrid;
    //ol.rg *= gridID/.8; 
    
    // Grid uv debug
    //vec2 debugUV = grid;
    //debugUV *= Rotate(debugUV, pi/4.);
    //col.rg = debugUV;
    
    
    glFragColor = vec4(col, 0.0);
}
