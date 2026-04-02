#version 420

// original https://www.shadertoy.com/view/lsKczW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.1415926535897932384626;

// a simple scene: just 5 spheres

float sphere(in vec3 rayOri, in vec3 rayDir, in vec3 center, in float r)
{
    vec3 oc = rayOri - center;
    float a = dot(rayDir, rayDir);
    float b = 2.0 * dot(rayDir, oc);
    float c = dot(oc, oc) - r * r;
    float delta = b * b - 4.0 * a * c;
    if (delta < 1e-9)
        return 1e9;
    return (-b - sqrt(delta)) / (2.0 * a);
}

vec3 getNormal(in vec3 p)
{
    vec3 d = p - vec3(0.0, 0.0, -10.0);
    if (dot(d, d) <= 4.0)
        return normalize(d);
    
    for (int i = 0; i < 8; i++)
    {
        vec3 o = vec3(3.2 * cos(float(i) * pi * 0.25), 3.2 * sin(float(i) * pi * 0.25), -10.0);
        d = p - o;
        if (dot(d, d) <= 1.0)
            return normalize(d);
    }
    
    return vec3(0.0, 0.0, 0.0);
}

float findIntersection(in vec3 rayOri, in vec3 rayDir)
{
    float t = 1e9;
    t = min(t, sphere(rayOri, rayDir, vec3(0.0, 3.2, -10.0), 1.0));
    t = min(t, sphere(rayOri, rayDir, vec3(0.0, -3.2, -10.0), 1.0));
    t = min(t, sphere(rayOri, rayDir, vec3(3.2, 0.0, -10.0), 1.0));
    t = min(t, sphere(rayOri, rayDir, vec3(-3.2, 0.0, -10.0), 1.0));
    for (int i = 0; i < 8; i++)
    {
        vec3 o = vec3(3.2 * cos(float(i) * pi * 0.25), 3.2 * sin(float(i) * pi * 0.25), -10.0);
        t = min(t, sphere(rayOri, rayDir, o, 1.0));
    }
    t = min(t, sphere(rayOri, rayDir, vec3(0.0, 0.0, -10.0), 2.0));
    return t;
}

// iridescence
const mat3 XYZ2RGB = mat3(2.3706743, -0.5138850, 0.0052982, 
                          -0.9000405, 1.4253036, -0.0146949, 
                          -0.4706338, 0.0885814, 1.0093968);
const float eta2 = 2.0;
const float eta3 = 3.0;
const float kappa3 = 0.5;
const float alpha = 0.15;

float sqr(in float x)
{
    return x * x;
}

float GGX(in float NdotH, in float a)
{
    return sqr(a) / (pi * sqr(sqr(NdotH) * (sqr(a) - 1.0) + 1.0));
}

float smithG1_GGX(in float NdotV, in float a)
{
    return 2.0 / (1.0 + sqrt(1.0 + sqr(a) * (1.0 - sqr(NdotV)) / sqr(NdotV)));
}

float smithG_GGX(in float NdotL, float NdotV, float a)
{
    return smithG1_GGX(NdotL, a) * smithG1_GGX(NdotV, a);
}

void fresnelDielectric(in float cost1, in float n1, in float n2, out vec2 R, out vec2 phi)
{
    float sint1 = (1.0 - sqr(cost1));
    float nr = n1 / n2;
    
    if (sqr(nr) * sint1 > 1.0)
    {
        vec2 R = vec2(1.0, 1.0);
        phi = 2.0 * atan(vec2(-sqr(nr) * sqrt(sint1 - 1.0 / sqr(nr)) / cost1,
                             -sqrt(sint1 - 1.0 / sqr(nr)) / cost1));
    }
    else
    {
        float cost2 = sqrt(1.0 - sqr(nr) * sint1);
        vec2 r = vec2((n2 * cost1 - n1 * cost2) / (n2 * cost1 + n1 * cost2),
                     (n1 * cost1 - n2 * cost2) / (n1 * cost1 + n2 * cost2));
        phi.x = r.x < 0.0 ? pi : 0.0;
        phi.y = r.y < 0.0 ? pi : 0.0;
        R = r * r;
    }
}

void fresnelConductor(in float cost1, in float n1, in float n2, in float k, out vec2 R, out vec2 phi)
{
    if (k == 0.0)
        fresnelDielectric(cost1, n1, n2, R, phi);
    else
    {
        float A = sqr(n2) * (1.0 - sqr(k)) - sqr(n1) * (1.0 - sqr(cost1));
        float B = sqrt(sqr(A) + sqr(2.0 * sqr(n2) * k));
        float U = sqrt((A + B) / 2.0);
        float V = sqrt((B - A) / 2.0);
        
        R.y = (sqr(n1 * cost1 - U) + sqr(V)) / (sqr(n1 * cost1 + U) + sqr(V));
        phi.y = atan(2.0 * n1 * V * cost1, sqr(U) + sqr(V) - sqr(n1 * cost1)) + pi;
        
        R.x = (sqr(sqr(n2) * (1.0 - sqr(k)) * cost1 - n1 * U) + sqr(2.0 * sqr(n2) * k * cost1 - n1 * V)) /
            (sqr(sqr(n2) * (1.0 - sqr(k)) * cost1 + n1 * U) + sqr(2.0 * sqr(n2) * k * cost1 + n1 * V));
        phi.x = atan(2.0 * n1 * sqr(n2) * cost1 * (2.0 * k * U - V * (1.0 - sqr(k))),
                    sqr(sqr(n2) * (1.0 + sqr(k)) * cost1) - sqr(n1) * (sqr(U) + sqr(V)));
    }
}

