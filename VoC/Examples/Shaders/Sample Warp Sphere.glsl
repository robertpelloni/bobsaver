#version 420

// original https://www.shadertoy.com/view/lttBDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(in vec3 p)
{
    p = fract(p * vec3(821.35, 356.17, 671.313));
    p += dot(p, p+23.5);
    return fract(p.x*p.y*p.z);
}

float noise(in vec3 p)
{
    vec3 ip = floor(p);
    vec3 fp = fract(p);
    
    float a = hash(ip + vec3(0, 0, 0));
    float b = hash(ip + vec3(1, 0, 0));
    float c = hash(ip + vec3(0, 1, 0));
    float d = hash(ip + vec3(1, 1, 0));
    float e = hash(ip + vec3(0, 0, 1));
    float f = hash(ip + vec3(1, 0, 1));
    float g = hash(ip + vec3(0, 1, 1));
    float h = hash(ip + vec3(1, 1, 1));
    
    vec3 t = smoothstep(vec3(0), vec3(1), fp);
    return mix(mix(mix(a, b, t.x), mix(c, d, t.x), t.y),
               mix(mix(e, f, t.x), mix(g, h, t.x), t.y), t.z);
}

float fbm(in vec3 p)
{   
    float res = 0.0;
    float amp = 0.5;
    float freq = 2.0;
    for (int i = 0; i < 5; ++i)
    {
        res += amp * noise(freq * p);
        amp *= 0.5;
        freq *= 2.0;
    }
    return res;
}

float bi_fbm(in vec3 p)
{
    return 2.0 * fbm(p) - 1.0;
}

vec3 warp(in vec3 p)
{
    p = p + bi_fbm(p + mod(0.5*time, 100.0));
    p = p + bi_fbm(p - mod(0.3*time, 100.0));
    return p;
}

float map(in vec3 p)
{
    p = warp(p);
    return 0.2 * (length(p) - 1.0);
}

vec3 map_n(in vec3 p)
{
    vec2 e = vec2(0, 0.001);
    return normalize(vec3(map(p + e.yxx), map(p + e.xyx), map(p + e.xxy)) - map(p));
}

vec3 color_map(in float t)
{
    vec3 a = vec3(1, 0, 0);
    vec3 b = vec3(1, 0.3, 0);
    vec3 c = vec3(1, 0.7, 0);
    vec3 d = vec3(1, 0.3, 0);
    
    if (t < 0.333)
    {
        return mix(a, b, 3.0*t);
    }
    else if (t < 0.666)
    {    
        return mix(b, c, 3.0*(t - 0.3333));
    }
    else
    {
        return mix(c, d, 3.0*(t - 0.6666));
    }
}

void main(void)
{
    vec2 uv = 2.0 * gl_FragCoord.xy/resolution.xy - 1.0;
    uv.x *= resolution.x / resolution.y;

    vec3 at = vec3(0);
    vec3 ro = vec3(0, 0, -3);
    vec3 cam_z = normalize(at - ro);
    vec3 cam_x = normalize(cross(vec3(0,1,0), cam_z));
    vec3 cam_y = cross(cam_z, cam_x);
    vec3 rd = normalize(cam_x * uv.x + cam_y * uv.y + 1.73 * cam_z);
    
    int iter = 0;
    int matid = -1;
    float t = 0.001;
    float t_max = 20.0;
    for (int i = 0; i < 256; ++i)
    {
        if (t > t_max) break;
        
        float d = map(ro + t*rd);
        if (d < 0.001)
        {
            matid = 0;
            iter = i;
            break;
        }
        t += d;
    }
    
    float occ = 1.0 - float(iter) / 256.0;
    
    vec3 sky = vec3(0.6, 0.7, 0.8);
    vec3 col = sky;
    if (matid != -1)
    {
        vec3 p = ro + t*rd;
        vec3 n = map_n(p);
        vec3 l = normalize(vec3(0.5, 0.4, -0.5));
        vec3 sun = vec3(1.5);
        vec3 albedo = vec3(0.9) * color_map(fbm(warp(p)));
        
        vec3 direct_light = max(0.0, dot(n, l)) * sun;
        vec3 indirect_light = pow(occ, 10.0) * (0.2 * sky);
        
        col = (indirect_light + direct_light) * albedo;
    }
    
    col = 1.0-exp(-col);
    col = sqrt(col);
    glFragColor = vec4(col,1.0);
}
