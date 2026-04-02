#version 420

// original https://www.shadertoy.com/view/3dSGRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 uLightDir = vec3(0.0, 1.0, 0.0);
const vec3 uLightColor = vec3(5.0,6.0,12.0);

struct Material {
    vec3 albedo;
    float roughness;
    float metallic;
};

struct Scene {
    int type;
    float dist;
    Material material;
};

struct DirLight {
    vec3 dir;
    vec3 color;
};

const Material kNoMaterial = Material(vec3(0.0), 0.0, 0.0);

mat2 Rotate(float r) { return mat2(cos(r), sin(r), -sin(r), cos(r)); }
vec3 Repeate(vec3 p, vec3 r) {
    return mod(p, r) - 0.5 * r;
}

float NormalDistributionFunctionGGXTR(vec3 n, vec3 m, float a)
{
    float a2 = a * a;
    float NdotM = max(0.0, dot(n, m));
    float NdotM2 = NdotM * NdotM;
    float denom = (NdotM * (a2 - 1.0) + 1.0);
    denom = 3.14 * (denom * denom);
    return a2 / denom;
}

float GeometryGGX(float NdotV, float a)
{
    float k = (a + 1.0) * (a + 1.0) / 8.0;
    return NdotV / (NdotV * (1.0 - k) + k);
}

float GeometrySmith(float NdotV, float NdotL, float a)
{
    float g1 = GeometryGGX(NdotL, a);
    float g2 = GeometryGGX(NdotV, a);
    return g1 * g2;
}

vec3 FresnelSchlick(vec3 v, vec3 h, vec3 F0)
{
    float VdotH = max(0.0, dot(v, h));
    return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
}

vec3 Shade(vec3 n, vec3 v, DirLight l, in Material material)
{
    vec3 F0 = mix(vec3(0.04), material.albedo, material.metallic);
    vec3 h = normalize(v + l.dir);
    float roughness = material.roughness * material.roughness;
    float NdotL = max(0.0, dot(n, l.dir));
    float NdotV = max(0.0, dot(n, v));
    float D = NormalDistributionFunctionGGXTR(n, h, roughness);
    vec3 F = FresnelSchlick(v, h, F0);
    float G = GeometrySmith(NdotV, NdotL, roughness);
    vec3 Kd = (1.0 - F) * (1.0 - material.metallic);
    vec3 radiance = l.color;
    vec3 num = D * F * G;
    float denom = 4.0 * NdotL * NdotV;
    vec3 specularBRDF = num / max(denom, .01);
    
    return (material.albedo * 0.3) + ((Kd * material.albedo / 3.14 + specularBRDF) * radiance * NdotL);
}

Scene SceneUnion(Scene a, Scene b) {
    if (a.dist < b.dist) return a;
    return b;
}

