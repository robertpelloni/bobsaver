#version 420

// original https://www.shadertoy.com/view/3lVfWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

#define MaxSteps 1000
#define InfDist  500.
#define SurfDist 0.001
#define eps      0.1

float SDF(vec3 p)
{
    float circle = sqrt((abs(p.x)-1.) * (abs(p.x)-1.) + p.y * p.y) - 1.;
    float wave;

    if(0. > p.y && p.y > -PI)
        wave = (abs(p.x) - 1.) - cos(p.y);
    else
        wave = sqrt(p.x * p.x + (p.y + PI) * (p.y + PI));

    //to 3D SDF
    vec2 w = vec2(min(wave,circle), abs(p.z) - .4);
    return min(max(w.x,w.y), 0.) + length(max(w, 0.));
}

vec3 march(vec3 ro, vec3 rd)
{
    float dist = 0.;
    vec3 ray = ro;

    for(int i = 0; i < MaxSteps; ++i)
    {
        dist = SDF(ray);
        ray += rd*dist;
        if(dist < SurfDist || dist > InfDist) break;
    }
    return ray;
}

float lighting(vec3 p)
{

    if(SDF(p) > eps*2.) return 0.;

    const vec3 ex = vec3(eps, 0.,  0.);
    const vec3 ey = vec3(0.,  eps, 0.);
    const vec3 ez = vec3(0.,  0.,  eps);

    vec3 normal =  normalize(
        vec3( eps,-eps,-eps) * SDF(p + vec3( eps,-eps,-eps) * eps) +
        vec3(-eps,-eps, eps) * SDF(p + vec3(-eps,-eps, eps) * eps) +
        vec3(-eps, eps,-eps) * SDF(p + vec3(-eps, eps,-eps) * eps) +
        vec3( eps, eps, eps) * SDF(p + vec3( eps, eps, eps) * eps));

    float L1 = dot(normalize(p - vec3(sin(time)*  2.,  2.,  1.5)), normal);
    float L2 = dot(normalize(p - vec3(cos(time)* -2., -4., -1.5)), normal);

    if(L1 < 0.) L1 = 0.;
    if(L2 < 0.) L2 = 0.;

    return L1+L2;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y * 1.5;
    uv.y   -= .25;

    vec3 ro, rd;
    ro.x = sin(time)*5.;
    ro.y = cos(time/2.)*2.5;
    ro.z = cos(time)*5.;

    vec3 rorg = normalize(vec3(0)-ro);
    vec3 u    = normalize(cross(vec3(0,1.,0), rorg));
    vec3 v    = normalize(cross(rorg, u));
    rd        = normalize(rorg + u*uv.x + v*uv.y);
    
    
    float col = lighting(march(ro,rd));
    glFragColor = vec4(vec3(col, 0.,0.),1.);
}
