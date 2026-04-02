#version 420

// original https://www.shadertoy.com/view/tdjfDm

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------

/*
 * Another Mandelbulb this time inspired by the movie Annihilation
 *
 * Original Mandelbulbs
 * Paul Nylander - http://bugman123.com (this site is awesome)
 * Daniel White - https://www.skytopia.com/
 *
 * Code
 * Mandelbulb SDF - IQ - Mandelbulb Derivative
 * https://www.shadertoy.com/view/ltfSWn
 * https://www.iquilezles.org/www/articles/mandelbulb/mandelbulb.htm
 * Shortest Mandelbulb - Fabrice Neyret
 * https://www.shadertoy.com/view/ltVGW3
 */

#define R resolution.xy
#define ZERO (min(frames,0))
#define EPS .0005
#define FAR 10.
#define T time
#define PI 3.141592
#define B1 vec4(0.0,0.0,-0.6,0.18)
#define B2 vec4(0.0,0.0,-0.86,0.2)

//Fabrice - compact rotation
mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}

//Dave Hoskins - Hash without sin
//https://www.shadertoy.com/view/4djSRW
float hash13(vec3 p3)
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash33(vec3 p3)
{
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

float nz(vec3 p)
{
    vec3 ip=floor(p);
    p-=ip; 
    vec3 s=vec3(7,157,113);
    vec4 h=vec4(0.,s.yz,s.y+s.z)+dot(ip,s);
    p=p*p*(3.-2.*p); 
    h=mix(fract(sin(h)*43758.5),fract(sin(h+s.x)*43758.5),p.x);
    h.xy=mix(h.xz,h.yw,p.y);
    return mix(h.x,h.y,p.z); 
}

//Sphere functions & SDFs - IQ
//https://www.iquilezles.org/www/articles
vec2 sphIntersect(vec3 ro, vec3 rd, vec4 sph) 
{
    vec3 oc = ro - sph.xyz;
    float b = dot(oc,rd),
          c = dot(oc,oc) - sph.w*sph.w,
          h = b*b - c;
    if (h < 0.0) return vec2(-1.0);
    h = sqrt(h);
    float tN = -b - h,
          tF = -b + h;
    return vec2(tN, tF);
}

float sphDensity(vec3 ro, vec3 rd, vec4 sph, float dbuffer) 
{
    float ndbuffer = dbuffer / sph.w;
    vec3  rc = (ro - sph.xyz) / sph.w;

    float b = dot(rd, rc);
    float c = dot(rc, rc) - 1.0;
    float h = b * b - c;
    if (h < 0.0) return 0.0;
    h = sqrt(h);
    float t1 = -b - h;
    float t2 = -b + h;

    if (t2 < 0.0 || t1 > ndbuffer) return 0.0;
    t1 = max(t1, 0.0);
    t2 = min(t2, ndbuffer);

    float i1 = -(c * t1 + b * t1 * t1 + t1 * t1 * t1 / 3.0);
    float i2 = -(c * t2 + b * t2 * t2 + t2 * t2 * t2 / 3.0);
    return (i2 - i1) * (3.0 / 4.0);
}

float sdCappedCylinder(vec3 p, float h, float r) 
{
    vec2 d = abs(vec2(length(p.xy),p.z)) - vec2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

//slightly modified mandelbulb code and trap from IQ - Mandelbulb Derivative
//https://www.shadertoy.com/view/ltfSWn
vec2 map(vec3 p, out vec4 col) 
{
    vec3 w = p - vec3(normalize(p.xy)*0.26,0);
    float m = dot(w,w),
          dz = 1.,
          MP = 8.0;
    vec4 trap = vec4(abs(w), m);
    
    for (int i=ZERO; i<4 ; i++) {
        dz = MP*pow(sqrt(m),7.0)*dz + 1.0;
        float r = length(w), 
              b = MP*acos(w.z / r) + fract(T*0.1)*2.*PI,
              a = MP*atan(w.y, w.x);        
        w = p + pow(r,8.0) * vec3(sin(b)*cos(a), sin(a) * sin(b), cos(b));
        trap = min(trap, vec4(abs(w), m));
        m = dot(w,w);
        if (m>256.0) break;
    }
    
    col = vec4(m, trap.yzw);
    return vec2(max(0.25*log(m)*sqrt(m)/dz, -sdCappedCylinder(p, 0.2, 2.0)),
                length(p - B1.xyz) - B1.w);
}

vec3 normal(vec3 p) {
    vec4 trap;
    vec2 e = vec2(EPS, 0);
    float d1 = map(p + e.xyy, trap).x, d2 = map(p - e.xyy, trap).x,
          d3 = map(p + e.yxy, trap).x, d4 = map(p - e.yxy, trap).x,
          d5 = map(p + e.yyx, trap).x, d6 = map(p - e.yyx, trap).x,
          d = map(p, trap).x * 2.0;
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float apprSoftShadow(vec3 ro, vec3 rd, float mint, float tmax, float w)
{
    vec4 trap;
     float t = mint, res = 1.0;
    for( int i=ZERO; i<256; i++ )
    {
         float h = map(ro + t*rd, trap).x;
        res = min( res, h/(w*t) );
        t += clamp(h, 0.005, 0.30);
        if( res<-1.0 || t>tmax ) break;
    }
    res = max(res,-1.0); // clamp to [-1,1]

    return 0.25*(1.0+res)*(1.0+res)*(2.0-res); // smoothstep
}

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 C = glFragColor;

    float fl = 2.4;
    vec2 uv = (U - R*.5) / R.y;
    vec3 la = vec3(0),
         lp = vec3(4,5,-2),
         ro = vec3(0,0.1+sin(T*0.07)*0.4,-1.4 - sin(T*0.02)*0.04);
    //camera    
    ro.xz *= rot(sin(0.1*(T + 4.6))*0.6);
    vec3 fwd = normalize(la-ro),
         rgt = normalize(vec3(fwd.z,0.0,-fwd.x)),
         rd = normalize(fwd + fl*uv.x*rgt + fl*uv.y*cross(fwd, rgt));
    //background
    //(1.0 + rd.y*rd*100.0) cool %&*$ up
    vec3 pc = vec3(0.2,0.1,0.0)*nz(12.*rd+0.3*T)*.1/(1.0 + rd.y*rd.y*100.0),
         gc = vec3(0);
    //raymarching
    vec4 trap;
    float mint = FAR,
          s = hash13(rd)*0.1;
    for (int i=ZERO; i<240; i++)
    {
        vec3 p = ro + rd*s;
        vec2 ns = map(p, trap);
        float d = abs(ns.x);
        if (d<EPS) break;
        vec3 h3 = hash33(p*1.0) - 0.5;
        vec2 b1 = sphIntersect(p, normalize(-p), B1);
        vec2 b2 = sphIntersect(p - h3*0.04, normalize(-p), B2);
        if (b1.x>0.0 && max(b2.x,b2.y)>0.0)
        {
            gc += 0.06*vec3(1.0,0.2,0.0) * max(0.7,hash13(p))
                  / (0.6 + ns.y*ns.y*100.0);    
        }
        gc += 0.02*vec3(1.0,0.2,0.0) / (1.0 + ns.y*ns.y*400.0);
        s += d*0.6;
        if (s>FAR) 
        {
            s = -1.0;
            break;
        } 
    }
    //shading
    if (s>0.0)
    {
        mint = s;
        vec3 p = ro + rd*s,
             n = normal(p),
             ld = normalize(lp - p);
        pc = mix(vec3(0.02), vec3(0.6,0.0,0.0), clamp(trap.y,0.0,1.0));
        pc = mix(pc, vec3(0.8,0.2,0.0), clamp(trap.z*trap.z*0.4,0.0,1.0));
        pc = mix(pc, vec3(1.0,0.4,0.0), clamp(pow(trap.w,8.0),0.0,1.0));
        pc += vec3(1.0,0.1,0.0)*0.4*max(0.0,-n.y);
        pc *= max(0.05,dot(ld,n));
        pc += vec3(0.5)*pow(max(dot(reflect(-ld,n),-rd),0.0),16.0);
        pc *= clamp(0.03*log(trap.x), 0.0, 1.0)*apprSoftShadow(p, ld, 0.01, FAR, 0.1);
    }
    //glow ball
    vec2 bc = sphIntersect(ro,rd,B1);
    float sds = sphDensity(ro,rd,B1,FAR);
    if (bc.x>0.0 && bc.x<mint)
    {
        vec3 p = ro + rd*bc.x,
             n = normalize(p - B1.xyz),
             ld = normalize(lp - p);
        pc = vec3(1.0,0.2,0.0)*sds*sds + vec3(1.0,0.6,0.1)*pow(sds,6.0);
    }

    pc += gc;
    
    pc = pow(pc, vec3(1./2.4));
    pc *= 1.0 - 0.08*length(uv);
    
    glFragColor = vec4(pc,1.0);
}
