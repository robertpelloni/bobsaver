#version 420

// original https://www.shadertoy.com/view/mtyyRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_STEPS = 128;
#define SURFACE_DIST 0.1
const float PI = 3.14159265359;

struct Hit
{
    float dist;
    float min_dist;
    vec3 point;
    vec3 normal;
};

float spiral(vec3 p) {
    vec2 uv = p.xy;
    float l = length(uv) * 8.0 - time;
    vec2 p2 = vec2(sin(l), cos(l));
    float d = 2.0 - pow(distance(uv, p2), 0.1);
    d = pow(d, 2.0 - length(uv) * 0.5 + 1.0 / (0.2 + dot(uv, uv)));
    return dot(p, normalize(vec3(0.2, 0.2, -1))) + d;
}

float SDF(vec3 point)
{
    return spiral(point);
}

vec3 getNormal(vec3 point, float dist)
{
    vec2 e = vec2(0.002, 0.0);
    return normalize(dist - vec3(SDF(point - e.xyy), SDF(point - e.yxy), SDF(point - e.yyx)));
}

Hit raymarch(vec3 ro, vec3 rd)
{
    Hit hit;
    hit.min_dist = 99999.;
    hit.point = ro;
    for (int i = 0; i < MAX_STEPS; ++i)
    {
        float sdf = SDF(hit.point);
        if (abs(sdf) < hit.min_dist) 
        {
            hit.min_dist = sdf;
            hit.normal = getNormal(hit.point, hit.min_dist);
            if (sdf <= SURFACE_DIST)
                break;
        }
        hit.point += rd * sdf * 0.1;
        hit.dist += sdf;
    }
    
    return hit;
}

vec3 gammaCorrect(vec3 color, float gamma)
{
    return pow(color, vec3(1.0 / gamma));
}

float diffuse(vec3 normal, vec3 light_dir)
{
    return max(0.0, dot(normal, light_dir));
}
    
float specular(vec3 light_dir, vec3 ray_dir, vec3 normal)
{
    vec3 halfway = normalize(light_dir + ray_dir);
    return max(0.0, dot(normal, halfway));
}

vec3 gradient(float z, float d) {
    return mix(
        vec3(0.4, 0.8, 1.0),
        mix(
            vec3(0.0, 0.0, 1.0),
            vec3(1),
            z * 0.55
        ),
        1.0 / (d * 0.033)
    );
}

void main(void)
{
    float mr = min(resolution.x, resolution.y);
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy) / mr;
    vec3 ro = vec3(0, 0, -1);
    vec3 rd = normalize(vec3(uv, 1));
    
    Hit hit = raymarch(ro, rd);
    
    vec3 lp = vec3(6, 8, -4);
    vec3 ld = normalize(lp - hit.point);
    
    vec3 vd = normalize(ro - hit.point);
    float s = specular(ld, vd, hit.normal);
    float spec = pow(s, 32.);
    spec += pow(s, 64.);
    spec += pow(specular(normalize(vec3(5, -10, -2)), vd, hit.normal), 8.);
    float diff = diffuse(hit.normal, ld);
    float light = spec + diff;

    vec3 color = gradient(hit.point.z, hit.dist + 32. * light);
    glFragColor = vec4(color, 1);
}
