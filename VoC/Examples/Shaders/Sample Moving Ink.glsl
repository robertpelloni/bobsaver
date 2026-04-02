#version 420

// original https://www.shadertoy.com/view/WdtXz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NEGATIVE_COLOR vec3(0.4, 0.4, 1.0)
#define POSITIVE_COLOR vec3(0.4, 1.0, 0.4)
#define BORDER_COLOR vec3(1.0, 1.0, 1.0)
#define BORDER_WIDTH 0.004

#define TIME (time * 1.0)

float hash12(vec2 x)
{
     return fract(sin(dot(x, vec2(533.59731, 821.49221))) * 4315.212331);   
}

float sphereSDF(vec2 point, float radius)
{
    return length(point) - radius;
}

vec2 sphereCenter(vec2 rootUV)
{
     float hash = hash12(rootUV);
    vec2 relativePos = vec2(sin(hash * 532.121 + TIME * 2.0), cos(hash * 532.121 + TIME * 2.0)) * 0.5 + 0.5;
    return rootUV + relativePos;
}

float addObjects(float o1, float o2)
{
     return min(o1, o2);   
}

float addObjectsSmooth(float o1, float o2, float smoothness)
{
    float k = clamp((o1 - o2) / smoothness * 0.5 + 0.5, 0.0, 1.0);
    return mix(o1, o2, k) - k * (1.0 - k) * smoothness;
}

float sphereGridSDF(vec2 point, float radius, float gridScale)
{
    point *= gridScale;
     vec2 rootUV = floor(point);
    float minSDF = 99999.0;
    for (float x = -1.0; x <= 1.0; x++)
    {
         for (float y = -1.0; y <= 1.0; y++)
        {
            float sphereSDF = sphereSDF(point - sphereCenter(rootUV + vec2(x, y)), radius);
            minSDF = addObjectsSmooth(minSDF, sphereSDF, 0.3);
        }
    }
    
    return minSDF / gridScale;
}

float objSDF(vec2 point)
{
     float object = sphereSDF(point, 0.2);
    
    vec2 circularMovement = vec2(sin(TIME * 0.2), cos(TIME * 0.2)) * 2.0;
    vec2 dotsShift = vec2(-cos(TIME * 0.2), sin(TIME * 0.2));
    float gridSphereRadius = (smoothstep(0.5, 0.0, length(point - dotsShift * 0.1)) - 0.4);
    float smallGridSphereRadius = (smoothstep(0.4, 0.0, length(point - dotsShift * 0.1)) - 0.5);
    object = addObjectsSmooth(object, sphereGridSDF(point + circularMovement, gridSphereRadius, 10.0), 0.1);
    object = addObjectsSmooth(object, sphereGridSDF(point + circularMovement, smallGridSphereRadius, 20.0), 0.01);
    return object;
}

vec3 objSDFToTestColor(float objSDF)
{
    vec3 col = vec3(0.0);
    float positive = smoothstep(-BORDER_WIDTH, BORDER_WIDTH, objSDF);
    float border = smoothstep(BORDER_WIDTH, BORDER_WIDTH * 0.5, abs(objSDF));
    
    float lines = smoothstep(0.5, 0.0, abs(fract(objSDF * 40.0) - 0.5)) * 0.8;
    
    col += POSITIVE_COLOR * positive * lines;
    col += NEGATIVE_COLOR * (1.0 - positive) * lines;
    col += BORDER_COLOR * border;
    
    return col;
}

vec3 objSDFToColor(float objSDF)
{
    float positive = smoothstep(-BORDER_WIDTH, BORDER_WIDTH, objSDF);

    return vec3(1.0) * positive;
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.x;

    float sdf = objSDF(uv);
    vec3 col = objSDFToColor(sdf);
    
    // Output to screen
    glFragColor = vec4(col, 1.0);
}
