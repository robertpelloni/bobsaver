#version 420

// original https://www.shadertoy.com/view/7sffWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 400
#define MAX_DIST 20.
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

// (SdSmoothMin) stolen from here: https://www.shadertoy.com/view/MsfBzB
float smin(float a, float b)
{
    float k = 0.12;
    float h = clamp(0.5 + 0.5 * (b-a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

//nabbed from blacklemori
vec3 erot(vec3 p, vec3 ax, float rot) {
  return mix(dot(ax, p)*ax, p, cos(rot)) + cross(ax,p)*sin(rot);
}

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

vec3 distort(vec3 p) {
    float time = 3. * length(p) + 1.*time;//0. * length(p);
    
    float spd = 0.01;
    float c = cos(time);
    float c2 = cos(time + 2. * pi /3.);
    float c3 = cos(time - 2. * pi / 3.);
    //float s = thc(spd, pi/2. + time);
    vec3 q = erot(vec3(c,c2,c3), normalize(vec3(c2,c3,c)), 0.5 * time + 3. * length(p));
    return cross(p, q);
}

float GetDist(vec3 p) {
   
    
    float sd = length(p - vec3(0, 3., -3.5)) - 1.2;
    
    //p = mix(sabs(p) - 0., sabs(p) - 1., 0.5 + 0.5 * thc(4., time));
    
    p = distort(p);
    p.xz *= Rot(4. * p.y + time);
    p = sabs(p) - 0.25;
    float d = length(p) - 0.3;
    d *= 0.05; //smaller than I'd ike it to be
    d = -smin(-d, sd); 
    
    return d;
}

float RayMarch(vec3 ro, vec3 rd, float z) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = z * GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
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

    vec3 ro = vec3(0, 3, -3.5);
   // ro.yz *= Rot(-m.y*3.14+1.);
    //ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0,0.,0), 1.);
    vec3 col = vec3(0);
   
    float d = RayMarch(ro, rd, 1.);

    float IOR = 1.5;
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        //vec3 r = reflect(rd, n);

        vec3 rdIn = refract(rd, n, 1./IOR);
        vec3 pIn = p - 3. * SURF_DIST * n;
        float dIn = RayMarch(pIn, rdIn, -1.);

        vec3 pExit = pIn + dIn * rdIn;
        vec3 nExit = GetNormal(pExit);

        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        col = vec3(dif);
        
        float fresnel = pow(1.+dot(rd, n), 1.);
        col = 1. * vec3(fresnel);
        
       // vec3 q = distort(p);
        col *= 2. + 1.8 * thc(10., 60. * length(p) - 1. * time);
        col = clamp(col, 0., 1.);
       // col *= 1.-exp(-0.5 - 0.5 * p.y);
       // col *= 0.5 + 0.5 * n;
        vec3 e = vec3(1.);
        col *= pal(length(p) * 3. - 0.05 * time, e, e, e, 0.5 * vec3(0,1,2)/3.);
        col = clamp(col, 0., 1.);
        col *= exp(-1.2 * length(p));
        col *= 3.;
    }
    
    col = pow(col, vec3(.4545));    // gamma correction
    
    glFragColor = vec4(col,1.0);
}
