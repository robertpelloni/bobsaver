#version 420

// original https://www.shadertoy.com/view/td23z3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time

const vec3 target = vec3(0,0,0);
const float focalLength = 1.4;
const vec3 wup = vec3(0,1,0);
const float tMin = 1.e-3;
const float tMax = 5.;
const int spp = 4;

// https://www.shadertoy.com/view/4lVcRm
vec2 R2seq(int n)
{
    return fract(vec2(n) * vec2(0.754877666246692760049508896358532874940835564978799543103, 0.569840290998053265911399958119574964216147658520394151385));
}

float D(vec3 p, vec3 r)
{
    float a = length(p)-r.x;
    vec3 v = abs(p) - r;
    float b = length(max(v,0.)) + min(max(v.x,max(v.y,v.z)),0.);
    return mix(a,b,.5+.5*sin(time));
}

void T (inout vec3 color, inout float t, inout vec3 p, inout vec3 ro, inout vec3 rd, inout mat3 mo, inout float ud, inout float sd)
{
    sd = D(p, vec3(0.2));
    ud = abs(sd);
    color += step(ud,tMin)*mix(vec3(1),vec3(1,0,0),smoothstep(.3,.35,distance(fract(p*sin(.1*time)*40.), vec3(.5))));
    ro = ro+rd*ud;
    p = mo*ro;
    t += ud;
}

void C (inout vec3 color, vec2 uv, float dt, vec3 ro, mat3 mo, mat3 mc, int i)
{
    vec3 p = mo*ro;
    vec3 rd = vec3(normalize(vec3(uv+(R2seq(i)-.5)*dt,focalLength)));
    rd.x *= -1.;
    rd = mc*rd;
    float sd = D(p, vec3(0.2));
    float ud = abs(sd);
    for (float t = 0.; t < tMax && ud > tMin; T(color,t,p,ro,rd,mo,ud,sd));
}

void main(void)
{
    float dt = 1./max(resolution.x,resolution.y);
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)*dt;
    vec3 rd = normalize(vec3(uv,focalLength));
    vec3 ro = vec3(0,0,-2.5-sin(time));
    vec3 fo = normalize(target-ro);
    vec3 ri = cross(wup,fo);
    vec3 up = cross(fo,ri);
    mat3 mc = mat3(ri,up,fo);
    
    float s = sin(time);
    float c = cos(time);
    mat3 mo = 
        mat3(1,0,0,0,c,-s,0,s,c)*
        mat3(s,c,0,c,-s,0,0,0,1)*
        mat3(c,0,s,0,1,0,-s,0,c);
    vec3 color = vec3(0);
    for (int i = 0; i < spp; C(color, uv, dt, ro, mo, mc, i++));    
    glFragColor = vec4(sqrt(color/float(spp)),1);
}
