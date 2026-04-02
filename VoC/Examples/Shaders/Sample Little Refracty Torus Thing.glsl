#version 420

// original https://www.shadertoy.com/view/7sXBzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 400
#define MAX_DIST 100.
#define SURF_DIST .001

#define pi 3.14159

#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define ths(a,b) tanh(a*sin(b))/tanh(a)
#define sabs(x) sqrt(x*x+1e-2)

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float mlength(vec2 uv) {
    return max(abs(uv.x), abs(uv.y));
}

float mlength(vec3 uv) {
    return max(max(abs(uv.x), abs(uv.y)), abs(uv.z));
}

float smin(float a, float b)
{
    float k = 0.12;
    float h = clamp(0.5 + 0.5 * (b-a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

//crude
vec3 smin(vec3 a, vec3 b) {
    return vec3(smin(a.x,b.x), smin(a.y,b.y), smin(a.z,b.z));
}

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float GetDist(vec3 p) {
    float r1 = 1.3;
    float r2 = 0.3;
    float d1 = length(p.xz) - r1;
    
    float a = atan(p.x, p.z);
    
    vec2 u = vec2(d1, p.y);    
    u.xy *= Rot(1.5 * a - 0.5 * atan(u.x, u.y) + time);
    u.x = sabs(u.x) - 0.5;
    u = sabs(u) - 0.2;

    float d2 = length(u) - r2;
    
    return 0.5 * d2;
}

float RayMarch(vec3 ro, vec3 rd, float z) {    
    float dO=0.; 
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        if(abs(dS)<SURF_DIST || dO>MAX_DIST) break;
        dO += dS*z; 
    }
    
    return min(dO, MAX_DIST);
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;

    vec3 ro = vec3(0, 0, -5);
    //ro.yz *= Rot(-m.y*3.14+1.);
    //ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0), 1.5);
    vec3 col = vec3(0);
   
    float d = RayMarch(ro, rd, 1.);

    float IOR = 1. + exp(-0.6 * d); // very specific trick
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);

        vec3 pIn = p - 30. * SURF_DIST * n;
        vec3 rdIn = refract(rd, n, 1./IOR);
        float dIn = RayMarch(pIn, rdIn, -1.); //rdIn
        
        vec3 pExit = pIn + dIn * rdIn;
        vec3 nExit = -GetNormal(pExit); // *-1.; ?
        
        float fresnel = pow(1.+dot(rdIn, nExit), 2.);
        col = vec3(fresnel);
        fresnel = pow(1.+dot(rd, n), 5.);
        col += vec3(fresnel);
        
        float dif = dot(p, normalize(vec3(1,2,3)))*.5+.5;
        col *= mix(dif, 1., 0.8 + 0.22 * thc(40., d * 20.));
        
        float v = 1.-exp(-1. * pow(dIn, 4.));
        //col = vec3(v);
        col = smin(col, vec3(v));
        vec3 e = vec3(dIn);
        col *= pal(0.02 * dIn, e, e, e, vec3(0,1,2)/3.);
    }
    
    col = pow(col, vec3(.4545));    // gamma correction
    
    glFragColor = vec4(col,1.0);
}
