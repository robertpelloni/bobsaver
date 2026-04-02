#version 420

// original https://www.shadertoy.com/view/tlXyRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ------------------------------------------------------------------------------------
// Original "thinking..." created by kaneta : https://www.shadertoy.com/view/wslSRr
// Original Character By MikkaBouzu : https://twitter.com/mikkabouzu777
// ------------------------------------------------------------------------------------

#define saturate(x) clamp(x, 0.0, 1.0)
#define MAX_MARCH 100
#define MAX_DIST 100.

#define M_PI 3.1415926
#define M_PI2 M_PI*2.0

#define M_PI03 1.04719
#define M_PI06 2.09439

#define MAT_BLACK 1.0
#define MAT_FACE 2.0
#define MAT_BROW 3.0
#define MAT_CHEEP 4.0
#define MAT_SPHERE 5.0
#define MAT_BG1 6.0
#define MAT_BG2 7.0
#define MAT_CS 8.0

vec3 sinebow(float h) {
    vec3 r = sin((.5-h)*M_PI + vec3(0,M_PI03,M_PI06));
    return r*r;
}

float rand(vec2 st)
{
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 10000.0);
}

float rand3d(vec3 st)
{
    return fract(sin(dot(st.xyz, vec3(12.9898, 78.233, 56.787))) * 10000.0);
}

float noise(vec3 st)
{
    vec3 ip = floor(st);
    vec3 fp = smoothstep(vec3(0.), vec3(1.), fract(st));
    
    vec4 a = vec4(rand3d(ip+vec3(0.)),rand3d(ip+vec3(1.,0.,0.)),rand3d(ip+vec3(0.,1.,0.)),rand3d(ip+vec3(1.,1.,0.)));
    vec4 b = vec4(rand3d(ip+vec3(0.,0.,1.)),rand3d(ip+vec3(1.,0.,1.)),rand3d(ip+vec3(0.,1.,1.)),rand3d(ip+vec3(1.,1.,1.)));
    
    a = mix(a, b, fp.z);
    a.xy = mix(a.xy, a.zw, fp.y);
    
    return mix(a.x, a.y, fp.x);
}

// Distance functions by iq
// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdRoundBox(vec3 p, vec3 size, float r)
{
    return length(max(abs(p) - size * 0.5, 0.0)) - r;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r)
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}

float sdEllipsoid( vec3 p, vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float sdCappedTorus(in vec3 p, in vec2 sc, in float ra, in float rb)
{
  p.x = abs(p.x);
  float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
  return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

float sdPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

// Union, Subtraction, SmoothUnion (distance, Material) 
vec2 opU(vec2 d1, vec2 d2)
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec2 opS( vec2 d1, vec2 d2 )
{ 
    return (-d1.x>d2.x) ? vec2(-d1.x, d1.y): d2;
}

vec2 opSU( vec2 d1, vec2 d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2.x-d1.x)/k, 0.0, 1.0 );
    return vec2(mix( d2.x, d1.x, h ) - k*h*(1.0-h), h > 0.5 ? d1.y : d2.y); }

