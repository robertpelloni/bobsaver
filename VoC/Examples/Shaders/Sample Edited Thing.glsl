#version 420

// original https://www.shadertoy.com/view/4tGBz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define N_DELTA 0.015625
float rand(vec3 n) { 
    return fract(sin(dot(n, vec3(95.43583, 93.323197, 94.993431))) * 65536.32);
}

float perlin2(vec3 n)
{
    vec3 base = floor(n / N_DELTA) * N_DELTA;
    vec3 dd = vec3(N_DELTA, 0.0, 01.0);
    float
        tl = rand(base + dd.yyy),
        tr = rand(base + dd.xyy),
        bl = rand(base + dd.yxy),
        br = rand(base + dd.xxy);
    vec3 p = (n - base) / dd.xxx;
    float t = mix(tl, tr, p.x);
    float b = mix(bl, br, p.x);
    return mix(t, b, p.y);
}

float perlin3(vec3 n)
{
    vec3 base = vec3(n.x, n.y, floor(n.z / N_DELTA) * N_DELTA);
    vec3 dd = vec3(N_DELTA, 0.0, 0.0);
    vec3 p = (n - base) / dd.xxx;
    float front = perlin2(base + dd.yyy);
    float back = perlin2(base + dd.yyx);
    return mix(front, back, p.z);
}

float fbm(vec3 n)
{
    float total = 0.0;
    float m1 = 1.0;
    float m2 = 0.1;
    for (int i = 0; i < 6; i++)
    {
        total += perlin3(n * m1) * m2;
        m2 *= 2.1;
        m1 *= 0.6;
    }
    return total;
}

float cloudAtmosphere(vec2 uv)
{
    float n1 = fbm(vec3(uv * 2.0, 0.0));
    float n2 = fbm(vec3(uv,  1.0) + n1 * 0.05);   
    float n3 = fbm(vec3(uv, 2.0) + n2 * 0.3);
    return n3;
}

float nebula1(vec3 uv)
{
    float n1 = fbm(uv * 2.9 - 1000.0);
    float n2 = fbm(uv + n1 * 0.05);   
    return n2;
}

float nebula2(vec3 uv)
{
    float n1 = fbm(uv * 1.3 + 115.0);
    float n2 = fbm(uv + n1 * 0.35);   
    return fbm(uv + n2 * 0.17);
}

float nebula3(vec3 uv)
{
    float n1 = fbm(uv * 5.0);
    float n2 = fbm(uv + n1 * 0.15);   
    return n2;
}

vec3 nebula(vec3 uv)
{
    uv *= 10.0;
    return nebula1(uv * 0.5) * vec3(-5.0, 1.1, 7.0) -
            nebula2(uv * 0.4) * vec3(-3.5, 1.0, 8.0) -
            nebula3(uv * 0.6) * vec3(0.0, 0.0, -1.0);
        
}

float altitude(vec3 pos)
{
    return (cloudAtmosphere(pos.xz * 0.03) + 2.0) * 24.0;
}

float map(vec3 pos, vec3 rd)
{
    return (pos.y - altitude(pos)) * 0.7;
}

vec3 calcNormal(vec3 pos)
{
    vec3 dd = vec3(0.01, 0.0, 1.0);
    vec3 n = vec3(0.0, 1.0, 0.0);
    return normalize(vec3(map(pos + dd.xyy, n) - map(pos - dd.xyy, n),
                          map(pos + dd.yxy, n) - map(pos - dd.yxy, n),
                          map(pos + dd.yyx, n) - map(pos - dd.yyx, n)));
                          
}

void main(void)
{
    float size = max(resolution.x, resolution.y);
    vec2 xy = (gl_FragCoord.xy - resolution.xy * 0.5)  / size * 2.0;
    vec3 rayDir = normalize(vec3(xy, 1.0));
    vec2 uv = xy * 0.5 + 0.5;
    
    glFragColor = vec4(vec3((nebula(vec3(uv * 5.1, time * 0.1) * 0.1) - 1.0)), 1.0);
    
    //float ca = cloudAtmosphere(uv) * 0.5;
    //glFragColor = vec4(ca, ca, ca, 1.0);
    
    /*
    vec3 ro = vec3(cos(time), 0.0, time * 10.0);
    ro.y = altitude(ro) + 30.0;
    //vec3 fwd = normalize(-ro);
    //vec3 ro = vec3(0.0, 10.0, 0.0);
    vec3 fwd = normalize(vec3(0.0, -10.0, 50.0));
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 left = normalize(cross(fwd, up));
    vec3 rd = rayDir.x * left + rayDir.y * up + rayDir.z * fwd;
    
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
    vec3 pos = ro;
    float stepSize = 1.1;
    for (int i = 1; i < 50; i++)
    {
        //stepSize += stepSize * 0.1;
        float dist = map(pos, rd);
        pos += rd * max(dist, 0.0);
        if (dist < 0.01)
        {
            glFragColor = vec4(calcNormal(pos) * 0.5 + 0.5, 1.0);
            break;
        }
        pos += rd * max(dist * float(i) / 30.0, 0.0);
    }
    */
    //glFragColor = vec4(color, 1.0);

}
