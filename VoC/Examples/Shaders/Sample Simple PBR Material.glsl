#version 420

// original https://www.shadertoy.com/view/Wdl3zB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPSILON 0.001
#define MAX_DIST 50.0
#define MIN_DIST EPSILON
#define PI 3.14159265359
#define SAT(n) clamp(n, 0.0, 1.0)

struct Material
{
    vec3 albedo;
    float roughness;
    float metallic;
};

struct Hit
{
    float dist;
    Material material;
};

const Material kInvalidMaterial = Material(vec3(0.0), 0.0, 0.0);

//https://www.iquilezles.org/www/articles/morenoise/morenoise.htm
float hash( float n ) { return fract(sin(n)*753.5453123); }

//https://www.iquilezles.org/www/articles/morenoise/morenoise.htm
//---------------------------------------------------------------
// value noise, and its analytical derivatives
//---------------------------------------------------------------

vec4 noised( in vec3 x )
{
    vec3 p = floor(x);
    vec3 w = fract(x);
    vec3 u = w*w*(3.0-2.0*w);
    vec3 du = 6.0*w*(1.0-w);
    
    float n = p.x + p.y*157.0 + 113.0*p.z;
    
    float a = hash(n+  0.0);
    float b = hash(n+  1.0);
    float c = hash(n+157.0);
    float d = hash(n+158.0);
    float e = hash(n+113.0);
    float f = hash(n+114.0);
    float g = hash(n+270.0);
    float h = hash(n+271.0);
    
    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return vec4( k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z, 
                 du * (vec3(k1,k2,k3) + u.yzx*vec3(k4,k5,k6) + u.zxy*vec3(k6,k4,k5) + k7*u.yzx*u.zxy ));
}

vec4 fbmd( in vec3 x )
{
    const float scale  = 1.5;

    float a = 0.0;
    float b = 0.5;
    float f = 1.0;
    vec3  d = vec3(0.0);
    for( int i=0; i<8; i++ )
    {
        vec4 n = noised(f*x*scale);
        a += b*n.x;           // accumulate values      
        d += b*n.yzw*f*scale; // accumulate derivatives
        b *= 0.5;             // amplitude decrease
        f *= 1.8;             // frequency increase
    }

    return vec4( a, d );
}

float smin(float d1, float d2, float k)
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

mat2 rot(float r) { return mat2(cos(r), sin(r), -sin(r), cos(r)); }

float sdfBox(vec3 p, vec3 s)
{
    vec3 d = abs(p) - s;
    return length(max(d,0.0)) + min(0.0, max(d.x, max(d.y, d.z)));
}

float sdfSphere(vec3 p, float r)
{
    return length(p) - r;
}

Material mixMaterial(Material a, Material b, float s)
{
    return Material(
        mix(a.albedo, b.albedo, s),
        mix(a.roughness, b.roughness, s),
        mix(a.metallic, b.metallic, s)
    );
}

float noiseValue = 0.0;

Hit scene(vec3 p)
{
    vec3 rep = vec3(3.0, 0.0, 3.0);
    float n = pow(noiseValue, 2.0);
    
    p = mod(p, rep) - rep * 0.5;
    p.xz *= rot(1.0);
    
    float box = sdfBox(p, vec3(0.4)) - 0.1;
    float sphereA = sdfSphere(p + vec3(+0.9, 0.0, 0.0), 0.5);
    float sphereB = sdfSphere(p + vec3(-0.9, 0.0, 0.0), 0.5);
    
    Material m = Material(vec3(176.0/255.0, 196.0/255.0, 222.0/255.0), SAT(0.35), SAT(1.0));
    Material b = Material(vec3(183.0/255.0, 65.0/255.0, 14.0/255.0), SAT(pow(1.0 - noiseValue, 10.0)), SAT(0.1));

    return Hit(smin(box, min(sphereA, sphereB), 0.15), mixMaterial(m, b, n));
}

vec3 norm(vec3 p)
{
    vec2 e = vec2(0.0, EPSILON);
    return normalize(scene(p).dist - vec3(
        scene(p - e.yxx).dist,
        scene(p - e.xyx).dist,
        scene(p - e.xxy).dist
    ));
}

