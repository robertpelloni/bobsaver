#version 420

// original https://www.shadertoy.com/view/MtBGW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(in vec3 pos)
{
    float negCircle = length(pos) - 1.37;
    float cube = length(max(abs(pos) - 0.95, 0.0)) - 0.05;
    float shape = max(-negCircle, cube);
    
    float ground = dot(pos, vec3(0.0, 1.0, 0.0)) + 1.0;
    
    vec2 repeatPos = mod(pos.xz, 2.5) - 0.5 * 2.5;
    float pillars = length(max(abs(repeatPos) - 0.1, 0.0)) - 0.01;
    
    return min(min(shape, ground), pillars);
}

vec3 castRay(in vec3 ro, in vec3 rd, in float mint, in float maxt)
{
    vec3 p = vec3(0.0);
    float t = mint;
    
    for(int i = 0; i < 96; i++)
    {
        p = ro + rd*t;
        float dist = map(p);
        
        if (dist < 0.0 || t > maxt)
            break;
        
        t += dist;
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
    float dist = 0.02;
    vec3 spos = hitp + normal * dist;
    float sdist = map(spos);
    return clamp(sdist / dist, 0.0, 1.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 p = -1.0 + 2.0*uv;
    p.y *= resolution.y/resolution.x;
    
    vec3 ro = vec3(0.0, 0.0, -3.0);
    vec3 rd = normalize(vec3(p.x, p.y, 0.75));
    
    vec3 hitp = castRay(ro, rd, 1.5, 32.0);
    vec3 normal = getNormal(hitp);
    
    vec3 lightPos = vec3(cos(time * 0.6) * 5.0, 0.0, sin(time * 1.1) * 5.0);
    vec3 lightDir = normalize(hitp - lightPos);
    vec3 lightHit = castRay(hitp, -lightDir, 0.01, distance(hitp, lightPos));
    
    float ao = getAO(hitp, normal);
    float ndist = distance(ro, hitp) / 32.0;
    float shadow = distance(hitp, lightHit) / distance(hitp, lightPos);
    float light = clamp(dot(normal, lightDir), 0.05, 1.0);
    float specular = pow(clamp(dot(normalize(lightDir + rd), -normal), 0.0, 1.0), 64.0);
    
    vec4 lightColor = vec4(1.0) * light;
    vec4 specularColor =  vec4(1.0) * specular * light;
    vec4 fogColor = vec4(1.0) * pow(ndist, 3.0) + vec4(1.0, 0.5, 0.0, 1.0) * pow(ndist, 2.0);
    
    glFragColor = sqrt((lightColor + specularColor) * min(ao, shadow) + fogColor);
}
