#version 420

// original https://www.shadertoy.com/view/WlffWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAT_FLOOR 0.0
#define MAT_SPHERE 1.0

const float pi = acos(-1.);

vec2 opU(vec2 d1, vec2 d2)
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec2 map(vec3 p)
{
    vec2 plane = vec2(p.y + 1.0, MAT_FLOOR);
    p -=  vec3(0.0, -0.5, 0.0);
    vec3 l = vec3(5.0, 0.0, 5.0);
    vec3 q = p-clamp(round(p),-l,l);
    vec2 d = vec2(length(q) - 0.49, MAT_SPHERE);
    return opU(d, plane);
}

vec3 normal( vec3 pos, float eps )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*eps;
    return normalize( e.xyy*(map( pos + e.xyy ).x) +
                      e.yyx*(map( pos + e.yyx ).x) +
                      e.yxy*(map( pos + e.yxy ).x) +
                      e.xxx*(map( pos + e.xxx ).x) );
}

float ndfGGX(float NdotH, float roughness)
{
    float alpha   = roughness * roughness;
    float alphaSq = alpha * alpha;

    float denom = (NdotH * NdotH) * (alphaSq - 1.0) + 1.0;
    return alphaSq / (pi * denom * denom);
}

float gaSchlickG1(float cosTheta, float k)
{
    return cosTheta / (cosTheta * (1.0 - k) + k);
}

float gaSchlickGGX(float NdotL, float NdotV, float roughness)
{
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;
    return gaSchlickG1(NdotL, k) * gaSchlickG1(NdotV, k);
}

