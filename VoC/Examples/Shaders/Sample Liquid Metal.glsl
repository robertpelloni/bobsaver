#version 420

// original https://www.shadertoy.com/view/7dtSDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Scene

#define NUM_REFLECTIONS 5

const float SURF_HIT = 0.01;
const float farPlane = 20.0;
const int maxSteps = 128;

// Common / Framework stuff

// -----------------------------------------------------------------------------
// Basics / Math

#define S(x, y, z) smoothstep(x, y, z)
#define animTime (mod(time, 11.))
#define A(v1,v2,t1,t2) mix(v1,v2,S(t1,t2,animTime))

float invLerp(float a, float b, float x) {
    x = clamp(x, a, b);
    return (x - a) / (b - a);
}

const float PI = 3.14159;
const float TAU = PI * 2.0;
const float DEG2RAD = PI / 180.;

float saturate(in float x) { return clamp(x, 0.0, 1.0); }
vec2 saturate(in vec2 x) { return clamp(x, vec2(0.0), vec2(1.0)); }
vec3 saturate(in vec3 x) { return clamp(x, vec3(0.0), vec3(1.0)); }
vec4 saturate(in vec4 x) { return clamp(x, vec4(0.0), vec4(1.0)); }

mat2 rot2D(float angle) {
    float ca = cos(angle), sa = sin(angle);
    return mat2(ca, -sa, sa, ca);
}

