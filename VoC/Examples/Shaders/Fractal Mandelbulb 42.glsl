#version 420

// original https://www.shadertoy.com/view/wsByzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 rotate(vec3 p, float angleX, float angleY)
{
    float cosA = cos(angleY);
    float sinA = sin(angleY);
    vec3 r = vec3(p.x, sinA * p.z + cosA * p.y, cosA * p.z - sinA * p.y);
    cosA = cos(angleX);
    sinA = sin(angleX);
    return (-vec3(cosA * r.x - sinA * r.z, r.y, sinA * r.x + cosA * r.z));
}

vec3 hsv2rgb(vec3 c)
{
    vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0,4.0,2.0),6.0) - 3.0) - 1.0, 0.0, 1.0);
    return (c.z * mix(vec3(1.0), rgb, c.y));
}

float distSphere(vec3 p, float r)
{
    return (length(p) - r);
}

bool backgr = false;

float distanceEstimate(vec3 p)
{
    float bailout = 2.0;
    float dSphere = -distSphere(p, 12.0);    
    vec3 v = p;
    float r = 0.0;
    float dr = 1.0;
    float power = abs(cos(time * 0.02)) * 10.0 + 2.0;
    for(float n = 0.0; n <= 8.0; n++)
    {
        r = length(v);
        if(r > bailout)
            break;
        // convert to polar coordinate
        float theta = acos(v.z / r);
        float phi = atan(v.y, v.x);
        dr = pow(r, power - 1.0) * power * dr + 1.0;
        
        // scale and rotate the point
        float vr = pow(r, power);
        theta = theta * power;
        phi = phi * power;
        
        // convert back to cartesian coordinates
        v = vr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
        
        v += p;
    }
    float dFractal = 0.50 * log(r) * r / dr;    
    backgr = dSphere < dFractal ? true : false;
    return (min(dFractal, dSphere));
}

vec3 getNormal(vec3 pos, float dist)
{
    vec3 eps = vec3(0.001, 0.0, 0.0);
    return normalize(vec3(
           distanceEstimate(pos + eps.xyy),
           distanceEstimate(pos + eps.yxy),
           distanceEstimate(pos + eps.yyx)) - dist);
}

float softShadow(in vec3 ro, in vec3 rd, in float k)
{
    float res = 1.0;
    float t = 0.0;
    for(int i = 0; i < 64; i++)
    {
        float d = distanceEstimate(ro + rd * t);
        res = min(res, k * d/t);
        if(res < 0.001)
            break;
        t += clamp(d, 0.01, 0.2);
    }
    return (clamp(res, 0.0, 1.0));
}

void main(void)
{
    vec2 aspectRatio = vec2(resolution.x/resolution.y, 1.0);
    vec2 uv = aspectRatio * (gl_FragCoord.xy / resolution.xy - 0.5);
    vec2 mouse = 7.0 * (mouse*resolution.xy.xy / resolution.xy - 0.5);
    vec3 ro = rotate(vec3(0.0, 0.0, 2.5), mouse.x, mouse.y);
    vec3 rd = -rotate(vec3(uv, 1.0), mouse.x, mouse.y);  
    vec3 light = rotate(vec3(0.0, 0.3, 0.77), mouse.x, mouse.y);
    vec3 lightColor = vec3(0.8, 0.9, 1.0);
    vec3 material;
    vec3 color;
    float eps = 0.002;
    float dist;
    for(float n = 0.0; n < 200.0; n++)
    {
        dist = distanceEstimate(ro);
        if(dist < eps)
            break;
        ro += rd * dist * 0.5;
    }
    if(backgr == true)
    { 
        color = vec3(0.3, 0.8, 1.0) * (0.5 - 0.4 * uv.x);
        glFragColor = vec4(color, 1.0);
        return;
    }
    vec3 norm = getNormal(ro, dist);
    material = hsv2rgb(vec3(dot(ro, ro) - 0.27, 1.2, 1.0));
    vec3 lightDir = normalize(light - rd);   
    float shadow = softShadow(ro + 0.001 * norm, light, 5.0);
    float ambient = 0.22;
    float diff = clamp(dot(light, norm), 0.0, 1.0) * shadow * 0.9;
    float spec = pow(clamp(dot(norm, lightDir), 0.0, 1.0), 32.0) * shadow * 1.8;
     color = (lightColor * (ambient + diff + spec) * material);  
    color = pow(color, lightColor); 
    vec2 fd = (6.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;   
    color *= 1.0 - length(fd) * 0.07;
    glFragColor = vec4(color, 1.0);
}
