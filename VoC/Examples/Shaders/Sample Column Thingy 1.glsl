#version 420

// original https://www.shadertoy.com/view/NdXBWf

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

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float smin(float a, float b)
{
    float k = 0.12;
    float h = clamp(0.5 + 0.5 * (b-a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float GetDist(vec3 p) {
    //float sd = sdBox(p, vec3(4.)) - 2.;
    
    vec2 uv = p.xz;
    
    // buggy + laggy:
    // float sc = 3.;
    // uv = floor(sc * uv)/sc + 0.5;

    uv *= Rot(0.1 * p.y);
    //uv.x = sabs(uv.x) - 1.5;
   
    float ext = 4.2 + 1.2 * cos(0.1 * p.y + time);
    uv = abs(uv) - ext;
    uv *= Rot(pi/4.);
    uv.x = abs(uv.x) - sqrt(ext) * sqrt(3./2.);
   
    uv *= Rot(p.y * 2.4 + time);
   
    float t = time;
    float r = 0.5;
    r *= 0.5 + 0.5 * cos(0.5 * t + 1.2 * p.y);       
    vec2 p0 = r * vec2(cos(t), sin(t));
    vec2 p1 = r * vec2(cos(t + pi), sin(t + pi));
    float d = sdSegment(uv * 1.35, p0, p1) - .8 - .5 * length(uv);
    
    // looks cool too:
     //d = sdSegment(uv * (1. + 0.1 * cos(3. * 3. * length(uv))), p0, p1) -0.055 - .5 * length(uv);  

    //d *= 0.8;
    return d;//-smin(d, -sd);
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

    vec3 ro = vec3(0, 3, -20);
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0), 1.);
    vec3 col = vec3(0);
   
    float d = RayMarch(ro, rd, 1.);

    float IOR = 1.;
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);
           
        vec3 pIn = p - 4. * SURF_DIST * n;
        vec3 rdIn = refract(rd, n, 1./IOR);
        float dIn = RayMarch(pIn, rdIn, -1.);
        
        vec3 pExit = pIn + dIn * rdIn;
        vec3 nExit = -GetNormal(pExit);
        
        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        vec3 e = vec3(1);
        vec3 bcol = pal(dif * 0.35 + 0.2 + 0.2 * cos(0.1 * p.y + time), e, e, e, 0.5 * vec3(0,1,2)/3.);
       // col = 0.02 * clamp(col, 0., 1.);
       
        col = bcol;
        col *= 0.75 - 0.25 * n.y;
        
        // fresnel (interior + exterior)
        col += pow(1.+dot(rdIn, nExit), 5.);    
        col += pow(1.+dot(rd, n), 5.);
        col *= col * (1. + dot(rd, n));

        // cartoony outline effect (0.5 determines thickness, looks cool with smoothstep)
        col += bcol * step(0., 0.5 + dot(rd, n));
    }
    
    col = pow(col, vec3(.4545)) + 0.05;    // gamma correction
    
    glFragColor = vec4(col,1.0);
}
