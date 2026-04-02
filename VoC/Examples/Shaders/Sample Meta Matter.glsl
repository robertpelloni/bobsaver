#version 420

// original https://www.shadertoy.com/view/4dGfDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// leon/ponk 01/07/2018
// a lot of lines are from the community

const float steps = 100.;
const float far = 20.;
const float count = 8.;

vec3 cameraPos = vec3(4);
vec3 cameraTarget = vec3(0);
const float fov = 3.;

vec3 lightPos = vec3(1, 1, 1);
vec3 ambient = vec3(.5);
vec3 light = vec3(.5);
vec3 specular = vec3(0);
float specularSharpness = 10.;
vec3 glow = vec3(0);
float glowSharpness = .5;

#define PI 3.14159
#define repeat(p,r) (mod(p,r)-r/2.)
#define sdist(p,r) (length(p)-r)
#define saturate(p) clamp(p,0.,1.)
mat2 rot (float a) { float c = cos(a), s = sin(a); return mat2(c,-s,s,c); }
float smin (float a, float b, float r) { float h = clamp(.5+.5*(b-a)/r, 0., 1.); return mix(b, a, h)-r*h*(1.-h); }
vec3 look (vec3 eye, vec3 target, vec2 uv) {
    vec3 forward = normalize(target-eye);
    vec3 right = normalize(cross(forward, vec3(0,1,0)));
    vec3 up = normalize(cross(right, forward));
    return normalize(forward * fov + right * uv.x + up * uv.y);
}

float sdf (vec3 p) {
    float scene = 10.;
    float shape = 10.;
    float breath = sin(time - length(p)*4. + atan(p.y, p.z));
    float thin = .05;
    float range = .4 + .1 * breath;
    float height = .5 - .5 * breath;
    float smoo = .2 + .1 * breath;
    for (float i = count; i > 0.; --i) {
        float r = i / count;
        r *= r;
        p.xz = abs(p.xz) - range * r;
        p.xz *= rot(+.5);
        p.yz *= rot(-.5);
        p.yx *= rot(+r*breath*.1+2.);
        shape = sdist(p.yz, thin*r);
        shape = max(abs(p.x)-height*r, shape);
        scene = smin(scene, shape, smoo * r);
    }
    return scene;
}

vec3 getNormal (vec3 p) {
    vec2 e = vec2(.001,0);
    return normalize(vec3(sdf(p+e.xyy)-sdf(p-e.xyy),
                          sdf(p+e.yxy)-sdf(p-e.yxy),
                          sdf(p+e.yyx)-sdf(p-e.yyx)));
}

vec3 raymarching (vec3 eye, vec3 ray)
{
    vec4 hit = vec4(0);
    float total = .001;
    for (float i = steps; i >= 0.; --i) {
        float dist = sdf(eye + ray * total);
        if (dist < .001 * total || total > far) {
            hit.xyz = eye + ray * total;
            hit.w = i/steps;
            break;
        }
        dist *= .5;
        total += dist;
    }

    vec3 pos = hit.xyz;
    vec3 normal = getNormal(pos);
    vec3 view = normalize(cameraPos-pos);
    vec3 lightDir = normalize(lightPos);
    float lightIntensity = clamp(dot(lightDir, normal),0.,1.);
    float specularIntensity = saturate(pow(max(0., dot(reflect(-lightDir, normal), view)), specularSharpness));
    float glowIntensity = pow(abs(1.-abs(dot(normal, view))), glowSharpness);

    vec3 color = ambient + light * lightIntensity + specular * specularIntensity + glow * glowIntensity;
    color *= hit.w;
    color *= step(length(cameraPos-pos), far);

    return saturate(color);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    //cameraPos.yz *= rot((mouse.y*2.-1.)*step(.1, mouse*resolution.xy.z));
    //cameraPos.xz *= rot((mouse.x*2.-1.)*step(.1, mouse*resolution.xy.z));
    vec3 ray = look(cameraPos, cameraTarget, uv);
    glFragColor = vec4(raymarching(cameraPos, ray), 1);
}
