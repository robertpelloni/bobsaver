#version 420

// original https://www.shadertoy.com/view/Xl23zm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DIST 10.0

float map(in vec3 pos)
{
    float circle = length(pos) - 2.0 + cos((pos.x + pos.y) * 15.0) * 0.05;
    float negCircle = length(pos) - 1.4;
    float cube = length(max(abs(pos) - 1.0, 0.0)) - 0.05;
    float ground = dot(pos, vec3(0.0, 1.0, 0.0)) + 1.0 + cos(pos.x * 20.0) * 0.05;
    float ceiling = dot(pos, vec3(0.0, -1.0, 0.0)) + 3.0 + 1.0 + cos(pos.z * 20.0) * 0.05;
    
    float shape = mix(circle, cube, 0.5 + 0.5 * cos(time));
    shape = max(-negCircle, shape);
    return min(shape, min(ground, ceiling));
}

vec3 castRay(in vec3 ro, in vec3 rd)
{
    vec3 p = vec3(0.0);
    float t = 0.0;
    
    for(int i = 0; i < 64; i++)
    {
        p = ro + rd*t;
        float dist = map(p);
        
        if (dist < 0.0 || dist > MAX_DIST)
            break;
        
        t += max(dist * 0.8, 0.001);
    }
    
    return p;
}

vec3 getNormal(in vec3 pos)
{
    vec2 eps = vec2(0.001, 0.0);
    vec3 normal = vec3(
        map(pos + eps.xyy) - map(pos - eps.xyy),
        map(pos + eps.yxy) - map(pos - eps.yxy),
        map(pos + eps.yyx) - map(pos - eps.yyx));
    return normalize(normal);
}

float getAO(in vec3 hitp, in vec3 normal)
{
    float dist = 0.1;
    vec3 spos = hitp + normal * dist;
    float sdist = map(spos);
    return clamp(sdist / dist, 0.5, 1.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 p = -1.0 + 2.0*uv;
    p.y *= resolution.y/resolution.x;
    
    vec3 ro = vec3(0.0, 0.0, -3.0);
    vec3 rd = normalize(vec3(p.x, p.y, 0.5));
    
    vec3 hitp = castRay(ro, rd);
    vec3 normal = getNormal(hitp);
    float ao = getAO(hitp, normal);
    float ndist = distance(ro, hitp) / MAX_DIST;
    
    glFragColor = vec4(1.0) * ao - ndist;
}
