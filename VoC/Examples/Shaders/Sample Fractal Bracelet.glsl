#version 420

// original https://www.shadertoy.com/view/fs2fWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define ths(a,b) tanh(a*sin(b))/tanh(a)
#define sabs(x) sqrt(x*x+0.00005)
//#define sabs(x, k) sqrt(x*x+k)-0.1

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

float dlength(vec2 uv) {
    return abs(uv.x) + abs(uv.y);
}

float dlength(vec3 uv) {
    return abs(uv.x) + abs(uv.y) + abs(uv.z);
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

    vec3 ro = vec3(0, 0.01, 2.2);

    //if (mouse*resolution.xy.z > 0.) {     
    //    ro.yz *= Rot(-m.y*3.14+1.);
    //    ro.xz *= Rot(-m.x*6.2831);
    //} 
	ro.y += 0.3 * cos(0.8 * time);
          
    
    return ro;
}

float GetDist(vec3 p) {
   
    float a = atan(p.x, p.z);
    float r = length(p.xz);
    
    float sc = 3. / pi;
    // polar
    
    //float d = length(vec3(abs(uv.x * r) - 0.25, abs(sc * p.y) - 0.25, 0.)) - 0.2;
    
    vec2 uv = sc * vec2(a - 0.25 * time, p.y);
    uv.x = (fract(uv.x) - 0.5) * r;
    
    float d = 10.;
    float m = 0.25;
    float n = 6.;
    for (float i = 0.; i < n; i++) {
        float io = 2. * pi * i / n;
        d = min(d, dlength(uv) - m);
        uv = abs(uv) - m;
        m *= 0.6;// * (0.5 + 0.5 * thc(5., 3. * a + time));// + 0.15 * cos(io + time);
        
    }
    d = min(d, dlength(uv) - m);
   // d = length(uv) - m;
    
  //  d = max(length(p) - 1.8, d);
    
    // main cylinder
    float d2 = abs(length(p.xz) - 1.) - 0.03;
    
    // 2 cylinders on top + bottom
    float d3 = d2;
     
    p.y += 0.05 * cos(3. * a + time);
    float h = 0.35 * pow(abs(cos(0.5 * a + 0.5 * time)), 4.);
    d2 = max(d2, abs(p.y) - h);
   
    float h2 = 0.02;
    d3 = max(d3, abs(abs(p.y) - h - 0.5 * h2) - h2);

    // cut out fractal from main cylinder
    d2 = -min(-d2, d);
    
    d2 = min(d2, d3);

   // d2 = length(p.xz) - 0.8;

    return 0.8 * d2;
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
    
    vec3 ro = getRo();
    
    float a = 0.5 * pi * uv.x + 0.18 * time;
    //ro = 2.7 * vec3(cos(a),0,sin(a));

    float zm = mix(1.2, 4., 0.5 + 0.5 * thc(5., 0. * pi * uv.x + 0.5 * time));
    zm = 1.2;

    vec3 rd = GetRayDir(uv, ro, vec3(0), zm);
    vec3 col = vec3(0);
   
    float d = RayMarch(ro, rd, 1.);

    float IOR = -1.;
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);

        vec3 pIn = p + 1000. * SURF_DIST * n;
        vec3 rdIn = refract(rd, n, 1./IOR);
        float dIn = RayMarch(pIn, rdIn, 1.);
        
        vec3 pExit = pIn + dIn * rdIn;
        vec3 nExit = -GetNormal(pExit); // *-1.; ?

        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        col = vec3(dif);
        
        float v = exp(-0.85 * pow(abs(p.y), 0.25));
        
        float fresnel = pow(1. + dot(p, n), 5.);
        
        // idk what this does
        v = smoothstep(0., 1., v);
        v = clamp(1.5 * v * v, 0., 1.);
      
        // color + lighten
        vec3 e = vec3(1);
        col = v * pal(0.32 + v, 0.8 * e, 0.5 * e, 0.5 * e, 0.8 * vec3(0,1,2)/3.); 
        //col = clamp(col, 0., 1.);
       
        col *= dif;
        col += 0.08 * n.y;
         col = smoothstep(0., 1., col);
    }
    
    col = pow(col, vec3(.4545));    // gamma correction
    col += 0.15;
    glFragColor = vec4(col,1.0);
}
