#version 420

// original https://www.shadertoy.com/view/ltBfWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPSILON .02
#define PI 3.4

vec3 eye;

vec3 skyColor(vec3 pos) 
{
    return mix(vec3(1., 1., 0.), vec3(1., 0., 0.), pos.y);
}

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

// iq value noise
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

float f(vec2 pos) 
{
    return noise(pos.yx * .1) * 50. * (pos.y - (eye.z + 3.))/ 30.;
}

vec3 getNormal(vec3 p)
{
    vec3 n = vec3(
        f(vec2(p.x - EPSILON, p.z)) - f(vec2(p.x + EPSILON, p.z)),
        2.0 * EPSILON,
        f(vec2(p.x, p.z - EPSILON)) - f(vec2(p.x, p.z + EPSILON)));
    return normalize(n);  
}

mat4 lookAt(vec3 eye, vec3 target, vec3 up)
{
    vec3 f = normalize(target - eye);
    vec3 r = normalize(cross(f, up));
    vec3 u = normalize(cross(r, f));
    
    return mat4(
        vec4(r, 0.),
        vec4(u, 0.),
        vec4(-f, 0.),
        vec4(0., 0., 0., 1.));
}

bool castRay(vec3 ro, vec3 rd, out float resT)
{
    const float mint = 0.001;
    const float maxt = 60.0;
    const float dt = .5;
    float lh = 0.0;
    float ly = 0.0;
    
    float t = mint;
    
    for (float t = mint; t < maxt; t += dt)
    {
        vec3 p = ro + rd * t;
        float h = f(vec2(p.x, p.z));
        if (p.y < h)
        {
            resT = t - dt + dt * (lh - ly) / (p.y - ly - h + lh);
            return true;
        }
        lh = h;
        ly = p.y;
    }
    
    return false;
}

vec3 getShading(vec3 p, vec3 normal, vec3 light)
{
    vec3 diffuseColor = vec3(0.2, 0.7, 0.3);
    return max(0., dot(normal, light)) * diffuseColor;
}

vec3 terrainColor(vec3 pos, vec3 eye) 
{   
    return getShading(pos, getNormal(pos), vec3(0., 1., 0.)) *  (1.5 - (pos.z - eye.z) / 30.);
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    eye = vec3(0., 12., -2. + time * 5.);
    vec3 viewRayDir = vec3(uv, -1.);
    
    vec3 dir = normalize(lookAt(eye, vec3(0., 11., time * 5.), vec3(0., 1., 0.)) * vec4(viewRayDir, 0.)).xyz;
    float resT;
    
    if (castRay(eye, dir, resT)) 
    {
        glFragColor.rgb = terrainColor(eye + dir * resT, eye);
    }
    else 
    {
        glFragColor.rgb = skyColor(vec3(uv, 0.));
    }
}
