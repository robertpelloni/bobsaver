#version 420

// original https://www.shadertoy.com/view/WdK3Wz

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define fr float(frames)

const float maxDist = 200.;
const float planeDist = 2.;

float rand31(vec3 co)
{
    return fract(sin(dot(co,vec3(65.9898,
         78.233, 29.3471))) * 1537.5497);
}

float n(vec3 uv)
{
    vec3 i = floor(uv);
    vec3 luv = fract(uv);
    luv.xyz = smoothstep(0., 1., luv.xyz);
    vec3 d = vec3(1,-1,0);
    vec3 p[8];
    float r[8];

    p[0] = i;
    p[1] = i + d.zzx;
    p[2] = i + d.zxz;
    p[3] = i + d.zxx;
    p[4] = i + d.xzz;
    p[5] = i + d.xzx;
    p[6] = i + d.xxz;
    p[7] = i + d.xxx;

    for(int k = 0; k < 8; k++)
        r[k] = rand31(p[k]);

    float rx[4];

    for(int k = 0; k < 4; k++)
        rx[k] = mix(r[k], r[k+4], luv.x);

    float rxy[2];

    for(int k = 0; k < 2; k++)
        rxy[k] = mix(rx[k], rx[k+2], luv.y);

    float rxyz = mix(rxy[0], rxy[1], luv.z);

    return rxyz;
}

float noise(vec3 uv)
{
    float r = 0.;
    float p = 1.;

    for(int i = 0; i < 2; i++)
    {
        r += n(uv * p) / p;
        p *= 2.;
    }
    r *= .7;

    r -= .5;

    return r;
}

float sin01(float x)
{
    return sin(x) * 0.5 + 0.5;
}

float cos01(float x)
{
    return cos(x) * 0.5 + 0.5;
}

vec3 lightPos()
{
    return vec3(1,1,1);
}

float smin(float a, float b, float k)
{
    float h = clamp((a - b)/k + 0.5, 0., 1.);
    float m = h * (1. - h) * 0.5 * k;
    float r = mix(a, b, h) - m;
    return r;
}

vec3 cameraPos()
{
    return vec3(6,8,-6);
    float t = (fr/30.) * 0.05;

    vec3 res = vec3(
        sin(t) * 9.,
        9.,
        -cos(t) * 9.);

    return res;
}

vec3 getRay(vec2 uv)
{
    vec3 cam = cameraPos();
    vec3 origin = vec3(0, 0, 0);
    vec3 look = normalize(origin - cam);
    vec3 upGlob = vec3(0,1,0);
    vec3 right = normalize(cross(upGlob, look));
    vec3 camUp = normalize(-cross(right, look));

    vec3 p = cam + camUp * uv.y + right * uv.x;
    p += look * planeDist;

    vec3 res = p - cam;
    return normalize(res);
}

float getSphere(vec3 p, float size, vec3 origin)
{
    return length(p - origin) - size;
}

float getSphere(vec3 p, float size)
{
    return getSphere(p, size, vec3(0,0,0));
}

float getCube(vec3 p, float size)
{
    p = abs(p);
    return max(max(p.x, p.y), p.z) - size;
}

float getInfCylinder(vec3 p, float size)
{
    float l = length(vec3(p.x, p.y, 0)) - size;
    return l;
}

float getPlane(vec3 p)
{
    return p.y;
}

float inter(float a, float b)
{
    return max(a, b);
}

float un(float a, float b)
{
    return min(a, b);
}

float diff(float a, float b)
{
    return max(a, -b);
}

float getCapsule(vec3 p, vec3 a, vec3 b, float r)
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

vec2 skew(vec2 p, float a)
{
    float ca = cos(a);
    float sa = sin(a);

    mat2 m = mat2(ca, sa, -sa, ca);

    p = p * m;

    return p;
}

float getSd(vec3 p)
{
    vec3 po = p;

    float time = fr / 30.;
    float n = noise(p - vec3(0,time*.5,0));

    float res = n;

    //res = abs(res)-.015;
    res = inter(res, getCube(po, 1.7));

    return res;
}

vec3 calcNormal(vec3 p )
{
    const float h = 0.0001; // or some other value const
    vec2 k = vec2(1,-1);

    return
    normalize(
        k.xyy*getSd( p + k.xyy*h ) +
         k.yyx*getSd( p + k.yyx*h ) +
             k.yxy*getSd( p + k.yxy*h ) +
                 k.xxx*getSd( p + k.xxx*h ) );
}

float raymarch(vec3 sp, vec3 ray)
{
    float depth = 0.;

    for(int i = 0; i < 150; i++)
    {
        vec3 p = sp + ray * depth;
        float dist = getSd(p);

        if (dist <= 0.01)
          return depth;

        depth += dist;

        if (depth >= maxDist)
          return maxDist;
    }

    return maxDist;
}

float getShadow(vec3 p)
{
    vec3 lp = lightPos();
    float ld = length(lp - p);
    vec3 ray = normalize(lp - p);
    float d = raymarch(p + ray*0.2, ray);
    float res = smoothstep(0.1,1., d);
    res = res * 0.3 + 0.7;
    return res;
}

float getSpec(vec3 refRay, vec3 l)
{
    float x = dot(refRay, l);

    x = clamp(x,0.,1.);
    x = pow(x, 7.);

    return x;
}

float getHatch(vec3 l, vec3 p)
{
    float time = fr / 30.;
    p -= vec3(0,time*.5,0);
    vec3 right = normalize(cross(l, vec3(0,1,0)));
    vec3 up = (cross(l, right));

    float u = dot(p, right);
    float v = dot(p, up);
    vec2 uv = vec2(u,v)*0.3;

    float h = 0.0;//texture(iChannel0, uv).r;

    return 1.-h;
}

void main(void)
{

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv.y /= resolution.x / resolution.y;
    uv *= 2.;
    
    vec3 ray = getRay(uv);
    vec3 camPos = cameraPos();
    float d = raymarch(camPos, ray);
    float inf = step(1., maxDist - d);

    vec3 col = vec3(1.);

    if (d > 30.)
    {
        glFragColor = vec4(0);
        return;
    }

    vec3 intP = cameraPos() + d*ray;
    vec3 n = calcNormal(intP);
    vec3 lightDir = normalize(vec3(1));

    float dd = dot(n, lightDir);
    dd = dd *.5 + .5;
    
    vec3 cuv = (intP - vec3(-1.7))/3.4;

    vec3 res = col * dd * inf * cuv;

    vec3 refRay = reflect(ray, n);

    float spec = getSpec(refRay, lightDir);
    float h = getHatch(lightDir, intP);
    
    spec *= h;
    res += spec;

    glFragColor = vec4(res, 1.0);
}