// Union, Subtraction, SmoothUnion (distance only)
float opUnion( float d1, float d2 ) {  return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

vec3 rotate(vec3 p, float angle, vec3 axis)
{
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

vec3 opTwist(in vec3 p, float k )
{
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return vec3(q.x, q.y, q.z);
}

vec3 TwistY(vec3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    mat3 m = mat3(
          c, 0.0,  -s,
        0.0, 1.0, 0.0,
          s, 0.0,   c
    );
    return m*p;
}

float ease_cubic_out(float p)
{
    float f = (p - 1.0);
    return f * f * f + 1.0;
}

vec3 opRep( in vec3 p, in vec3 c)
{
    return mod(p+0.5*c,c)-0.5*c;
}

vec2 opRep2D( in vec2 p, in vec2 c)
{
    return mod(p+0.5*c,c)-0.5*c;
}

// 線分と無限平面の衝突位置算出
// rayPos : レイの開始地点
// rayDir : レイの向き
// planePos : 平面の座標
// planeNormal : 平面の法線
float GetIntersectLength(vec3 rayPos, vec3 rayDir, vec3 planePos, vec3 planeNormal)
{
    return dot(planePos - rayPos, planeNormal) / dot(rayDir, planeNormal);
}

// 直方体とレイの衝突位置算出
vec2 GetIntersectBox(vec3 rayPos, vec3 rayDir, vec3 boxPos, vec3 boxSize)
{
    vec3 diff = rayPos - boxPos;
    vec3 m = 1.0 / rayDir;
    vec3 n = m * diff;
    vec3 k = abs(m) * boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    
    return vec2(tN, tF);
/*    
    if(tN > tF || tF < 0.0)
        return vec2(-1.0);    // no intersection
    
    return vec2(tN, tF);
*/
}
/////////////////////////////////////////////////////////////////////////////////////////////////
// Mikka Boze Distance Function
/////////////////////////////////////////////////////////////////////////////////////////////////
#define RAD90 (M_PI * 0.5)

float sdEar(vec3 p, float flip, float sc)
{
    p.x *= flip;
    p = rotate(p, RAD90+0.25, vec3(0,0,1));    
    return sdCappedTorus(p + vec3(0.05, 0.175, 0) * sc, vec2(sin(0.7),cos(0.7)), 0.03 * sc, 0.01 * sc);
}

#define EYE_SPACE 0.04

vec3 opBendXY(vec3 p, float k)
{
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    return vec3(m*p.xy,p.z);
}

float sdMouse(vec3 p, float sc, float ms)
{
    vec3 q = opBendXY(p, 2.0 / sc);
    
    //return sdEllipsoid(q - vec3(0,0,0.2) * sc, vec3(0.05,0.015 + sin(time * 1.) * 0.05,0.05) * sc);
    return sdEllipsoid(q - vec3(0,0,0.2) * sc, vec3(0.05, 0.02 * ms,0.2 * ms) * sc);
}

float sdCheep(vec3 p, float flip, float sc)
{
    p.x *= flip;
    
    float x = 0.05;
    float z = -0.18;
    p = rotate(p, M_PI * -0.6 * (p.x - x) / sc, vec3(0,1,0));

    float d = sdCapsule(opBendXY(p + vec3(x, -0.01, z) * sc, 100.0/sc), vec3(-0.005,0.0,0) * sc, vec3(0.005, 0., 0) * sc, 0.0025 * sc);
    float d1 = sdCapsule(opBendXY(p + vec3(x+0.01, -0.01, z) * sc, 200.0/sc), vec3(-0.0026,0.0,0) * sc, vec3(0.0026, 0., 0) * sc, 0.0025 * sc);
    float d2 = sdCapsule(opBendXY(p + vec3(x+0.019, -0.015, z) * sc, -100.0/sc), vec3(-0.01,0.0,-0.01) * sc, vec3(0.0045, 0., 0.0) * sc, 0.0025 * sc);
    
    return opUnion(opUnion(d, d1), d2);
}

float sdEyeBrow(vec3 p, float flip, float sc)
{
    p.x *= flip;
    
    p = rotate(p, M_PI * -0.0225, vec3(0,0,1));
    
    //return sdRoundBox(p + vec3(0.03, -0.14,-0.125) * sc, vec3(0.015,0.0025,0.1) * sc, 0.0001);
    return sdRoundBox(p + vec3(0.03, -0.14,-0.1) * sc, vec3(0.0175,0.0025,0.1) * sc, 0.001);
}

vec2 sdBoze(vec3 p, float sc, float ms)
{    
    vec2 result = vec2(0.);
    
    // head
    float d = sdCapsule(p, vec3(0,0.05,0) * sc, vec3(0, 0.11, 0) * sc, 0.125 * sc);
    
    float d1 = sdRoundedCylinder(p + vec3(0,0.025,0) * sc, 0.095 * sc, 0.05 * sc, 0.0);
    
    d = opSmoothUnion(d, d1, 0.1 * sc);
    
    // ear
    float d2 = sdEar(p, 1.0, sc);
    d = opUnion(d, d2);
    float d3 = sdEar(p, -1.0, sc);
    d = opUnion(d, d3);

    vec2 head = vec2(d, MAT_FACE);

    // eye
    float d4 = sdCapsule(p, vec3(EYE_SPACE, 0.06, 0.125) * sc, vec3( EYE_SPACE, 0.08, 0.125) * sc, 0.0175 * sc);
    float d5 = sdCapsule(p, vec3(-EYE_SPACE,0.06, 0.125) * sc, vec3(-EYE_SPACE, 0.08, 0.125) * sc, 0.0175 * sc);
    vec2 eye = vec2(opUnion(d4, d5), MAT_BLACK);
    
    // mouse
    float d6 = sdMouse(p, sc, ms);
    vec2 mouse = vec2(d6, MAT_BROW);
    
    // cheep
    float d7 = sdCheep(p, 1.0, sc);
    float d8 = sdCheep(p, -1.0, sc);
    vec2 cheep = vec2(opUnion(d7, d8), MAT_CHEEP);

    // eyebrows
    float d9 = sdEyeBrow(p, 1.0, sc);
    float d10 = sdEyeBrow(p, -1.0, sc);
    eye.x = opUnion(eye.x, opUnion(d9, d10));
    //eye.x = opUnion(d9, d10);
    
    mouse = opU(eye, mouse);
    result = opS(mouse, head);
    result = opU(cheep, result);
    
    
    return result;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// End of Mikka Boze
/////////////////////////////////////////////////////////////////////////////////////////////////

vec2 map(vec3 p)
{
    vec2 result = vec2(0.);
    p = rotate(p, M_PI, vec3(0,1,0));
    //p = rotate(p, time, vec3(0,1,0));
    //p = rotate(p, time, vec3(1,0,0));
    result = sdBoze(p, 1.0, 1.0);
    //result = sdBoze(p, (sin(time) * 0.5 + 0.5) * 1.5);
    
    // background
    vec2 bg1 = vec2(sdPlane(p + vec3(0., 0.1, 0.), vec4(0,1,0,0)), MAT_BG1);
    
    vec3 q = opRep(p, vec3(0.5));
    q = TwistY(q, 2.*M_PI2);
    q = rotate(q, time*M_PI, vec3(0,1,0));
    q += vec3(0.01,0,0.01);
    float w = 0.025;
    vec2 bg2 = vec2(sdRoundBox(q, vec3(w,0.5,w), 0.01), MAT_BG2);
    
    result = opU(result, opSU(bg1, bg2, 0.2));
    //result = opU(bg1, result);
    //result = opSU(bg1, result, sin(time)*0.01+0.01);
    //result = opU(bg2, result);
    //result = opSU(bg2, result, sin(time)*0.1+0.1);
    return result;
}

#if 0
vec3 norm(vec3 p)
{
    vec2 e=vec2(.00001,.0);
    return normalize(.000001+map(p).x-vec3(map(p-e.xyy).x,map(p-e.yxy).x,map(p-e.yyx).x));
}
#else

vec3 norm(in vec3 position) {
    vec3 epsilon = vec3(0.001, 0.0, 0.0);
    vec3 n = vec3(
          map(position + epsilon.xyy).x - map(position - epsilon.xyy).x,
          map(position + epsilon.yxy).x - map(position - epsilon.yxy).x,
          map(position + epsilon.yyx).x - map(position - epsilon.yyx).x);
    return normalize(n);
}
#endif

float shadow(in vec3 origin, in vec3 direction) {
    float hit = 1.0;
    float t = 0.02;
    
    for (int i = 0; i < MAX_MARCH; i++) {
        float h = map(origin + direction * t).x;
        if (h < 0.0001) return 0.0;
        t += h;
        hit = min(hit, 10.0 * h / t);
        if (t >= 2.5) break;
    }

    return clamp(hit, 0.0, 1.0);
}

vec2 traceRay(in vec3 origin, in vec3 direction) {
    float material = 0.0;

    float t = 0.02;
    
    vec3 pos;
    for (int i = 0; i < MAX_MARCH; i++) {
        pos = origin + direction * t;
        vec2 hit = map(pos);

        t += hit.x;
        material = hit.y;

        if (hit.x <= 0.0001 ) {
            break;
        }

        
    }
    if (t >= MAX_DIST) {
        t = MAX_DIST;
        material = 0.0;        
    }
    return vec2(t, material);
}

vec3 materialColor(vec3 pos, vec2 mat, out float roughness, out float metalness)
{
    vec3 col = vec3(0);
    
    //float t = saturate(sin(time * 2.5)*0.25+0.25);
    float m = 0.1;
    //float r = mix(0.00001, 1., sin(time * 5.)*0.5+0.5);
    float r = 0.1;
    if(mat.y == MAT_BLACK) {
        col = vec3(0.1);
        roughness = r;
        metalness = m;
    } else if(mat.y == MAT_FACE) {
        col = vec3(1.0, 0.8, 0.45);
        roughness = r;
        metalness = m;
    } else if(mat.y == MAT_BROW) {
        col = vec3(1.0, 0, 0.1);
        roughness = r;
        metalness = m*0.1;
    } else if(mat.y == MAT_CHEEP) {
        col = vec3(1.0, 0.3, 0.5);
        roughness = r;
        metalness = m;
    } else if(mat.y == MAT_BG1) {
        vec3 index = floor(pos * 10.+ 0.5);

        float f = noise(index + time * 2.8);
        col = mix(vec3(1), vec3(0), f);
        //col = vec3(0.25) + vec3(0.75) * mod(mod(index.x + index.y, 2.0) + index.z + index.y, 2.0);
        roughness = 0.001;
        metalness = 0.8;
    } else if(mat.y == MAT_BG2) {
        vec3 index = floor(pos * 50.+ 0.5);
        float f = noise(index + time * vec3(2.8,-0.8,0.79));
        col = sinebow(f);
        //col = vec3(1.0,0,0) + vec3(-1,0,1) * mod(mod(index.x + index.y, 2.0) + index.z + index.y, 2.0);
        roughness = 0.001;
        metalness = 0.8;
    }
    return col;
}

//------------------------------------------------------------------------------
// BRDF
//------------------------------------------------------------------------------

float pow5(float x) {
    float x2 = x * x;
    return x2 * x2 * x;
}

float D_GGX(float linearRoughness, float NoH, const vec3 h) {
    // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
    float oneMinusNoHSquared = 1.0 - NoH * NoH;
    float a = NoH * linearRoughness;
    float k = linearRoughness / (oneMinusNoHSquared + a * a);
    float d = k * k * (1.0 / M_PI);
    return d;
}

float V_SmithGGXCorrelated(float linearRoughness, float NoV, float NoL) {
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    float a2 = linearRoughness * linearRoughness;
    float GGXV = NoL * sqrt((NoV - a2 * NoV) * NoV + a2);
    float GGXL = NoV * sqrt((NoL - a2 * NoL) * NoL + a2);
    return 0.5 / (GGXV + GGXL);
}

vec3 F_Schlick(const vec3 f0, float VoH) {
    // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
    return f0 + (vec3(1.0) - f0) * pow5(1.0 - VoH);
}

float F_Schlick(float f0, float f90, float VoH) {
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

float Fd_Burley(float linearRoughness, float NoV, float NoL, float LoH) {
    // Burley 2012, "Physically-Based Shading at Disney"
    float f90 = 0.5 + 2.0 * linearRoughness * LoH * LoH;
    float lightScatter = F_Schlick(1.0, f90, NoL);
    float viewScatter  = F_Schlick(1.0, f90, NoV);
    return lightScatter * viewScatter * (1.0 / M_PI);
}

float Fd_Lambert() {
    return 1.0 / M_PI;
}

//------------------------------------------------------------------------------
// Indirect lighting
//------------------------------------------------------------------------------

vec3 Irradiance_SphericalHarmonics(const vec3 n) {
    // Irradiance from "Ditch River" IBL (http://www.hdrlabs.com/sibl/archive.html)
    return max(
          vec3( 0.754554516862612,  0.748542953903366,  0.790921515418539)
        + vec3(-0.083856548007422,  0.092533500963210,  0.322764661032516) * (n.y)
        + vec3( 0.308152705331738,  0.366796330467391,  0.466698181299906) * (n.z)
        + vec3(-0.188884931542396, -0.277402551592231, -0.377844212327557) * (n.x)
        , 0.0);
}

vec2 PrefilteredDFG_Karis(float roughness, float NoV) {
    // Karis 2014, "Physically Based Material on Mobile"
    const vec4 c0 = vec4(-1.0, -0.0275, -0.572,  0.022);
    const vec4 c1 = vec4( 1.0,  0.0425,  1.040, -0.040);

    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;

    return vec2(-1.04, 1.04) * a004 + r.zw;
}

vec3 calcAmb(vec3 pos, vec3 rayDir, vec3 normal, vec3 lightDir, vec3 lightColor, vec3 baseColor, float roughness, float metallic) {
    vec3 color = vec3(0);
    vec3 viewDir = normalize(-rayDir);
    vec3 halfV = normalize(viewDir + lightDir);
    vec3 r = normalize(reflect(rayDir, normal));

    float NoV = abs(dot(normal, viewDir)) + 1e-5;
    float NoL = saturate(dot(normal, lightDir));
    float NoH = saturate(dot(normal, halfV));
    float LoH = saturate(dot(lightDir, halfV));
    
    float indirectIntensity = 0.64;
    
    float linearRoughness = roughness * roughness;
    vec3 diffuseColor = (1.0 - metallic) * baseColor.rgb;
    vec3 f0 = 0.04 * (1.0 - metallic) + baseColor.rgb * metallic;
    
    float attenuation = shadow(pos, lightDir);
    
    // specular BRDF
    float D = D_GGX(linearRoughness, NoH, halfV);
    float V = V_SmithGGXCorrelated(linearRoughness, NoV, NoL);
    vec3  F = F_Schlick(f0, LoH);
    vec3 Fr = (D * V) * F;

    // diffuse BRDF
    vec3 Fd = diffuseColor * Fd_Burley(linearRoughness, NoV, NoL, LoH);
    
    color = Fd + Fr;
    color *= (attenuation * NoL) * lightColor;
     
     // diffuse indirect
    vec3 indirectDiffuse = Irradiance_SphericalHarmonics(normal) * Fd_Lambert();
    
    vec2 indirectHit = traceRay(pos, r);
    vec3 indirectSpecular = vec3(0.65, 0.85, 1.0) + r.y * 0.72;
    
    if (indirectHit.y > 0.0) {
        vec3 indirectPosition = pos + indirectHit.x * r;        
        float reflength = length(indirectPosition - pos);
        
        float roughness, metalness;
        indirectSpecular = materialColor(indirectPosition, indirectHit, roughness, metalness);

        vec3 sky = vec3(0.65, 0.85, 1.0) + r.y * 0.72;
        // fog
        indirectSpecular = mix(indirectSpecular, 0.8 * sky, 1.0 - saturate(exp2(-0.1 * reflength * reflength)));
    }
    
    // indirect contribution
    vec2 dfg = PrefilteredDFG_Karis(roughness, NoV);
    vec3 specularColor = f0 * dfg.x + dfg.y;
    vec3 ibl = diffuseColor * indirectDiffuse + indirectSpecular * specularColor;
    
    color += ibl * indirectIntensity;

    return color;
}

//------------------------------------------------------------------------------
// Tone mapping and transfer functions
//------------------------------------------------------------------------------

vec3 Tonemap_ACES(const vec3 x) {
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

vec3 OECF_sRGBFast(const vec3 linear) {
    return pow(linear, vec3(1.0 / 2.2));
}

///////////////
vec3 fresnelSchlick_roughness(vec3 F0, float cosTheta, float roughness) {
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

// Unreal Engine Ambient BRDF Approx
// https://www.unrealengine.com/en-US/blog/physically-based-shading-on-mobile?lang=en-US
vec3 EnvBRDFApprox( vec3 SpecularColor, float Roughness, float NoV )
{
    const vec4 c0 = vec4( -1, -0.0275, -0.572, 0.022 );
    const vec4 c1 = vec4( 1, 0.0425, 1.04, -0.04 );
    vec4 r = Roughness * c0 + c1;
    float a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
    vec2 AB = vec2( -1.04, 1.04 ) * a004 + r.zw;
    return SpecularColor * AB.x + AB.y;
}

vec3 calcAmbient(vec3 pos, vec3 albedo, float metalness, float roughness, vec3 N, vec3 V, float t)
{
    vec3 F0 = mix(vec3(0.04), albedo, metalness);
    vec3 F  = fresnelSchlick_roughness(F0, max(0.0, dot(N, V)), roughness);
    vec3 kd = mix(vec3(1.0) - F, vec3(0.0), metalness);
    
    float aoRange = t/20.0;
    float occlusion = max( 0.0, 1.0 - map( pos + N*aoRange ).x/aoRange );
    occlusion = min(exp2( -.8 * pow(occlusion, 2.0) ), 1.0);
    
    vec3 ambientColor = vec3(0.5);
    
    vec3 diffuseAmbient = kd * albedo * ambientColor * min(1.0, 0.75+0.5*N.y) * 3.0;
    vec3 R = reflect(-V, N);
    
    vec3 col = mix(vec3(0.5) * pow( 1.0-max(-R.y,0.0), 4.0), ambientColor, pow(roughness, 0.5));
    vec3 ref = EnvBRDFApprox(F0, roughness, max(dot(N, V), 0.0));
    vec3 specularAmbient = col * ref;

    diffuseAmbient *= occlusion;
    return vec3(diffuseAmbient + specularAmbient);
}

vec3 materialize(vec3 p, vec3 ray, float depth, vec2 mat)
{
    vec3 col = vec3(0.65, 0.85, 1.0);
    //vec3 sky = vec3(0);
    vec3 sky = vec3(0.65, 0.85, 1.0) + ray.y * 0.72;
    //vec3 sky = vec3(1);
    if (depth >= MAX_DIST) {
        col = sky;
    } else {
        if(mat.y > 0.0)
        {
            vec3 nor = norm(p);            
            float roughness, metalness;
            col = materialColor(p, mat, roughness, metalness);

            vec3 result = vec3(0.);
            //result += calcAmbient(p, col, metalness, roughness, nor, -ray, depth);
            result = calcAmb(p, ray, nor, normalize(vec3(0.6, 0.8, -0.7)), vec3(0.98, 0.92, 0.89) * 3.0, col, roughness, metalness);
            col = result;
        }
    }
    
    // Tone mapping
    col = Tonemap_ACES(col);

    // Exponential distance fog
    col = mix(col, 0.8 * sky, 1.0 - saturate(exp2(-0.1 * depth * depth)));

    // Gamma compression
    col = OECF_sRGBFast(col);
    return col;
}

vec3 render(vec3 p, vec3 ray)
{
    vec3 pos;
    vec2 mat = traceRay(p, ray);
    
    p = p + mat.x * ray;
    return materialize(p, ray, mat.x, mat);
}

mat3 camera(vec3 ro, vec3 ta, float cr )
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    float t = time * M_PI * 0.2;
    float y = sin(t * 2.5) * 0.25;
    float r = 1. + sin(t * 0.5)*0.5;
    float theta = t + RAD90 + RAD90*0.25;
    //vec3 ro = vec3( 0., 0.05, -0.75 );
    vec3 ro = vec3(cos(theta) * r, 0.24 + y, -sin(theta) * r);
    vec3 ta = vec3(0., 0.05, 0.);
    
    mat3 c = camera(ro, ta, 0.0);
    vec3 ray = c * normalize(vec3(p, 3.5));
    vec3 col = render(ro, ray);
    
    glFragColor = vec4(col,1.0);
}
