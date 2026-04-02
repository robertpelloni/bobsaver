#version 420

// original https://www.shadertoy.com/view/NdlfWf

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
   
    float sd = sdBox(p, vec3(4.)) - 2.;
    
    vec2 uv = p.xz;
    //float sc = 3.;
   // uv = floor(sc * uv)/sc + 0.5;

    uv *= Rot(0.1 * p.y);
   // uv.x = abs(uv.x) - 1.5;
   
    float tim = 0.1 * p.y + time;
   
    float ext = 4.2 + 0.1 * thc(4., tim) * thc(4., 4. * p.y);
    vec2 id = vec2(step(uv.x,0.), step(uv.y,0.));
    uv = sabs(uv) - ext;
   // uv *= Rot(pi/4.);
   // uv.x = sabs(uv.x) - sqrt(ext) * sqrt(3./2.);
   
    float time = 0. * p.y + time + cos(tim);
    vec2 v = vec2(cos(time), sin(time));
    float d = sdSegment(uv, -2. * v, 2. * v) - 1.;
    d *= 0.6;
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
        vec3 nExit = -GetNormal(pExit); // *-1.; ?
        
        
        vec2 uv = p.xz;
        uv *= Rot(0.1 * p.y);
        vec2 id = vec2(step(uv.x,0.), step(uv.y,0.)) - 0.5;
        float ido = pi * id.x * id.y;
        float hid = pi * h21(id) ;
        
        
        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        vec3 e = vec3(1);
        
        float in1 = dif * 0.3 + 0.25 + 0.1 * thc(4., hid + 0.05 * p.y + time);
        
        // removed this, was causing artifacts (was thc(10.,) instead of cos)
        //in1 += thc(6., ido -0.05 * p.y + 0.1 * time + floor(5. * (time + 2. * ido + 0.5 * pi * cos(ido + 4. * p.y))) / 5.);
        
        vec3 bcol = pal(in1, e, e, e, 0.28 * vec3(0,1,2)/3.);
       // col = 0.02 * clamp(col, 0., 1.);
       
        col = bcol;
        col *= 0.75 - 0.25 * n.y;
        
        // fresnel
        col += pow(1.+dot(rdIn, nExit), 5.);
        col += pow(1.+dot(rd, n), 4.);  //5.  //maybe better without this too?   
        col *= col * vec3(1. + dot(rd, n));
        
        col = clamp(col, 0., 1.);
        col *= 1.- 0.1 * exp(-2. * cos(hid * ido + 5. * length(p.xz) + time));
        

        float k = 0.01;
        float v = 1. + .5 * step(thc(10., 4. * p.y), 0.5) + 0.5 * thc(80., floor(5. * (hid + 0.1 * p.y + id.x * id.y * time))/5. ) + dot(rd,n);
        float val = smoothstep(-k, k, v);
       // col += bcol * clamp(mix(0.5, 1. + dot(rd,n), 10000.), 0., 1.);//exp(-2. * p.y));
        col += bcol * clamp(val, 0., 1.);
        //col += mix(0., fresnel, 0.5);
    }
    
    col = pow(col, vec3(.4545)) + vec3(0.24, 0.05, 0.09);    // gamma correction
    
    glFragColor = vec4(col,1.0);
}
