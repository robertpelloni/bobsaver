#version 420

// original https://www.shadertoy.com/view/NsBfWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 80
#define MAX_DIST 50.
#define SURF_DIST 0.0001

#define pi 3.14159

vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b*cos( 6.28318*(c*t+d) );
}

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

//https://www.shadertoy.com/view/Wl3fD2

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

vec3 getRo() {
    float t = 0.0 * time, o = 2. * pi / 3.;
    return 3. * vec3(cos(t - o), cos(t), cos(t + o));
}

vec3 distort(vec3 p) {
    float o = 2.* pi / 3.;
    float t = 0. * length(p) - 0.25 * time;
   // p = abs(p) - 0.5;
    p.xy *= Rot(t - o);
    p.yz *= Rot(t);
    p.zx *= Rot(t + o);
    return p;//fract(0.8 * p) - 0.5;
}

float GetDist(vec3 p) {

    vec3 ro = getRo();
    float cd = length(p - ro) - 0.;

   

    p = distort(p);
    
    float r1 = 1.2;
    float r2 = 0.3;
    float d0 = length(p.xz) - r1;
    float d1 = length(vec2(d0, p.y)) - r2;
    //d1 += 0. + 0.2 * cos(d1 * 2. + time);
    p *= 1.8;
    //p /= cos(length(p) - time);
   
    p *= log(d1 - 0.);

    vec3 center = floor(p) + 0.5;
    vec3 neighbour = center + face(p - center);
    
    vec3 pos = p - center;
    vec3 npos = p - neighbour;
    
    float h = hash(hash(neighbour.x, neighbour.y), neighbour.z);
    
    float o = 2. * pi / 3.;
    float t = 2. * pi * h + 0. * time;
    vec3 ax = vec3(cos(t - o), cos(t), cos(t + o));
    ax = normalize(ax);
    
   // npos = erot(npos, ax, 0.5 * pi * h);
    
   
    //npos.xy *= Rot(pi * h);
    float e = 0.1;
    float worst = sdBox(npos, vec3(0.75)) - 0.;
    
    float sq = 0.25 * sqrt(3.);
   // worst = length(npos) - 0.5;//sq;
    worst = sdBox(npos, vec3(0.4)) - 0.3798;
   // worst = min(min(length(npos.xz), length(npos.zy)), length(npos.yx)) - 0.2;
    
    float me = sdBox(pos, vec3(0.2)) - 0.;
    
    
    // lower k => more "fog"
    float k = 0.4;
    float d = worst;//min(me, worst);
    d = -min(-d, cd);
    
    //return length(p) -0.3 + SURF_DIST;
    return k * d + 0.14;//500. * SURF_DIST;
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

    vec3 rd = GetRayDir(uv, ro, vec3(0), 0.95);
    vec3 col = vec3(0);
   
    float d = RayMarch(ro, rd, 1.);

    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);

        vec3 dp = distort(p);

        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
       // col = vec3(step(0., dif));
        
        // darken with distance from origin
        float v = exp(-0.3 * pow(dot(p,p), 0.25));
        
        // idk what this does
        v = smoothstep(0., 1., v);
        v = clamp(1.2 * v * v, 0., 1.);
      
        // color + lighten
        vec3 e = vec3(1);
        col = v * pal(0.32 + 1. * v, 0.8 * e, 0.5 * e, 0.5 * e, 0.8 * vec3(0,1,2)/3.);    
        //col = vec3(v);
        //col -= 0.1;
    }
    
    glFragColor = vec4(col,1.0);
}
