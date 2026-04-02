#version 420

// original https://www.shadertoy.com/view/wl3XRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI             3.14159265357989
#define TAU            (PI * 2)
#define saturate(v)    (clamp(v, 0.0, 1.0))

// --------------------------------------------------

const int pattern[60] = int[](
    1,0,0,0,0,0,0,0,0,0,
    1,0,1,1,1,1,1,1,1,0,
    1,0,0,1,0,1,0,1,0,0,
    1,0,1,0,0,1,0,0,1,0,
    1,1,1,1,0,1,0,1,1,1,
    0,0,0,0,0,1,0,0,0,0
);

struct Primitive
{
    float type;
    float dist;
    vec2 uv;
};

struct Geometry
{
    float type;
    vec3 position;
    vec3 normal;
    float dist;
    vec2 uv;
};
    
struct Material
{
    vec3 color;
};
    
// --------------------------------------------------

mat3 rotate(float angle, vec3 axis)
{
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m;
}

float hash(vec2 v)
{
    return fract(sin(dot(v, vec2(34373.129, 472.445))) * 1933.55);
}

float sdSphere(in vec3 pos)
{
    return length(pos) - 0.5;
}

float sdBox(in vec3 pos)
{
    vec3 q = abs(pos) - vec3(0.5);
    return length(max(q, 0.0)) - min(max(q.x, max(q.y, q.z)), 0.0);
}

// --------------------------------------------------

vec2 mapimp(in vec3 rayPos, in vec3 rayDir)
{
    vec2 grid = floor(rayPos.xz);
    float rand = hash(grid);
    
    vec2 ptn = vec2(mod(grid.x, 10.0), mod(grid.y, 10.0));
    ptn.y = 5.0 <= ptn.y ? 10.0 - ptn.y : ptn.y;
    float up = float(pattern[int(ptn.x + ptn.y * 10.0)]);
    
    float seqence =  sin(time * 0.5);
    
    vec3 localPos = rayPos;
    localPos.xz = fract(rayPos.xz) - 0.5;
    localPos.y += (sin(rand * 10.0 + time) * 1.0) * smoothstep(-0.3, -1.0, seqence);
    localPos.y -= up * cos(time * 0.5) * smoothstep(-1.0, 0.0, seqence);
    
    return vec2(up + 1.0, sdBox(localPos));
}

Primitive map(in vec3 rayPos, in vec3 rayDir)
{
    vec2 primitive = mapimp(rayPos, rayDir).xy;
    
    // anti overshoot grid
    vec2 gridDist = (step(vec2(0), rayDir.xz) - fract(rayPos.xz)) / rayDir.xz;
    gridDist.x = min(gridDist.x, gridDist.y) + 1e-4;
    primitive = gridDist.x < primitive.y ? vec2(0, gridDist.x) : primitive;

    Primitive result;
    result.type = primitive.x;
    result.dist = primitive.y;
    return result;
}

vec3 computeNormal(in vec3 pos, in vec3 rayDir)
{
    vec2 Epsilon = vec2(0.0, 1e-3);
    return normalize(vec3(
        map(pos + Epsilon.yxx, rayDir).dist - map(pos - Epsilon.yxx, rayDir).dist,
        map(pos + Epsilon.xyx, rayDir).dist - map(pos - Epsilon.xyx, rayDir).dist,
        map(pos + Epsilon.xxy, rayDir).dist - map(pos - Epsilon.xxy, rayDir).dist
    ));
}

Geometry raymarch(in vec3 camPos, in vec3 camDir, float start, int steps)
{
    Geometry geometry;
    geometry.type = 0.0;
    float migration = start;
    
    for(int i=0 ; i<steps ; ++i)
    {
        Primitive primitive = map(camPos + camDir * migration, camDir);
        
        if(primitive.dist < 1e-4)
        {
            geometry.type = primitive.type;
            break;
        }
        
        migration += primitive.dist;
    }
    
    vec3 pos =  camPos + camDir * migration;
    geometry.position = pos;
    geometry.normal = computeNormal(pos, camDir);
    geometry.dist = migration;
    geometry.uv = abs((1.0 - abs(geometry.normal.xz)) * geometry.position.xz);
    geometry.uv = vec2(max(geometry.uv.x, geometry.uv.y), geometry.position.y);
    geometry.uv = mix(geometry.uv, geometry.position.xz, saturate(abs(geometry.normal.y)));
    geometry.uv *= 0.3;
    return geometry;
}

float volumetric(in vec3 camPos, in vec3 camDir, in vec3 litDir, float stepLength, float maxLength)
{
    float migration = 0.0;
    float brightness = 0.0;
    
    for(int i=0 ; i<50 ; ++i)
    {
        migration += stepLength;
        vec3 pos = camPos + camDir * migration;

        Geometry occlusion = raymarch(pos, -litDir, 0.0, 30);
        brightness += step(occlusion.type, 1.0) * occlusion.dist * 1e-2 * 4.0 * (1.0 - migration * 1e-2);
        
        if(maxLength <= migration)
            break;
    }
    
    return brightness;
}

Material materialize(in Geometry geometry, in Geometry occlusion, in vec3 litDir, in float volume)
{
    Material material;
    material.color = vec3(0);
    material.color += float(geometry.type == 1.0) * vec3(1);
    //material.color += float(geometry.type == 2.0) * texture(iChannel0, geometry.uv).rgb;
    material.color = 1.0 - pow(1.0 - material.color, vec3(3.0));
    
    float light = mix(0.0, 1.0, occlusion.dist * 0.5);
    light = min(light, dot(litDir, geometry.normal));
    light = clamp(light, 0.2, 1.0);
    
    material.color *= light;
    material.color += light * vec3(0.02,0.03, 0.0);
    material.color = mix(material.color, vec3(0.0), pow(geometry.dist * 1e-2 * 1.5, 3.0));
    material.color += volume * vec3(0.017, 0.015, 0.008);
    
    return material;
}

void main(void)
{
       vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    mat3 camMat = rotate(time * 0.1 + PI * 0.75, vec3(0,1,0)) * rotate(PI * 0.25, vec3(1,0,0));
    vec3 camPos = camMat * vec3(0,0,-20) + vec3(0,3,0);
    vec3 camDir = normalize(camMat * vec3(uv, 2.0));
    vec3 litDir = normalize(rotate(time * 0.1, vec3(0,1,0)) * vec3(0.5,0.8,0.5));
    
    float ortho = smoothstep(0.4, 0.6, cos(time * 0.2) * 0.5 + 0.5);
    camPos += camMat * vec3(uv, 0) * 10.0 * ortho;
    camDir = mix(camDir, normalize(camMat * vec3(0, 0, 1)), ortho);
    
    Geometry geometry = raymarch(camPos, camDir, 0.0, 130);
    Geometry occlusion = raymarch(geometry.position, litDir, 1e-3, 20);
    float volume = volumetric(camPos, camDir, litDir, 0.5, 20.0) * (1.0 - ortho);
    Material material = materialize(geometry, occlusion, litDir, volume);

    glFragColor.rgb = material.color;
    glFragColor.a = 1.0;
}