vec3 evalSensitivity(float opd, float shift)
{
    float phase = 2.0 * pi * opd * 1.0e-6;
    vec3 val = vec3(5.4856e-13, 4.4201e-13, 5.2481e-13);
    vec3 pos = vec3(1.6810e06, 1.7953e06, 2.2084e06);
    vec3 var = vec3(4.3278e09, 9.3046e09, 6.6121e09);
    vec3 xyz = val * sqrt(2.0 * pi * var) * cos(pos * phase + shift) * exp(-var * sqr(phase));
    xyz.x += 9.7470e-14 * sqrt(2.0 * pi * 4.5282e09) * cos(2.2399e06 * phase + shift) * exp(-4.5282e09 * sqr(phase));
    return xyz / 1.0685e-7;
}

vec3 brdf(in vec3 L, in vec3 V, in vec3 N, in float dinc)
{
    float eta_2 = mix(1.0, eta2, smoothstep(0.0, 0.03, dinc));
    
    float NdotL = dot(N, L);
    float NdotV = dot(N, V);
    if (NdotL < 0.0 || NdotV < 0.0)
        return vec3(0.0);
    vec3 H = normalize(L + V);
    float NdotH = dot(N, H);
    float cost1 = dot(H, L);
    float cost2 = sqrt(1.0 - sqr(1.0 / eta_2) * (1.0 - sqr(cost1)));
    
    vec2 R12, phi12;
    fresnelDielectric(cost1, 1.0, eta_2, R12, phi12);
    vec2 R21 = R12;
    vec2 T121 = vec2(1.0) - R12;
    vec2 phi21 = vec2(pi) - phi12;
    
    vec2 R23, phi23;
    fresnelConductor(cost2, eta_2, eta3, kappa3, R23, phi23);
    
    float opd = dinc * cost2;
    vec2 phi2 = phi21 + phi23;
    
    vec3 I = vec3(0.0);
    vec2 R123 = R12 * R23;
    vec2 r123 = sqrt(R123);
    vec2 Rs = T121 * T121 * R23 / (1.0 - R123);
    
    vec2 C0 = R12 + Rs;
    vec3 S0 = evalSensitivity(0.0, 0.0);
    I += (C0.x + C0.y) * 0.5 * S0;
    
    vec2 Cm = Rs - T121;
    for (int m = 1; m <= 3; m++)
    {
        Cm *= r123;
        vec3 SmS = 2.0 * evalSensitivity(float(m) * opd, float(m) * phi2.x);
        vec3 SmP = 2.0 * evalSensitivity(float(m) * opd, float(m) * phi2.y);
        I += (Cm.x * SmS + Cm.y * SmP) * 0.5;
    }
    
    I = clamp(XYZ2RGB * I, vec3(0.0), vec3(1.0));
    float D = GGX(NdotH, alpha);
    float G = smithG_GGX(NdotL, NdotV, alpha);
    return D * G * I / (4.0 * NdotL * NdotV);
}

vec3 render(in vec3 rayOri, in vec3 rayDir)
{
    // light
    vec3 lightPos = vec3(3.0, 3.0, 100.0);
    vec3 lightColor = vec3(1.0);
    
    // material
    float glossiness = 8.0;
    float kd = 0.3, ks = 0.7;
    
    // find intersection
    float t = findIntersection(rayOri, rayDir);
    if (t > 1e8)
        return vec3(0.25);
    
    // get important vector
    vec3 p = rayOri + (t + 0.0001) * rayDir;
    vec3 n = getNormal(p);
    vec3 l = normalize(vec3(0.0, 15.0 * cos(time), 0.0) - p);//normalize(lightPos - p);
    vec3 r = 2.0 * n * dot(n, l) - l;
    
    //ks * lightColor * pow(max(dot(r, -rayDir), 0.0), glossiness);

    // iridescence
    vec3 color = vec3(0.0);
    color += ks * brdf(l, -rayDir, normalize(l - rayDir), cos(time * 0.3 + p.y) + 1.01) * dot(l, n) * dot(r, -rayDir);
    color += kd * lightColor * max(dot(n, l), 0.0);
    return color;
}

mat3 lookAt(in vec3 eye, in vec3 center, in float angle)
{
    vec3 w = normalize(center - eye);
    vec3 up = vec3(sin(angle), cos(angle), 0.0);
    vec3 u = normalize(cross(w, up));
    vec3 v = normalize(cross(u, w));
    return mat3(u, v, w);
}

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
    p.x *= resolution.x / resolution.y;
    
    // camera to world
    vec3 eye = vec3(0.0, 0.0, 0.0);
    vec3 center = vec3(0.0, 0.0, -100.0);
    mat3 caMat = lookAt(eye, center, 0.0);
    
    // generate ray
    vec3 rayDir = caMat * normalize(vec3(p.xy, 2.0));
    
    // render
    vec3 color = render(eye, rayDir);
    glFragColor = vec4(color, 1.0);
}