vec3 blinnPhong(vec3 n, vec3 v, vec3 l, in Material material)
{
    vec3 h = normalize(v + l);
    vec3 r = -reflect(n, l);
    float NdotL = max(0.0, dot(n, l));
    float HdotR = max(0.0, dot(h, r));
    
    vec3 ambient = vec3(0.2);
    vec3 diffuse = vec3(0.6);
    vec3 specular = vec3(1.0);
    
    return (ambient) + (diffuse * NdotL) + (specular * pow(HdotR, 1024.0));
}

float NormalDistributionFunction_GGXTR(vec3 n, vec3 m, float a)
{
    float a2 = a * a;
    float NdotM = max(0.0, dot(n, m));
    float NdotM2 = NdotM * NdotM;
    float denom = (NdotM * (a2 - 1.0) + 1.0);
    denom = PI * (denom * denom);
    return a2 / denom;
}

float Geometry_GGX(vec3 n, vec3 v, float a)
{
#if 0
    float a2 = a * a;
    float NdotV = max(0.0, dot(n, v));
    float NdotV2 = NdotV * NdotV;
    float denom = NdotV + sqrt(a2 + (1.0 - a2) * NdotV2);
    return (2.0 * NdotV) / denom;
#else
    float k = (a + 1.0) * (a + 1.0) / 8.0;
    float NdotV = max(0.0, dot(n, v));
    return NdotV / (NdotV * (1.0 - k) + k);
#endif
}

float Geometry_Smith(vec3 n, vec3 v, vec3 l, float a)
{
    float g1 = Geometry_GGX(n, l, a);
    float g2 = Geometry_GGX(n, v, a);
    return g1 * g2;
}

vec3 Fresnel_Schlick(vec3 v, vec3 h, vec3 F0)
{
    float VdotH = max(0.0, dot(v, h));
    return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
}

vec3 PBR(vec3 p, vec3 n, vec3 v, vec3 l, in Material material)
{
    vec3 F0 = mix(vec3(0.04), material.albedo, material.metallic);
    vec3 h = normalize(v + l);
    float roughness = material.roughness * material.roughness;
    float D = NormalDistributionFunction_GGXTR(n, h, roughness);
    vec3 F = Fresnel_Schlick(v, h, F0);
    float G = Geometry_Smith(n, v, l, roughness);
    float NdotL = max(0.0, dot(n, l));
    float NdotV = max(0.0, dot(n, v));
    vec3 Kd = (1.0 - F) * (1.0 - material.metallic);
    vec3 radiance = vec3(2.0);
    vec3 num = D * F * G;
    float denom = 4.0 * NdotL * NdotV;
    vec3 specularBRDF = num / max(denom, EPSILON);
    
    return (material.albedo * 0.03) + ((Kd * material.albedo / PI + specularBRDF) * radiance * NdotL);
}

void main(void)
{
    vec3 lightDir = normalize(vec3(0.5, 1.0, -0.8));
    vec3 color = vec3(0.04);
    vec2 ar = vec2(resolution.x / resolution.y, 1.0);
    vec2 uv = (gl_FragCoord.xy / resolution.xy - 0.5) *  ar;
    vec3 ro = vec3(0.0, 2.0, -2.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    float t = 0.0;
    Hit hit = Hit(MAX_DIST, kInvalidMaterial);
    
    float mx = (mouse.x*resolution.x/resolution.y*2.0-1.0)*3.14;

    ro.yz *= rot(-0.2);
    rd.yz *= rot(-0.2);

    ro.xz *= rot(mx);
    rd.xz *= rot(mx);

    for (int i = 0; i < 200; ++i)
    {
        vec3 p = ro + rd * t;
        
        Hit map = scene(p);
        if (map.dist < MIN_DIST)
        {
            noiseValue = SAT(pow(length(fbmd(p).yzw),2.0));
            map = scene(p);
            hit.material = map.material;
            hit.dist = t;
            break;
        }
        t += map.dist*.5;
        if (t > MAX_DIST) break;
    }
    
    if (hit.dist < MAX_DIST)
    {
        vec3 p = ro + rd * hit.dist;
        vec3 n = norm(p);
        vec3 v = normalize(-rd);

        color = PBR(p, n, v, lightDir, hit.material);
    }
    
    color = mix(color, vec3(0.01), SAT(pow(hit.dist / 50.0, 0.9)));
    
    // tone mapping
    color = color / (color + 1.0);
    
    // gamma correction
    color = pow(color, vec3(1.0 / 2.2));
    
    glFragColor = vec4(color, 1.0);
}