mat3 lookAtMatrix(in vec3 lookAtDirection) {
    vec3 ww = normalize(lookAtDirection);
    vec3 uu = cross(ww, vec3(0.0, 1.0, 0.0));
    vec3 vv = cross(uu, ww);
    return mat3(uu, vv, -ww);
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// -----------------------------------------------------------------------------
// Colors

vec4 linearTosRGB(vec4 linearRGB)
{
    bvec4 cutoff = lessThan(linearRGB, vec4(0.0031308));
    vec4 higher = vec4(1.055)*pow(linearRGB, vec4(1.0/2.4)) - vec4(0.055);
    vec4 lower = linearRGB * vec4(12.92);

    return mix(higher, lower, cutoff);
}

vec4 sRGBToLinear(vec4 sRGB)
{
    bvec4 cutoff = lessThan(sRGB, vec4(0.04045));
    vec4 higher = pow((sRGB + vec4(0.055))/vec4(1.055), vec4(2.4));
    vec4 lower = sRGB/vec4(12.92);

    return mix(higher, lower, cutoff);
}
   
vec4 ACESFilm(vec4 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}
   
// -----------------------------------------------------------------------------
// Hits

float smin(float a, float b, float k) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
float smax(float a, float b, float k) {
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

struct Hit {
    int id;
    float d; // means distance to surface
};

struct TraceResult {
    int id;
    float d; // means distance traveled
    vec3 ro;
    vec3 rd; 
};

Hit hmin(in Hit a, in Hit b) { if (a.d < b.d) return a; return b; }
Hit hmax(in Hit a, in Hit b) { if (a.d > b.d) return a; return b; }
Hit hsmin(in Hit a, in Hit b, in float k) {
    Hit h = hmin(a, b);
    h.d = smin(a.d, b.d, k);
    return h;
}
Hit hsmax(in Hit a, in Hit b, in float k) {
    Hit h = hmax(a, b);
    h.d = smin(a.d, b.d, k);
    return h;
}

// -----------------------------------------------------------------------------
// Materials

struct Light {
    vec3 direction;
    vec3 ambient;
    vec3 color;
};

struct Surface {
    int materialId;
    float dist;
    vec3 p;
    vec3 n;
    float ao;
    vec3 rd;
};
    
struct Material {
    vec3 albedo;
    float metallic;
    float roughness;
    vec3 emissive;
    float ao;
};

// -----------------------------------------------------------------------------
// SDFs

float sdSphere(in vec3 p, in float r) {
    return length(p) - r;
}

// -----------------------------------------------------------------------------
// Camera

struct Camera {
    vec3 position;
    vec3 direction;
};

Camera createOrbitCamera(vec2 uv, vec2 mouse, vec2 resolution, float fov, vec3 target, float height, float distanceToTarget) {
    vec2 r = mouse;
    float halfFov = fov * 0.5;
    float zoom = cos(halfFov) / sin(halfFov);
    
    vec3 position = target + vec3(0, height, 0) + vec3(sin(r.x), 0.0, cos(r.x)) * distanceToTarget ;
    vec3 direction = normalize(vec3(uv, -zoom));
    direction.yz = rot2D(-r.y) * direction.yz;
    direction = lookAtMatrix(target - position) * direction;
    
    return Camera(position, direction);
}

// -----------------------------------------------------------------------------
// PBR Implementation
// - Lamber or Burley diffuse    
// - Schlick Fresnel
// - GGX NDF
// - Smith-GGX height-correlated visibility function

// Sources
// 
// https://learnopengl.com/PBR/Lighting
// https://google.github.io/filament/Filament.html
// https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#appendix-b-brdf-implementation
    
vec3 F_Schlick_full(float HoV, vec3 f0, vec3 f90) {
    return f0 + (f90 - f0) * pow(1.0 - HoV, 5.0);
} 

vec3 F_Schlick(float HoV, vec3 f0) {
    return F_Schlick_full(HoV, f0, vec3(1.0));
} 
    
float Diff_Lambert() {
    return 1.0 / PI;
}

vec3 Diff_Burley(float NoV, float NoL, float LoH, float roughness) {
    float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
    vec3 lightScatter = F_Schlick_full(NoL, vec3(1.0), vec3(f90));
    vec3 viewScatter = F_Schlick_full(NoV, vec3(1.0), vec3(f90));
    return lightScatter * viewScatter * (1.0 / PI);
}

float D_GGX(float NoH, float a) {
    float a2 = a * a;
    float f = (NoH * a2 - NoH) * NoH + 1.0;
    return a2 / (PI * f * f);
}

float V_SmithGGXCorrelated(float NoV, float NoL, float a) {
    float a2 = a * a;
    float NoV2 = NoV*NoV;
    float NoL2 = NoL*NoL;
    float GGL = NoL * sqrt(NoV2 * (1.0 - a2) + a2);
    float GGV = NoV * sqrt(NoL2 * (1.0 - a2) + a2);
    return 0.5 / (GGL + GGV);
}

float GGX_Smith_Approx_Visibility(float NoV, float NoL, float a) {
    return 1.0 / (2.0 * mix(2.0*NoL*NoV, NoL+NoV, a));
}

vec3 BRDF(Light l, Surface surf, Material mat) {
    vec3 V = -surf.rd;
    vec3 N = surf.n;
    vec3 L = l.direction;
    vec3 H = normalize(V + L);
    
    float NoV = max(dot(N, V), 0.0);
    float NoL = max(dot(N, L), 0.0);
    float NoH = max(dot(N, H), 0.0);
    float HoV = max(dot(H, V), 0.0);
    
    vec3  albedo     = mat.albedo;
    float roughness  = mat.roughness;
    float a          = roughness * roughness;
    float metallic   = mat.metallic;
    float dielectric = 1.0 - metallic;
    
    // Constants
    vec3 dielectricSpecular = vec3(0.04);
    vec3 black = vec3(0);
    
    // Frenel term
    vec3 F0 = mix(dielectricSpecular, albedo, metallic);
    vec3 F  = F_Schlick(HoV, F0);
    
    // Normal distribution
    float D = D_GGX(NoH, a);
    
    // Visibility term
    //     should be equivalent to G / (4.0 * NoL * NoV)
    //     but it doesn't look the same as https://www.shadertoy.com/view/tdKXR3
    float Vis = V_SmithGGXCorrelated(NoV, NoL, a);
    
    // Specular BRDF Cook Torrance
    vec3 specular = F * (Vis * D);
    
    // Lambert Diffuse
    //     Should we scale by (1.0 - F) ?? gltf and learnopengl have it but filament doesn't
    //     Also what about lambert 1/PI ?? https://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
    //     PI might not be used in IBL only?
    vec3 kD = vec3(1.0) - F;
    vec3 c = mix(albedo * (1.0-dielectricSpecular), black, metallic);
    vec3 diffuse = kD * (c / PI);
    // vec3 diffuse = (1.0 - F) * diffuseColor * Diff_Burley(NoV, NoL, NoH, a);
    
    // Final Color
    vec3 fakeGI = l.ambient * mat.albedo;
    vec3 emissive = mat.emissive;
    vec3 directLight = l.color * NoL * (diffuse + specular);
    
    //return vec3(Vis)*NoL;
    return fakeGI + emissive + directLight;
}

Hit ground(in vec3 p) {
    return Hit(0, -(length(p-vec3(0, 198.8, 0)) - 200.));
}

Hit metaBall(in vec3 p) {
    vec3 q = p;
    q.y += A(cos(animTime * PI) * 1.0 + 1.7, 0.0, 0.0, 4.0);    
    if (animTime > 10.0) {
        // q.y += B(0.0, 2.5, 10.0, 12.0, vec2(0.5, -0.5), vec2(1.0, 0.0));
        float t = animTime - 10.0;
        q.y += -2.5 * t + 0.5 * 10.0 * t*t;
    }
    
    
    q.xz *= rot2D(q.y);
    
    vec3 scale = A(vec3(1), vec3(0.5, 1.0, 0.5), 10., 11.);
    q *= scale;
    
    float r = 1.0;
    r = A(r, 0.2, 10., 10.5);

    float amp = 0.1;
    amp = A(amp, sin(animTime * 30.0) * .05 + 0.1, 8.0, 10.);
    amp = A(amp, 1., 10., 10.5);
    
    r += amp * sin(q.x * 8.0 + animTime * 5.0) * sin(q.y * 8.0) * sin(q.z * 8.0);
    float sphere = sdSphere(q, r);
    
    float definition = A(0.7, 0.3, 10., 10.5);
    sphere *= definition;
    

    return Hit(1, sphere);
}

Hit ballGround(in vec3 p) {
    float blend = A(0.5, 0.0, 0.0, 8.0);
    blend = A(blend, 0.5, 10.0, 11.0);

    return hsmin(metaBall(p), ground(p), blend);
}

Hit map(in vec3 p) {
    Hit h = ballGround(p);
    return h;
}

vec3 mapNormal(in vec3 p, float surfHit) {
    vec2 e = vec2(0.01, 0.0);
     float d = map(p).d;
    return normalize(vec3(
        d - map(p - e.xyy).d,
        d - map(p - e.yxy).d,
        d - map(p - e.yyx).d
    ));
}

float calcAO( in vec3 pos, in vec3 nor ) {
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ ) {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).d;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return saturate(1.0 - 3.0*occ) * (0.5+0.5*nor.y);
}

// -----------------------------------------------------------------------------

TraceResult trace(in vec3 ro, in vec3 rd, in float maxDistance, in int maxSteps) {
    float d = 0.0;
    float closestD = maxDistance;
    Hit closest = Hit(-1, maxDistance);
    
    for (int i=0; i < maxSteps && d < maxDistance; i++) {
        vec3 p = ro + rd * d;
        Hit h = map(p);
        
        if (h.d < closest.d) {
            closest = h;
            closestD = d;
        }
        if (h.d <= SURF_HIT) return TraceResult(closest.id, d, ro, rd);
        
        d += h.d;
    }
    
    if (d >= maxDistance) {
        return TraceResult(-1, maxDistance, ro, rd);
    }

    //return Hit(closest.id, closestD);
    return TraceResult(-2, closestD, ro, rd);
}

TraceResult traceReflection(Surface s, in float maxDistance, in int maxSteps) {
    vec3 ro = s.p + s.n * SURF_HIT * 2.0;
    vec3 rd = reflect(s.rd, s.n);
    
    float d = SURF_HIT * 2.0;
    for (int i=0; i < maxSteps && d < maxDistance; i++) {
    
        vec3 p = ro + rd * d;
        Hit h = map(p);
        
        if (h.d < SURF_HIT) {
            return TraceResult(h.id, d, ro, rd);
        }
        
        d += h.d;
    }
    
    return TraceResult(-1, maxDistance, ro, rd);
}

Surface getSurf(TraceResult tr) { 
    vec3 p = tr.ro + tr.rd * tr.d;
    vec3 n = mapNormal(p, SURF_HIT);
    float ao = calcAO(p, n);
    
    return Surface(
        tr.id, // material id
        tr.d,  // distance
        p,    // position
        n,    // normal
        ao,   // ambient occlusion
        tr.rd    // view ray direction
    );
}

struct LightingResult {
    Material mat;
    vec3 color;
};

vec4 sampleEnv(in samplerCube samp, vec3 dir) {
    dir.xz = rot2D(270. * DEG2RAD) * dir.xz;
    return sRGBToLinear(texture(samp, dir));
}

Material matFromSurface(Surface s) {
    Material m;
    m.albedo    = vec3(0.0);
    m.emissive  = vec3(0.0);
    m.roughness = 1.0;
    m.metallic  = 0.0;
    m.ao = s.ao;

    if (s.materialId == -1) {
        m.albedo    = vec3(0.01);
        m.roughness = 0.85;
    } else if (s.materialId == 0) {
        m.albedo    = vec3(0.01);
        m.roughness = 0.0;
    } else if (s.materialId == 1) {
        m.albedo = vec3(0.1);
        m.roughness = 0.1;
        m.metallic = 1.0;
    } else {
        m.emissive = vec3(1, 0, 1);
    }
    
    return m;
}

vec3 calculateLights(Surface s, Material m) {
    const int lights = 2;
    Light l[2];
    l[0].direction = normalize(vec3(1, 1, 0));
    l[0].ambient = vec3(0.01);
    l[0].color = vec3(3.0);
    l[1].direction = normalize(vec3(-1, 1, 0));
    l[1].ambient = vec3(0.01);
    l[1].color = vec3(3.0);
    
    vec3 color = vec3(0);
    for (int i=0; i < lights; i++) {
        vec3 cont = BRDF(l[i], s, m);
        cont = max(cont, vec3(0));
        color += cont;
    }
    
    return color;
}

LightingResult surfaceLighting(inout Surface s) {  
    if (s.materialId == -1) {
        s.p.y += 1.1;
        vec3 n = normalize(vec3(s.p.x, s.p.y, s.p.z));

        Surface floorS = Surface(
            0,
            s.dist,
            s.p,
            vec3(0,1,0),
            s.ao,
            s.rd
        );
        Material floorM = matFromSurface(s);
        vec3 floorColor = calculateLights(floorS, floorM);
        
        float floorBlend = S(-.2, 1.2, n.y);
        
        Material m = matFromSurface(s);
        s.n = n;
        m.roughness = 1.0;
        
        vec3 color = mix(floorColor, vec3(0), floorBlend);
        
        return LightingResult(m, color);
    } else if (s.materialId == 0) {
        Material m = matFromSurface(s);
        vec3 floorColor = calculateLights(s, m);
        
        return LightingResult(m, floorColor);
    } else if (s.materialId == 1) {
        Surface floorS = Surface(
            0,
            s.dist,
            s.p,
            s.n,
            s.ao,
            s.rd
        );
        Material floorM = matFromSurface(floorS);
        vec3 floorColor = calculateLights(floorS, floorM);
        
        Material m = matFromSurface(s);
        vec3 ballColor = calculateLights(s, m);
        
        float blend = S(-1.1, -0.9, s.p.y); 
        vec3 color = mix(floorColor, ballColor, blend);
        
        m.metallic = mix(floorM.metallic, m.metallic, blend);
        m.roughness = mix(floorM.roughness, m.roughness, blend);
        
        return LightingResult(m, color);
    } else {
        // error, unset material
        Material m = matFromSurface(s);
        vec3 color = calculateLights(s, m);
        return LightingResult(m, color);
    }
}

vec3 lighting(Surface s) {
    LightingResult current = surfaceLighting(s);
    vec3 color = current.color;
    
    const int reflections = NUM_REFLECTIONS;
    float extintion = 1.0;
    
    for (int i = 0; i < reflections; i++) {
        TraceResult rh = traceReflection(s, farPlane, maxSteps);
        
        s = getSurf(rh);
        
        float refAmount = (1.0 - current.mat.roughness);
        extintion *= refAmount;
        
        current = surfaceLighting(s);
        color += extintion * saturate(current.color) * 0.6;
    }
    
    return color;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec2 screen = uv * 2.0 - 1.0;
    screen.x *= resolution.x / resolution.y;
    
    float xCam = A(0.0, -0.2, 0.0, 3.0);
    xCam = A(xCam, -0.65, 0.0, 9.0);
    xCam = A(xCam, -0.95, 8.5, 10.0);
    xCam = A(xCam, -1.0, 10.0, 11.0);
    
    float yCam = A(-0.25, -0.08, 0.3, 1.0);
    yCam = A(yCam, -0.3, 0.5, 2.5);
    yCam = A(yCam, -0.08, 0.5, 3.0);
    yCam = A(yCam, -0.06, 4.0, 10.0);
    yCam = A(yCam, 0.15, 10.0, 10.5);
    yCam = A(yCam, -0.25, 10.0, 11.0);
    
    float camDist = A(1.5, 5.5, 0.0, 2.0);
    camDist = A(camDist, 3.5, 0.0, 3.0);
    camDist = A(camDist, 4.0, 3.0, 5.0);
    camDist = A(camDist, 4.5, 4.0, 7.0);
    camDist = A(camDist, 3.5, 7.0, 10.0);
    camDist = A(camDist, 2.0, 9.5, 10.5);
    camDist = A(camDist, 2.5, 10.0, 11.);
    
    Camera cam = createOrbitCamera(
        screen, 
        vec2(xCam, yCam) *  PI, 
        resolution.xy, 
        60.0 * DEG2RAD, 
        vec3(0, 0.5, 0), 
        0.0, 
        camDist
    );

    vec3 ro = cam.position;
    vec3 rd = cam.direction;
    
    TraceResult tr = trace(ro, rd, farPlane, maxSteps);
    Surface s = getSurf(tr);
    
    vec4 col = vec4(lighting(s), 1.0);
    col = ACESFilm(col);
    col = linearTosRGB(col);
    glFragColor = col;
}
