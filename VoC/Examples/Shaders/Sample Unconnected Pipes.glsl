#version 420

// original https://www.shadertoy.com/view/WsSyDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.1415926;
const float E = 0.005;

struct Ray
{
    vec3 pos;
    vec3 dir;
};

// https://www.shadertoy.com/view/4djSRW
float hash13(vec3 p3)
{
    p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
vec3 hash33(vec3 p3)
{
    p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

mat2 rotate2D(float rad)
{
    float c = cos(rad);
    float s = sin(rad);
    return mat2(c, s, -s, c);
}

vec3 rotate(vec3 p)
{
    p.xz *= rotate2D(time * 0.2);
    p.yz *= rotate2D(0.5);
    return p;
}

float deBlock(vec3 p)
{
    vec3 pb = p;

    p.xz += 0.5;
    vec2 q = vec2(length(p.xz) - 0.5, p.y);
    float d = length(q) - 0.12;
    
    p = pb;
    p.yz -= 0.5;
    q = vec2(length(p.yz) - 0.5, p.x);
    d = min(d, length(q) - 0.12);
    
    p = pb;
    p.xy -= vec2(0.5, -0.5);
    q = vec2(length(p.xy) - 0.5, p.z);
    d = min(d, length(q) - 0.12);
    
    d = abs(d) - 0.0125;
    
    return d;
}

vec2 de(vec3 p)
{
    p = rotate(p);
    
    vec3 pb = p;
    
    vec3 id = floor(p);
    p = fract(p) - 0.5;
    
    vec3 r = hash33(id);
    if (r.x < 0.5)  p.x *= -1.0;
    if (r.y < 0.5)    p.y *= -1.0;
    if (r.z < 0.5)    p.z *= -1.0;

    float d = deBlock(p);
    float offset = smoothstep(0.45, 0.5, length(p));
    d -= offset * 0.03;
    
    p = pb;
    d = max(max(d, abs(p.x) - 5.0), abs(p.z) - 5.0);
    
    return vec2(d * 0.75, offset);
}

// iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 normal(vec3 p)
{
    float h = E;
    vec2 k = vec2(1.0, -1.0);
    return normalize(
            k.xyy * de(p + k.xyy * h).x + 
            k.yyx * de(p + k.yyx * h).x + 
            k.yxy * de(p + k.yxy * h).x + 
            k.xxx * de(p + k.xxx * h).x
        );
}

float ao(Ray ray)
{
    float d = 0.0;
    d += de(ray.pos + ray.dir * 1.0).x;
    d += de(ray.pos + ray.dir * 2.0).x;
    d += de(ray.pos + ray.dir * 3.0).x;
    d += de(ray.pos + ray.dir * 4.0).x;
    d += de(ray.pos + ray.dir * 5.0).x;
    return pow(d / 15.0, 2.0);
}

float noiseValue3D(vec3 p, float div)
{
    p *= div;
    vec3 i = floor(p);
    vec3 f = fract(p);
    float r1 = hash13((i + vec3(0.0, 0.0, 0.0)));
    float r2 = hash13((i + vec3(1.0, 0.0, 0.0)));
    float r3 = hash13((i + vec3(0.0, 1.0, 0.0)));
    float r4 = hash13((i + vec3(1.0, 1.0, 0.0)));
    float r5 = hash13((i + vec3(0.0, 0.0, 1.0)));
    float r6 = hash13((i + vec3(1.0, 0.0, 1.0)));
    float r7 = hash13((i + vec3(0.0, 1.0, 1.0)));
    float r8 = hash13((i + vec3(1.0, 1.0, 1.0)));
    return mix(
            mix(mix(r1, r2, smoothstep(0.0, 1.0, f.x)), mix(r3, r4, smoothstep(0.0, 1.0, f.x)), smoothstep(0.0, 1.0, f.y)),
            mix(mix(r5, r6, smoothstep(0.0, 1.0, f.x)), mix(r7, r8, smoothstep(0.0, 1.0, f.x)), smoothstep(0.0, 1.0, f.y)),
            smoothstep(0.0, 1.0, f.z)
        );
}
float noiseValueFbm3D(vec3 p, float div, int octaves, float amplitude)
{
    float o = 0.0;
    float fbm_max = 0.0;
    for(int i = 0; i >= 0; i++)
    {
        if(i >= octaves)    break;
        float a = pow(amplitude, float(i));
        o += a * noiseValue3D(p, div * pow(2.0, float(i)));
        fbm_max += a;
    }
    return o / fbm_max;
}

void trace(Ray ray, inout vec3 color, float md)
{
    vec3 or = ray.pos;
    
    float ad = 0.0;
    for (float i = 1.0; i > 0.0; i -= 1.0 / 120.0)
    {
        vec2 o = de(ray.pos);
        if (o.x < E)
        {
            vec3 n = normal(ray.pos);

            // diffuse
            vec3 ld = normalize(vec3(1.0, 0.75, 0.5));
            float l = pow(dot(n, ld) * 0.5 + 0.5, 3.0) * 3.0;
            
            // specular
            vec3 h = normalize(ld + normalize(or - ray.pos));
            float hn = max(dot(h, n), 0.0);
            float s1 = pow(hn, 15.0) * 0.75;
            float s2 = pow(hn, 50.0) * 15.0;
            
            // ao
            Ray rayAo;
            rayAo.pos = ray.pos;
            rayAo.dir = n;
            float a = ao(rayAo);
            
            // noise
            vec3 p = rotate(ray.pos);
            float ns = noiseValueFbm3D(p, 10.0, 4, 0.5);
            ns = noiseValueFbm3D(p + vec3(ns), 10.0, 4, 0.5);

            // color
            color += mix(
                    vec3(0.01, 0.1, 1.0) + s2 * ns * ns * ns, 
                    (mix(vec3(0.2, 0.2, 0.2), vec3(0.15, 0.15, 0.3), ns) + s1) * max(ns, 0.35), 
                    smoothstep(0.8, 1.0, 1.0 - o.y)
                ) * l * a;
            
//            color = n * 0.5 + 0.5;
//            color = vec3(a);

            return;
        }

        ray.pos += ray.dir * o.x;
        ad = ad + o.x;
        if (ad > md)
        {
            break;
        }
    }

    // background
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    vec3 color = vec3(0.0);

    // view
    vec3 view = vec3(0.0, 0.0, 10.0);
    vec3 at = normalize(vec3(0.0, 0.0, 0.0) - view);
    vec3 right = normalize(cross(at, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, at);
    float focallength = 1.75;
    
    // ray
    Ray ray;
    ray.pos = view;
    ray.dir = normalize(right * p.x + up * p.y + at * focallength);

    // ray marching
    trace(ray, color, 20.0);

    // cheap tonemapping
    // https://www.desmos.com/calculator/adupt0spl8
    float k = 0.75;
    color = mix(color, 1.0 - exp(-(color - k) / (1.0 - k)) * (1.0 - k), step(k, color));

    // gamma correction
    color = pow(color, vec3(0.454545));

    glFragColor = vec4(color, 1.0);
}
