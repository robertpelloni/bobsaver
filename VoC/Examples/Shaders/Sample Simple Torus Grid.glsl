#version 420

// original https://www.shadertoy.com/view/ftsfzn

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
//#define sabs(x, k) sqrt(x*x+k)-0.1

#define Rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

float cc(float a, float b) {
    float f = thc(a, b);
    return sign(f) * pow(abs(f), 0.25);
}

float cs(float a, float b) {
    float f = ths(a, b);
    return sign(f) * pow(abs(f), 0.25);
}

vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b*cos( 6.28318*(c*t+d) );
}

float h21(vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float mlength(vec2 uv) {
    return max(abs(uv.x), abs(uv.y));
}

float mlength(vec3 uv) {
    return max(max(abs(uv.x), abs(uv.y)), abs(uv.z));
}

float smin(float a, float b) {
    float k = 0.12;
    float h = clamp(0.5 + 0.5 * (b-a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

#define FK(k) floatBitsToInt(k*k/7.)^floatBitsToInt(k)
float hash(float a, float b) {
    int x = FK(a), y = FK(b);
    return float((x*x+y)*(y*y-x)-x)/2.14e9;
}

vec3 erot(vec3 p, vec3 ax, float ro) {
  return mix(dot(ax, p)*ax, p, cos(ro)) + cross(ax,p)*sin(ro);
}

vec3 face(vec3 p) {
     vec3 a = abs(p);
     return step(a.yzx, a.xyz)*step(a.zxy, a.xyz)*sign(p);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

vec3 getRo() {
    vec2 m = mouse*resolution.xy.xy/resolution.xy;

    float t = 0.1 * time;
    vec3 ro = vec3(2., 3. * cos(t), -3. * sin(t));
   // ro.yz *= Rot(-m.y*3.14+1.);
    //ro.xz *= Rot(-m.x*6.2831);
    return ro;
}

float GetDist(vec3 p) {
    vec3 ip = floor(p) + 0.5;
    vec3 fp = p - ip;
    
    float h = h21(vec2(ip.x, h21(ip.yz)));
   
    float o = 2. * pi * h;
    fp.xz*= Rot(o + 0.25 * time + 0.25 * pi * cc(1., o + 0.5 * time));
    fp.xy*= Rot(o + 0.25 * time + 0.25 * pi * cc(1., o + 0.5 * time + 0.5 * pi) + 0.5 * pi);
  
    float r1 = 0.1 + 0.2 * h - 0.15 * exp(-0.5 * length(p-getRo()));
    float r2 = min(0.1, r1);
    float d1 = length(fp.xz) - r1;
    float d = length(vec2(d1,fp.y)) - r2;
   
   // float d = mlength(fp) - 0.1 - 0.15 * h;
    return 0.4 * d;
}

float RayMarch(vec3 ro, vec3 rd, float z) {
    
    float dO=0.;
    float s = sign(z);
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        if (s != sign(dS)) { z *= 0.5; s = sign(dS); }
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
    
    vec3 ro = getRo();
    
    vec3 rd = GetRayDir(uv, ro, vec3(0), 1.);
    vec3 col = vec3(0);
   
    float d = RayMarch(ro, rd, 1.);

    float IOR = 1.05;
    vec3 p = ro + rd * d;
    vec3 n = GetNormal(p);
    vec3 r = reflect(rd, n);
    if(d<MAX_DIST) {

        vec3 pIn = p - 4. * SURF_DIST * n;
        vec3 rdIn = refract(rd, n, 1./IOR);
        float dIn = RayMarch(pIn, rdIn, -1.);
        
        vec3 pExit = pIn + dIn * rdIn;
        vec3 nExit = -GetNormal(pExit); // *-1.; ?

        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        col = vec3(dif);
        
        float fres = pow(1. + dot(rd, n), 5.);
        fres = 1. - fres;
        float k = 0.08;
        fres = smoothstep(-k, k,-0.9 + fres);
        fres = 1. - exp(-3. * fres + 1.5 * dif);
        col = mix(col, vec3(0), fres);
        vec3 e = vec3(0.5);
        vec3 c = pal(n.y, e, e, e, 0.5 * vec3(0,1,2)/3.);
        col *= c;
    }
    
    vec3 ip = floor(p) + 0.5;
    vec3 fp = p - ip;
    
    float h = h21(vec2(ip.x, h21(ip.yz)));
    
    vec3 col2 = vec3(1);
    float o = 2. * pi / 3.;
    float t = time + h * pi * 2.;
    vec3 a = 0.9 + 0.1 * thc(2., vec3(t-o,o,t+o));
    //vec3(0.75,0.9,1.)
    
    col2 = mix(col2, a, exp(-thc(4., 0.125 * pi * h + time - 0.1 * p.y)));
    
    float m2= exp(-0.1 * dot(p, r)) * exp(-0.5 * dot(p, normalize(vec3(1,2,3))));
    vec3 col3 = vec3(0.5 * dot(rd, n));// vec3(dot(normalize(r), normalize(p)));
    col2 = mix(col3, col2, 1.-exp(-0.5 * length(p)));
   // col = mix(col, vec3(0), 1.-m2);
   // col2 *= m2;
    
    float m = exp(-0.2 * length(p));
    m = clamp(m, 0., 1.);
    col = mix(col2, col, m);
    col = pow(col, vec3(.4545));    // gamma correction
    
    glFragColor = vec4(col,1.0);
}
