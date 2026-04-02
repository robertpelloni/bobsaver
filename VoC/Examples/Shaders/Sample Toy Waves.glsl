#version 420

// original https://www.shadertoy.com/view/fsBfWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define ths(a,b) tanh(a*sin(b))/tanh(a)
#define sabs(x) sqrt(x*x+1e-2)
//#define sabs(x, k) sqrt(x*x+k)-0.1

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

float smin(float a, float b)
{
    float k = 0.12;
    float h = clamp(0.5 + 0.5 * (b-a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

#define MAX_STEPS 400
#define MAX_DIST 100.
#define SURF_DIST .001

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
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

    float d = sqrt(26.);
    float a = 1.8 + 0.1 * time;
    vec3 ro = d * normalize(vec3(cos(a), 0.1, sin(a)));
    //ro.yz *= Rot(-m.y*3.14+1.);
    //ro.xz *= Rot(-m.x*6.2831);
    return ro;
}

float GetDist(vec3 p) {
    
    p.x -= 0.2 * time;
    p.y += 0.2 * cos(2. * p.z + time) * cc(1., 5. * p.x);
    p.y -= 0.2 * cos(p.z * 3.);
    float d = p.y + 1.;
    
    return 0.6 * d; // could be higher maybe
}

float RayMarch(vec3 ro, vec3 rd, float z) {
    float dO=0.;
    float s = 1.;
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        if(s!=sign(dS))z*=0.5;
        s = sign(dS);
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

vec3 Bg(vec3 rd) {
    return 0.5 + 0.5 * rd;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec3 ro = getRo();
    
    vec3 rd = GetRayDir(uv, ro, vec3(0,-1,0), 1.1);
    vec3 col = vec3(0);
   
    float d = RayMarch(ro, rd, 1.);

    float IOR = 1.05;
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);

        vec3 pIn = p - 4. * SURF_DIST * n;
        vec3 rdIn = refract(rd, n, 1./IOR);
        float dIn = RayMarch(pIn, rdIn, -1.);
        
        vec3 pExit = pIn + dIn * rdIn;
        vec3 nExit = -GetNormal(pExit); // *-1.; ?

        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        col = vec3(dif);
        
        
        //col *= 0.5 + 0.5 * cc(4., 5. * p.x - time);
        
        float x = mod(5. * p.x - time, 2. * pi) - pi;

        float o = 0.25 * pi;
        float s1 = smoothstep(0. + o, 0.5 + o, abs(x));
        s1 = pow(s1, 4.);
    
        float fresnel2 = pow(1.+dot(rd, n), 3.); 
    
        float sc = step(0.1 * s1, uv.y);
        col *= mix(col, vec3(fresnel2), 1.-vec3(s1));
        
        float fresnel = pow(1.+dot(rdIn, nExit), 5.);
        //col *= fresnel;
        
        //col += fresnel2;
        vec3 e = vec3(1);
        float mx = mix(0.32, 1., 0.5 + 0.5 * cc(1., 0.05 * p.z + .5 * time + floor(5. * p.x - time)));
        col *= pal(s1 * mx + 0.45 + 0.2 * exp(-0.2 * abs(p.z)), e, e, e, 0.5 * vec3(0,1,2)/3.);
       
    }
    
    col = pow(col, vec3(.4545));    // gamma correction
    //col = 1. - col;
     vec3 p = ro + rd * d;
    float lerp = exp(-0.35 * mlength(p.xz * Rot(0.1 * time)));
    col = mix(col, Bg(sabs(rd)+0.), 1.-lerp);
    
    glFragColor = vec4(col,1.0);
}
