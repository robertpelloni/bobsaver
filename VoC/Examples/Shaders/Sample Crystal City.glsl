#version 420

// original https://www.shadertoy.com/view/tt3SW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 lightColor = normalize(vec3(0.8, 1.0, 1.0));
vec3 skyColor1 = normalize(vec3(0.2, 0.6, 1.0));
vec3 skyColor2 = normalize(vec3(0.8, 0.9, 1.0));
vec3 buildingColor = vec3(0., 0., 0.);

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, 0.0,
        oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
        oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c, 0.0,
        0.0, 0.0, 0.0, 1.0);
}

vec3 rotate(vec3 v, vec3 axis, float angle)
{
    mat4 m = rotationMatrix(axis, angle);
    return (m * vec4(v, 1.0)).xyz;
}

float GetDist(vec3 p)
{
    float dist = 99999999.;

    for (int i = -5; i < 3; i++)
    {
        float s = pow(2., float(-i));
        vec3 p = vec3(mod(p.x, s), p.y, mod(p.z, s));
        vec3 c = vec3(0.5 * s, -2., 0.5 * s);
        vec3 b = vec3(0.1, 0.4, 0.1) * s;
        vec3 q = abs(p - c) - b;
        float d = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
        dist = min(dist, d);
    }
    dist = min(dist, p.y + 2.);

    return dist;
}

float RayMarch(vec3 rayOrigin, vec3 rayDir)
{
    float rayLength = 0.;

    for (int marches = 0; marches < 500; marches++)
    {
        float dist = GetDist(rayOrigin + rayDir * rayLength);
        rayLength += dist;

        if (rayLength > 100.)
            return -1.;
        else if (dist < 0.01)
            return rayLength;
    }

    return -1.;
}

vec3 GetNormal(vec3 point)
{
    float d = GetDist(point);
    vec2 e = vec2(0, 0.01);
    return normalize(vec3(
        d - GetDist(point - e.yxx),
        d - GetDist(point - e.xyx),
        d - GetDist(point - e.xxy)
    ));
}

vec3 GetColor(vec3 camPos, vec3 lightDir, vec3 rayDir)
{
    vec3 totalColor = vec3(0);
    float r = 1.;
    for (int i = 0; i < 2; i++)
    {
        //calculate raymarch
        float rayMarch = RayMarch(camPos + rayDir * 0.02, rayDir);
        vec3 point = camPos + rayMarch * rayDir;

        //calculate lights
        vec3 color = buildingColor;
        vec3 normal = GetNormal(point);
        color *= lightColor * clamp(dot(-lightDir, normal), 0., 1.);
        color += lightColor * pow(max(dot(reflect(-lightDir, normal), rayDir), 0.), 32.);
        if (rayMarch == -1.)
        {
            color = mix(skyColor1, skyColor2, 1. - rayDir.y);
            totalColor += color * r;
            r /= 5.;
            break;
        }
        else
        {
            color = mix(color, mix(skyColor1, skyColor2, 1. - rayDir.y), clamp(rayMarch / 100., 0., 1.));
            totalColor += color * r;
            r /= 5.;
        }
        camPos = point;
        rayDir = reflect(rayDir, normal);
    }

    return totalColor;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    vec3 rayDir = normalize(vec3(uv, 0.5));
    vec3 camPos = vec3(3., 0., time * 5.);
    vec3 lightDir = normalize(vec3(-5, -3, -1));
    rayDir = rotate(rayDir, vec3(0., 1., 0.), sin(time) * 0.1 + 1.);
    
    uv = gl_FragCoord.xy / resolution.xy;
    uv *=  1.0 - uv.yx;
    float vig = uv.x*uv.y * 20.0;
    vig = pow(vig, 0.25);

    // Output to screen
    glFragColor = vec4(pow(GetColor(camPos, lightDir, rayDir) * vig, vec3(1.0/1.5)), 1.0);
}
