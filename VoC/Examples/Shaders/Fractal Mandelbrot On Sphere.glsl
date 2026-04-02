#version 420

// original https://www.shadertoy.com/view/WdByzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 sphere = vec4(0.0, 0.0, 1.0, 0.4);
vec3 lightPos = vec3(-9.0, 8.0, -8.0);
vec3 lightCol = vec3(0.8, 0.9, 1.0);

float sphereDist1(vec3 ro, vec3 rd)
{
    float R = sphere.w;
    vec3 d1 = sphere.xyz - ro;
    float b = dot(rd, d1);
    float d2 = dot(d1, d1) - b * b;
    float h2 = R * R - d2;
    if (h2 <= 0.0)
        return (-1.0);
    return (b - sqrt(h2));
}

float sphereDist(vec3 p)
{
 return (length(p - sphere.xyz) - sphere.w);   
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float getShadow(vec3 ro, vec3 rd, float tmin, float tmax, const float k)
{
    float res = 1.0;
    float t = tmin;
    for( int i = 0; i < 50; i++)
    {
        float h = sphereDist(ro + rd * t);
        res = min(res, k * h / t);
        t += clamp(h, 0.02, 0.20);
        if(res < 0.005 || t > tmax)
            break;
    }
    return clamp(res, 0.0, 1.0);
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 getNormal(vec3 pos)
{
    const float ep = 0.0001;
    vec2 e = vec2(1.0, -1.0) * 0.5773;
    return normalize( e.xyy*sphereDist(pos + e.xyy*ep) + 
                      e.yyx*sphereDist(pos + e.yyx*ep) + 
                      e.yxy*sphereDist(pos + e.yxy*ep) + 
                      e.xxx*sphereDist(pos + e.xxx*ep));
}

//smooth color gradient - https://www.shadertoy.com/view/4df3Rn
float mandelbrot(vec2 c)
{
    vec2 z = vec2(0.0);
    const float B = 256.0;
    float l = 0.0;
    for (int i = 0; i < 512; i++)
    {
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if (dot(z, z) > (B * B))
            break;
        l += 1.0;
    }
    if (l > 511.0)
        return (0.0); 
    //float l = l - log(log(length(z))/log(B))/log(2.0);
    l = l - log2(log2(dot(z, z))) + 4.0;
    return (l);
}

void main(void)
{
    vec2 aspectRatio = vec2(resolution.x / resolution.y, 1.0);
    vec2 uv = aspectRatio * (gl_FragCoord.xy / resolution.xy - 0.5);
    vec2 mouse = 7.0 * (mouse*resolution.xy.xy / resolution.xy - 0.5);  
    vec3 ro = vec3(0.0, 0.0, 0.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    
    float rot = time * 0.2;
    mat3 rotX = mat3(
        vec3(cos(mouse.x - rot), 0.0, sin(mouse.x - rot)),
        vec3(0.0, 1.0, 0.0),
        vec3(-sin(mouse.x - rot), 0.0, cos(mouse.x - rot)));  
    mat3 rotY = mat3(
        vec3(1.0, 0.0, 0.0),
        vec3(0.0, cos(mouse.y), sin(mouse.y)),
        vec3(0.0, -sin(mouse.y), cos(mouse.y)));
    
    vec3 color = vec3(0.09 - uv.x, 0.38, uv.x + 0.4) * (0.9 - uv.x);
    
    float dSphere = sphereDist1(ro, rd);
    if (dSphere < 0.0)
    {
        glFragColor = vec4(color, 1.0);
        return;
    }
    vec3 pos = ro + dSphere * rd;
    vec3 normal = getNormal(pos);
    vec3 v3 = rotX * rotY * normal;
    vec2 v2 = 1.5 * v3.xy / abs(v3.z);
    float dMb = mandelbrot(v2);
        
    vec3 material = 0.44 + 0.5 * cos(3.0 + dMb * 0.11 + vec3(0.0, 0.5, 1.0)); 
    vec3 lightDir = normalize(vec3(lightPos - pos));
    vec3 reflectDir = normalize(reflect(lightDir, normal));
    float shadow = getShadow(pos, lightDir, 0.001, 1.0, 8.0);
        
    float diffuse = clamp(dot(normal, lightDir), 0.0, 1.0) * shadow * 2.0;
    float ambient = 0.6 + 0.6 * normal.y;
    float specular = pow(clamp(dot(reflectDir, rd), 0.0, 1.0), 16.0) * 2.2 * shadow;
        
    color = lightCol * material * (diffuse + specular + ambient);
    color = sqrt(color);
    glFragColor = vec4(color, 1.0);
}
