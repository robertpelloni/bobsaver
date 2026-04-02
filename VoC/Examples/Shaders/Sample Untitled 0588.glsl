#version 420

// original https://www.shadertoy.com/view/tsKBzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdf(vec3 p)
{
    float m = 1.0;
    for (float i = 0.0; i < 4.0; i++)
    {
        vec4 sphere = vec4(cos(p.y * 4.0 + time * i * 2.0 + i * 2.0) * 0.15 + 3.0 * i - 4.0, sin(time * 5.0 + i * 5.0) * 0.5 + 1.25 + sin(p.x * 4.0 + time * 10.0 + i * 6.0) * 0.15 + 1.2, 6.0, 1.0);
        float distanceSphere = length(p - sphere.xyz) - sphere.w;
        m = min(m, distanceSphere);
    }
    float distancePlane = p.y + cos(p.z + time * 1.5) * sin(p.x + time * 2.0) * 0.5 + cos(p.z + time * 3.5) * 0.5 + 1.75;
    return min(m, distancePlane);
}

vec3 normal(vec3 p)
{
    vec2 delta = vec2(0.01, 0.0);
    float dist = sdf(p);
    return normalize(dist - vec3(
        sdf(p - delta.xyy),
        sdf(p - delta.yxy),
        sdf(p - delta.yyx)
    ));
}

float raymarch(vec3 origin, vec3 direction)
{
    float distanceOrigin = 0.0;
    
    for (int i = 0; i < 64; i++)
    {
        vec3 point = origin + direction * distanceOrigin;
        float distanceScene = sdf(point);
        distanceOrigin += distanceScene;
        if (distanceOrigin < 0.01 || distanceOrigin > 100.0) break;
    }
    
    return distanceOrigin;
}

vec3 light(vec3 p, vec3 pos, vec3 col, float s)
{
    vec3 l = normalize(pos - p);
    vec3 n = normal(p);
    
    float dist = distance(p, pos);
    float att = 1.0 / (dist + 0.15 * dist + 0.15 * dist * dist);
    
    float diffuse = clamp(dot(l, n), 0.0, 1.0);
    
    float d = raymarch(p + n * 0.2, l);
    if (d < length(pos - p)) diffuse *= 0.1;
    
    return col * smoothstep(0.0, 1.0, diffuse) * att * s;
}

vec3 lights(vec3 p)
{
    vec3 position = vec3(0.0, 6.0, 6.0);
    position.xz += vec2(cos(time * 2.0), sin(time * 2.0)) * 2.0;
    
    vec3 l = vec3(0.0);
    
    vec3 color = vec3(0.5);
    
    color.r = sin(time * 2.0 + 50.0) * 0.25 + 1.0;
    color.g = cos(time * 2.0 + 150.0) * 0.25 + 1.0;
    color.b = sin(time * 2.0 + 200.0) * 0.25 + 1.0;
    
    l += light(p, position, color, 6.0);
    l += light(p, vec3(-4.0, 4.0, -1.0), vec3(0.15, 0.15, 0.8), 8.0);
    l += light(p, vec3(4.0, 4.0, -1.0), vec3(0.15, 0.8, 0.15), 8.0);
    
    return l;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    
    vec3 col = vec3(0.0);
    
    vec3 ro = vec3(0.0, 2.5, 0.0);
    vec3 rd = normalize(vec3(uv.x, uv.y, 0.5));
    
    float dist = raymarch(ro, rd);
    
    vec3 p = ro + rd * dist;
    vec3 diffuse = lights(p);
    
    col = diffuse;

    glFragColor = vec4(col, 1.0);
}
