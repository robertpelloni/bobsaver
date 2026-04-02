#version 420

// original https://www.shadertoy.com/view/wstXzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI   3.14159265357989
#define PI_2 6.28318530715978

float rand(vec3 st)
{
    return fract(sin(dot(st, vec3(12.9898, 78.233, 59378.234))) * 10000.0);
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec2 opMin(vec2 a, vec2 b)
{
    return mix(a, b, step(b.x, a.x));
    return a.x < b.x ? a : b;
}

vec2 map(in vec3 rayPos)
{
    float time = fract(time);
    vec3 grid = floor(rayPos);
    float noise = rand(grid);
    vec3 sphRayPos = fract(rayPos + vec3(time * mix(-1.0, 1.0, step(fract(grid.z / 2.0), 0.0)), 0.5, 0));
    vec3 boxRayPos = fract(rayPos + vec3(0.0, time * mix(-1.0, 1.0, step(fract(grid.x / 2.0), 0.0)), 0));
    
    vec2 ret = vec2(1e+2, 0);
    ret = opMin(ret, vec2(length(sphRayPos - 0.5) - 0.2, 1));
    ret = opMin(ret, vec2(sdBox(boxRayPos - 0.5, vec3(0.15)), 2));
    return ret;
}

vec4 march(in vec3 camPos, in vec3 camRay)
{
    const int ITERATE = 128;
    vec3 rayPos = camPos;
    vec4 ret = vec4(0);
    
    for(int i=0 ; i<ITERATE ; ++i)
    {
        vec2 result = map(rayPos);
        rayPos += camRay * result.x;
        
        if(result.x < 1.0e-3)
        {
            ret.xyz = rayPos;
            ret.w = result.y;
        }
    }
    
    return ret;
}

vec3 computeNormal(vec3 pos)
{
    const float EPSILON = 1.0e-4;
    return normalize(vec3(
        map(vec3(pos.x + EPSILON, pos.y, pos.z)).x - map(vec3(pos.x - EPSILON, pos.y, pos.z)).x,
        map(vec3(pos.x, pos.y + EPSILON, pos.z)).x - map(vec3(pos.x, pos.y - EPSILON, pos.z)).x,
        map(vec3(pos.x, pos.y, pos.z + EPSILON)).x - map(vec3(pos.x, pos.y, pos.z - EPSILON)).x
    ));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec3 camPos = vec3(0.5 + cos(fract(time * 0.25) * PI_2) * 0.1, sin(fract(time * 0.5) * PI_2) * 0.5 + 0.1, time);
    vec3 camDir = vec3(0, 0, 1);
    vec3 camUp  = normalize(vec3(cos(fract(time * 0.05) * PI_2), sin(fract(time * 0.05) * PI_2), 0));
    vec3 camSide= cross(camDir, camUp);
    mat3 camMat = mat3(camSide, camUp, camDir);
    float camLength = 2.0;
    vec3 camRay = camMat * normalize(vec3(uv, camLength));
    
    vec3 rd = (vec3(2.0 * gl_FragCoord.xy - resolution.xy, resolution.y));
    rd = normalize(vec3(rd.xy, sqrt(max(rd.z * rd.z - dot(rd.xy, rd.xy) * 0.2, 0.0))));
    
    vec4 result = march(camPos, camRay);
    float resDist  = distance(camPos, result.xyz);
    vec3 resPos    = vec3(result.xyz);
    vec3 resNormal = computeNormal(resPos);
    
    vec3 diffuse = vec3(0);
    diffuse = mix(diffuse, vec3(0.7, 0.7, 0.5), step(result.w, 2.0));
    diffuse = mix(diffuse, vec3(0.8, 0.7, 0.3), step(result.w, 1.0));
    diffuse = mix(diffuse, vec3(0.9), step(result.w, 0.0));
    
    vec3 lightDir = normalize(vec3(1,1.5,-1));
    vec3 light = clamp(dot(lightDir, resNormal), 0.3, 1.0) * vec3(1);
    light = mix(light, vec3(1), step(result.w, 0.0));

    glFragColor = vec4(diffuse * light,1.0);
    glFragColor.rgb = mix(glFragColor.rgb, vec3(0.9), clamp(resDist * 0.075, 0.0, 1.0));
}