float Box(vec3 p, vec3 s) {
    vec3 d = abs(p) - s;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

// iq's
float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float Ring(vec3 p, float radius) {
    float outer = sdCappedCylinder(p, vec2(radius, 0.025));
    float inner = sdCappedCylinder(p, vec2(radius-0.05, 1.0));
    return max(outer, -inner);
}

Scene GetOuterBox(vec3 p) {
    p.xz *= Rotate(-time * .4);
    p.xy *= Rotate(0.615472907);
    p.yz *= Rotate(0.785398);
    float border = 0.95;
    float scene = Box(p, vec3(1.0));
    float boxOut = scene;
    float remove = Box(p, vec3(2.0, border, border));
    remove = min(remove, Box(p, vec3(border, 2.0, border)));
    remove = min(remove, Box(p, vec3(border, border, 2.0)));
    scene = max(scene, -remove);
    vec3 p2 = p;
    vec3 p3 = p;
    p2.xy *= Rotate(3.14 / 2.0);
    p3.yz *= Rotate(3.14 / 2.0);
    float rings = 100.;
    float ringRadius = 1.1;
    rings = min(rings, Ring(Repeate(p, vec3(0.0, 1.95, 0.0)), ringRadius));
    rings = min(rings, Ring(Repeate(p2, vec3(0.0, 1.95, 0.0)), ringRadius));
    rings = min(rings, Ring(Repeate(p3, vec3(0.0, 1.95, 0.0)), ringRadius));
    rings = max(rings, boxOut);
    return Scene(2, min(scene, rings), Material(vec3(4.0), 0.8, 0.0));
}

Scene GetInnerContent(vec3 p) {
    vec3 pmin = p;
    vec3 pmax = p;
    pmin.xz *= Rotate(-time * .4);
    pmin.xy *= Rotate(0.615472907);
    pmin.yz *= Rotate(0.785398);
    pmax.xz *= Rotate(time * 0.8 + sin(0.2 * time + p.y * 0.1));
    pmax.yz *= Rotate(time * 0.8 + sin(0.2 * time + p.y * 0.1));
    pmax.xy *= Rotate(time * 0.8 + sin(0.2 * time + p.y * 0.1));
    float clip = Box(pmin, vec3(0.85));
    vec3 pmod = Repeate(pmax + vec3(0, time * 0.5, 0), vec3(0.4));
    float dispSize = sin((sin(p.y * 2.0) + sin(p.z) + sin(p.x) + time * 3.0) * 0.25);
    float scene = Box(pmod, vec3(0.1 + 0.2 * sin(dispSize + p.y * 0.1)));

    scene = max(scene, clip);

    return Scene(1, scene, Material(vec3(0.0), 0.1, 1.0));
}

Scene GetFloor(vec3 p) {
    return Scene(1, Box(p + vec3(0.0, 2.75, 0.0), vec3(1, 1.0,1)), Material(vec3(.2,0,0), 0.8, 0.));
}

Scene GetScene(vec3 p) {
    Scene scene = Scene(0, 100., kNoMaterial);

    scene = SceneUnion(scene, Scene(3, 9.0 - p.y, Material(vec3(1), 1.0, 0.0)));
    scene = SceneUnion(scene, GetOuterBox(p));
    scene = SceneUnion(scene, GetInnerContent(p));
    scene = SceneUnion(scene, GetFloor(p));

    return scene;
}

vec3 GetNormal(vec3 p) {
    vec2 e = vec2(0,.01);
    return normalize(GetScene(p).dist - vec3(
            GetScene(p - e.yxx).dist,
            GetScene(p - e.xyx).dist,
            GetScene(p - e.xxy).dist
        ));
}

Scene RayMarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 80; ++i) {
        vec3 p = ro + rd * t;
        Scene scene = GetScene(p);
        if (scene.dist < .01) {
            return Scene(scene.type, t, scene.material);
        }
        t += scene.dist * 0.8;
        if (t > 100.) break;
    }

    return Scene(0, 100., kNoMaterial);
}

vec3 Trace(vec3 ro, vec3 rd) {
    vec3 color = vec3(0.0);
    vec3 skyColor = vec3(0.0);
    float atten = 1.0;
    vec3 point = ro + rd;
    for (int i = 0; i < 2; ++i) {
        Scene scene = RayMarch(ro, rd);
        if (scene.type == 1) {
            vec3 p = ro + rd * scene.dist;
            vec3 n = GetNormal(p);
            vec3 v = normalize(-rd);
            DirLight l = DirLight(uLightDir, uLightColor);
            color += atten * Shade(n, v, l, scene.material);
            rd = normalize(reflect(rd, n));
            ro = p + rd * 0.1;
            atten *= 0.05;
        } else if (scene.type == 2) {
            vec3 p = ro + rd * scene.dist;
            vec3 n = GetNormal(p);
            vec3 v = normalize(-rd);
            DirLight l = DirLight(uLightDir, uLightColor);
            color += atten * Shade(n, v, l, scene.material);
            scene = RayMarch(p + n * 0.01, n);
            if (scene.type != 0) {
                color = mix(color, color * clamp(scene.dist, 0.0, 1.0), 0.7);
            }
            break;
        } else {
            color += atten * (vec3(0.35, 0.69, 1.2)*2.);
            break;
        }
    }
    return color;
}

void main(void)
{
    vec2 ar = vec2(resolution.x/resolution.y, 1.0);
    vec2 uv = (gl_FragCoord.xy/resolution.xy-.5) * ar;
    vec3 ro = vec3(0,-0.2,-5);
    vec3 rd = normalize(vec3(uv, 1.2));
    vec3 color = vec3(0.0);

    color = Trace(ro, rd);

    color = mix(color, color * 0.35, max(0.0, length(2. * uv/ar)));

    // tone mapping
    color = color / (color + 1.0);

    // gamma correction
    color = pow(color, vec3(1.0 / 2.2));

    glFragColor = vec4(color, 1.0);
}
