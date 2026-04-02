#version 420

// original https://www.shadertoy.com/view/wlV3DV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define PI2 (PI/2.)

// tuneables
#define SCALE 15.0
#define ROUGH 0.25
#define REFL 0.02
#define LIGHTWRAP sin(time/2.0)*5.0 // was 5.0, this is clearly more fun
#define NUM_LIGHTS 64
#define SPHERE_RAD 1.5
#define ORBIT_DIST 4.0
#define ALBEDO vec3(0.25)
#define HUE_SHIFT_RATE 0.25
#define HUE_BAND_SCALE 0.25
#define VERTICAL_ACCUM_SIN_SCALE 0.5
#define LIGHT_INTENSITY 0.5

#define saturate(x) clamp(x, 0.0, 1.0)

// GGX code borrowed from John Hable: https://gist.github.com/Kuranes/3065139b10f2d85074da
float GGX(vec3 N, vec3 V, vec3 L, float roughness, float F0)
{
    float alpha = roughness*roughness;

    vec3 H = normalize(V+L);

    float dotNL = saturate(dot(N,L));

    float dotLH = saturate(dot(L,H));
    float dotNH = saturate(dot(N,H));

    float F, D, vis;

    // D
    float alphaSqr = alpha*alpha;
    float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0;
    D = alphaSqr/(PI * denom * denom);

    // F
    float dotLH5 = pow(1.0-dotLH,5.);
    F = F0 + (1.-F0)*(dotLH5);

    // V
    float k = alpha/2.;
    float k2 = k*k;
    float invK2 = 1.-k2;
    vis = 1./(dotLH*dotLH*invK2 + k2);

    float specular = dotNL * D * F * vis;
    return specular;
}

// blatantly stolen from https://gist.github.com/eieio/4109795 (because rainbows)
vec3 hsv_to_rgb(float h, float s, float v)
{
    float c = v * s;
    h = mod((h * 6.0), 6.0);
    float x = c * (1.0 - abs(mod(h, 2.0) - 1.0));
    vec3 color;

    if (0.0 <= h && h < 1.0) {
        color = vec3(c, x, 0.0);
    } else if (1.0 <= h && h < 2.0) {
        color = vec3(x, c, 0.0);
    } else if (2.0 <= h && h < 3.0) {
        color = vec3(0.0, c, x);
    } else if (3.0 <= h && h < 4.0) {
        color = vec3(0.0, x, c);
    } else if (4.0 <= h && h < 5.0) {
        color = vec3(x, 0.0, c);
    } else if (5.0 <= h && h < 6.0) {
        color = vec3(c, 0.0, x);
    } else {
        color = vec3(0.0, 0.0, 0.0);
    }

    color.rgb += v - c;

    return color;
}

struct PointLight
{
    vec3 pos;
    vec3 color;
};

vec3 sphereNorm(vec2 ws, vec3 c, float r)
{
    vec3 pt = vec3((ws-c.xy)/r, 0);
    pt.z = -cos(length(pt.xy)*PI2);
    return normalize(pt);
}

bool sphereTest(vec2 ws, vec3 c, float r)
{
    vec3 pt = vec3(ws-c.xy, c.z);
    return (dot(pt.xy, pt.xy) < r*r);
}

vec3 spherePos(vec2 ws, vec3 c, float r)
{
    vec3 pt = vec3(ws, c.z);
    pt.z -= cos(length((ws-c.xy)/r)*PI2)*r;
    return pt;
}

vec4 sphere(vec3 pt, vec3 N, PointLight pl, float rough, float refl)
{   
    vec3 V = vec3(0, 0, -1);
    vec3 pToL = pl.pos - pt;
    vec3 L = normalize(pToL);
    
    float decay = length(pToL);
    decay = 1./decay*decay;
    
    float diffuse = dot(N,L) / PI;
    float spec = GGX(N, V, L, rough, refl);
            
    if (dot(N,L) >= 0.)
    {
        return vec4(decay * pl.color * (spec + diffuse * ALBEDO), pt.z);
    }
    else
    {
        return vec4(0, 0, 0, pt.z);
    } 
}

struct LightAnim
{
    vec3 period;
    vec3 shift;
    vec3 orbit;
    vec3 offset;
};

PointLight getLight(vec3 color, LightAnim anim)
{
    vec3 pos = sin(time * anim.period + anim.shift) * anim.orbit + anim.offset;
    PointLight mypt = PointLight(pos, color);
    return mypt;
}

vec4 renderLight(vec2 cs, PointLight pt)
{
    return vec4(pt.color * saturate(.1 - abs(length(cs-pt.pos.xy)))*100., pt.pos.z);
}

void drawWriteZ(vec4 result, inout vec4 glFragColor)
{
    glFragColor.xyz += result.xyz;
    glFragColor.w = result.w;
}

void drawTestZ(vec4 result, inout vec4 glFragColor)
{
    if (result.w <= glFragColor.w || glFragColor.w < 0.)
    {
        glFragColor.xyz += result.xyz;
    }
}

void planet(vec2 csUv, inout vec4 glFragColor, LightAnim anim, bool isGeo, vec3 norm, vec3 pos, vec3 color)
{
    PointLight ptL = getLight(color, anim);
    
    if (isGeo)
    {
        drawWriteZ(sphere(pos, norm, ptL, ROUGH, REFL), glFragColor);
    }
    drawTestZ(renderLight(csUv, ptL), glFragColor);
}

void main(void)
{
    float aspect = resolution.x / resolution.y;
    vec2 uv = gl_FragCoord.xy / resolution.xy;       
    vec4 csUv = vec4(uv-vec2(0.5, 0.5), mouse*resolution.xy.xy/resolution.xy);
    csUv.x *= aspect;
    csUv.xy *= SCALE;   
    
    float sphereRad = SPHERE_RAD;
    float orbitDelta = ORBIT_DIST;
    float orbit = sphereRad+orbitDelta;
    
    // period, shift, orbit, offset
    LightAnim anim = LightAnim(vec3(1, 0, 1), vec3(0, PI2, PI2), vec3(orbit, 0, -orbit), vec3(0, 0, 10));
    
    vec3 sphereCenter = vec3(0, 0, 10);
    
    vec3 sPos = spherePos(csUv.xy, sphereCenter, sphereRad);
    vec3 sNorm = sphereNorm(csUv.xy, sphereCenter, sphereRad);
    bool isSphere = sphereTest(csUv.xy, sphereCenter, sphereRad);
    
    glFragColor.xyzw = vec4(0, 0, 0, -1); // lazy "depth" value
    
    const int totalPlanets=NUM_LIGHTS;
    
    for (int i = 0; i < totalPlanets; ++i)
    {
        float rat = 1.-float(i)/float(totalPlanets);
        
        float hue = mod(HUE_SHIFT_RATE*-time+rat*HUE_BAND_SCALE,1.);
        
        vec3 color = hsv_to_rgb(hue, 1., LIGHT_INTENSITY*rat);
        
        planet(csUv.xy, glFragColor, anim, isSphere, sNorm, sPos, color);
        
        anim.orbit.y += sin(time)*VERTICAL_ACCUM_SIN_SCALE; // making things more interesting...
        
        anim.shift += LIGHTWRAP*2.*PI/float(totalPlanets);
           
    }
    
    glFragColor.xyz = pow(glFragColor.xyz, 1./vec3(2.2));
}