vec3 fresnelSchlick(vec3 F0, float cosTheta)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 fresnelSchlickWithRoughness(vec3 F0, float cosTheta, float roughness) {
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 skyColor(vec3 rd, float roughness)
{
    vec3 baseColor = mix(vec3(0.3,0.5,0.8)*0.8, vec3(0.3,0.5,0.8) * 0.5, rd.y);
    baseColor = mix( baseColor, vec3(0.2,0.5,0.85)*0.5, 1.0 - pow(1.0-max(-rd.y,0.0), 1.5));
    vec3 skyColor = baseColor;
    skyColor = mix( skyColor, vec3(0.9,1.1,1.2) * 1.5, pow( 1.0-max(rd.y,0.0), 8.0 ) );
    skyColor = mix( skyColor, vec3(0.2,0.5,0.85)*0.2, 1.0 - pow(1.0-max(-rd.y,0.0), 6.0));
    
    return mix(skyColor, baseColor, pow(roughness, 0.1)) * 10.0;
}

float so(float NoV, float ao, float roughness) {
    return clamp(pow(NoV + ao, exp2(-16.0 * roughness - 1.0)) - 1.0 + ao, 0.0, 1.0);
}

float shadow(in vec3 p, in vec3 l)
{
    float t = 0.01;
    float t_max = 20.0;
    
    float res = 1.0;
    for (int i = 0; i < 128; ++i)
    {
        if (t > t_max) break;
        
        float d = map(p + t*l).x;
        if (d < 0.001)
        {
            return 0.0;
        }
        t += d;
        res = min(res, 10.0 * d / t);
    }
    
    return res;
}

vec3 ambientLighting(vec3 pos, vec3 albedo, float metalness, float roughness, vec3 N, vec3 V, float aoRange)
{
    vec3 diffuseIrradiance = skyColor(N, 1.0);
    vec3 diffuseAmbient = diffuseIrradiance * albedo * (1.0 - metalness);

    vec3 R = reflect(-V, N);
    vec3 F0 = mix(vec3(0.04), albedo, metalness);
    vec3 F  = fresnelSchlickWithRoughness(F0, max(0.0, dot(N, V)), roughness);
    vec3 specularIrradiance = skyColor(R, roughness);
    vec3 specularAmbient = specularIrradiance * F;

    float ambientOcclusion = max( 0.0, 1.0 - map( pos + N*aoRange ).x/aoRange );
    ambientOcclusion = min(exp2( -.8 * pow(ambientOcclusion, 2.0) ), 1.0) * min(1.0, 1.0+0.5*N.y);
    diffuseAmbient *= ambientOcclusion;
    specularAmbient *= so(max(0.0, dot(N, V)), ambientOcclusion, roughness);

    return vec3(diffuseAmbient + specularAmbient);
}

vec3 directLighting(vec3 pos, vec3 albedo, float metalness, float roughness, vec3 N, vec3 V, vec3 L, vec3 lightColor)
{
    vec3 H = normalize(L + V);
    float NdotV = max(0.0, dot(N, V));
    float NdotL = max(0.0, dot(N, L));
    float NdotH = max(0.0, dot(N, H));
    float HdotL = max(0.0, dot(H, L));
        
    vec3 F0 = mix(vec3(0.04), albedo, metalness);

    vec3 F  = fresnelSchlick(F0, HdotL);
    float D = ndfGGX(NdotH, roughness);
    float G = gaSchlickGGX(NdotL, NdotV, roughness);
    vec3 specularBRDF = (F * D * G) / max(0.0001, 4.0 * NdotL * NdotV);

    vec3 kd = mix(vec3(1.0) - F, vec3(0.0), metalness);
    vec3 diffuseBRDF = kd * albedo / pi;
    
    float shadow = shadow(pos + N * 0.01, L);
    vec3 irradiance = lightColor * NdotL * shadow;

    return (diffuseBRDF + specularBRDF) * irradiance;
}

vec3 sunDir = normalize(vec3(.3, .45, .5));

#define repid(p, r) (floor((p + r*.5) / r))

vec3 materialize(vec3 p, vec3 ray, float depth, vec2 mat)
{
    vec3 col = vec3(0.0);
    vec3 sky = skyColor(ray, 0.0);
    vec3 albedo = vec3(1.0, 0.5, 0.1), emissive = vec3(0.0);
    
    vec2 id = repid(p.xz, vec2(1.0, 1.0)) / 10.0 + 0.5;
    float metalness = 1.0 - max(id.y, 0.0);
    float roughness = max(1.0 - id.x, 0.05);
    albedo *= mix(0.4, 1.0, metalness);
    
    if (depth > 200.0) {
        return sky;
    } else if (mat.y == MAT_FLOOR) {
        float checker = mod(floor(p.x) + floor(p.z), 2.0);
        albedo = vec3(0.4) * checker + 0.05;
        roughness = (0.2 + (1.0 - checker) * 0.45);
        metalness = 0.0;
    }
    vec3 n = normal(p, 0.005);
    
    col += directLighting(p, albedo, metalness, roughness, n, -ray, normalize(sunDir), vec3(1.0, 0.98, 0.95) * 100.);
    col += ambientLighting(p, albedo, metalness, roughness, n, -ray, depth / 30.0);
    col += emissive;
    
    float fo = exp(-0.006*depth);
    col = mix( sky, col, fo );

    return col;
}

vec3 trace(vec3 p, vec3 ray)
{
    float t = 0.1;
    vec3 pos;
    vec2 mat;
    for (int i = 0; i < 128; i++) {
        pos = p + ray * t;
        mat = map(pos);
        if (mat.x < 0.001) {
            break;
        }
        t += abs(mat.x);
    }
    return materialize(pos, ray, t, mat);
}

mat3 camera(vec3 ro, vec3 ta, float cr )
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

float luminance(vec3 col)
{
    return dot(vec3(0.298912, 0.586611, 0.114478), col);
}

vec3 acesFilm(const vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d ) + e), 0.0, 1.0);
}

vec3 reinhard(vec3 col, float exposure, float white) {
    col *= exposure;
    white *= exposure;
    float lum = luminance(col);
    return (col * (lum / (white * white) + 1.0) / (lum + 1.0));
}

vec3 render(vec2 p) {
    float time2 = time * 3.0;
    vec3 ro = vec3(cos(time2*0.1) * 15.0, 10.75, sin(time2*0.1) * 15.0);
    vec3 ta = vec3(0.0, -1.5, 0.0);
    mat3 c = camera(ro, ta, 0.0);
    vec3 ray = c * normalize(vec3(p, 3.5));
    return trace(ro, ray);
}

void main(void)
{
    //vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    vec3 col = vec3(0.0);

    // AA
    // https://www.shadertoy.com/view/Msl3Rr
    for(int y = 0; y < 3; y++) {
        for(int x = 0; x < 3; x++) {
            vec2 off = vec2(float(x),float(y))/3.;
            vec2 xy = (-resolution.xy+2.0*(gl_FragCoord.xy+off)) / resolution.y;
            //col += reinhard(render(xy), .12, 100.0)/9.;
            col += acesFilm(render(xy) * .06)/9.;
        }
    }
    
    //col = render(p) * 0.1;
    
    //col = reinhard(col, .3, 100.0);
    col = pow(col, vec3(1.0/2.2));
    glFragColor = vec4(col, 1.0);
}
