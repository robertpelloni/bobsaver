#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3dsfDj

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------

#define R resolution.xy
#define ZERO (min(frames,0))
#define S(a, b, v) smoothstep(a, b, v)
#define EPS .003
#define FAR 20.
#define T time
#define PI 3.14159
#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1.0 / float(0xffffffffU))

//Fabrice - compact rotation
mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}

//Dave Hoskins - improved hash without sin
//https://www.shadertoy.com/view/XdGfRR
vec3 h3(vec3 p) 
{
    uvec3 q = uvec3(ivec3(p)) * UI3;
    q = (q.x ^ q.y ^ q.z) * UI3;
    return vec3(q) * UIF;
}

float h1(float p) 
{
    vec3 x  = fract(vec3(p) * .1031);
    x += dot(x, x.yzx + 19.19);
    return fract((x.x + x.y) * x.z);
}

vec3 hash31(float p) 
{
   vec3 p3 = fract(vec3(p) * vec3(443.8975,397.2973, 491.1871));
   p3 += dot(p3.xyz, p3.yzx + 19.19);
   return fract(vec3(p3.x * p3.y, p3.x*p3.z, p3.y*p3.z));
}

vec3 n13(float n) 
{
    float f = fract(n);
    n = floor(n);
    f = f * f * (3.0 - 2.0 * f);
    return mix(hash31(n), hash31(n + 1.0), f);
}

//Shane IQ
float n3D(vec3 p) 
{    
    const vec3 s = vec3(7, 157, 113);
    vec3 ip = floor(p); 
    p -= ip; 
    vec4 h = vec4(0.,s.yz,s.y + s.z) + dot(ip, s);
    p = p * p * (3. - 2. * p);
    h = mix(fract(sin(h)*43758.5453),fract(sin(h + s.x)*43758.5453),p.x);
    h.xy = mix(h.xz,h.yw,p.y);
    return mix(h.x,h.y,p.z);
}

float noise(vec2 uv, float s1, float s2, float t1, float t2, float c1) 
{
    return clamp(h3(vec3(uv.xy * s1, t1)).x +
                 h3(vec3(uv.xy * s2, t2)).y, 
                 c1, 
                 1.);
}

//Shane - Perspex Web Lattice - one of my favourite shaders
//https://www.shadertoy.com/view/Mld3Rn
//Standard hue rotation formula... compacted down a bit.
vec3 rotHue(vec3 p, float a)
{
    vec2 cs = sin(vec2(1.570796,0) + a);

    mat3 hr = mat3(0.299,  0.587,  0.114,  0.299,  0.587,  0.114,  0.299,  0.587,  0.114) +
              mat3(0.701, -0.587, -0.114, -0.299,  0.413, -0.114, -0.300, -0.588,  0.886) * cs.x +
              mat3(0.168,  0.330, -0.497, -0.328,  0.035,  0.292,  1.250, -1.050, -0.203) * cs.y;
                             
    return clamp(p*hr,0.,1.);
}

//SDFs - IQ
float sdBox(vec3 p, vec3 b)
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdCappedCylinder(vec3 p, float h, float r)
{
  vec2 d = abs(vec2(length(p.xy),p.z)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdSegment(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sdArc(vec2 p, vec2 sca, vec2 scb, float ra, float rb)
{
    p *= mat2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

float smax(float a, float b, float k) 
{
    float h = clamp( 0.5 + 0.5 * (b - a) / k, 0.0, 1.0 );
    return mix(a, b, h) + k * h * (1.0 - h);
}

float dfS3DPart(vec3 p)
{
    vec3 q = p;
    q.y *= 2.0;
    float t = sdCappedCylinder(q,2.0,0.5); 
    q.xy *= rot(0.5);
    float l = max(0.0,p.y - 0.2)*max(0.0,p.y - 0.2)*-0.2*sign(q.z);
    t = min(t, sdBox(q - vec3(1.0,1.0,0.0), vec3(1.0,1.8,0.5 + l)));
    q = p;
    q.y *= 4.0;
    t = max(t, -sdCappedCylinder(q - vec3(0.0,-1.4,0.0),1.2,5.0)); 
    q = p;
    q.xy *= rot(0.3); 
    t = smax(t, -sdBox(q - vec3(1.7,0.0,0.0), vec3(1.0,4.0,2.0)),0.2);    
    return max(t, -sdBox(p - vec3(1.0,-1.0,0.0), vec3(1.0,1.0,2.0)));
}

float dfS3D(vec3 p)
{
    p.xy *= rot(-0.5);
    float t = dfS3DPart(p - vec3(0.0,0.825,0.0));
    p.xy *= rot(PI);
    return min(t, dfS3DPart(p - vec3(0.0,0.825,0.0)));
}

float dfH3D(vec3 p)
{
    float l = max(0.0,p.x*0.5 + 0.6)*max(0.0,p.x*0.5 + 0.6)*0.3;
    float t = sdCappedCylinder(p - vec3(1.0,6.0,0.0),5.0,0.5 + l);  
    vec3 q = p;
    q.xy *= rot(0.1);
    t = min(t, sdBox(q - vec3(-1.0,0.0,0.0), vec3(0.6,3.0,0.5)));
    t = smax(t, -sdBox(p - vec3(-1.0,-3.0,0.0), vec3(2.0,1.0,1.0)),0.2);    
    t = smax(t, -sdCappedCylinder(p - vec3(1.0,6.0,0.0),4.0,4.0),0.2);
    t = smax(t, -sdBox(q - vec3(-3.4,0.0,0.0), vec3(2.0,10.0,1.0)),0.2);
    t = smax(t, -sdBox(p - vec3(4.1,0.0,0.0), vec3(4.0,16.0,10.0)),0.2);
    t = max(t, -sdBox(p - vec3(0.0,9.0,0.0), vec3(10.0,4.0,4.0)));
    t = min(t, sdBox(p - vec3(1.0,0.0,0.0), vec3(0.5,2.0,0.5)));  
    q = p;
    l = max(0.0,p.x*-0.5)*max(0.0,p.x*-0.5)*0.3;
    return min(t, sdBox(q - vec3(-0.5,-0.4,0.0), vec3(1.4,0.2,0.5 + l)));
}

float dfA3D(vec3 p)
{
     float t = sdBox(p - vec3(-0.2,0.0,0.0), vec3(0.5,2.0,0.5));
    float l = max(0.0,(p.x-2.5)*-1.0)*max(0.0,(p.x-2.5)*-1.0)*0.1;
    t = min(t, sdBox(p - vec3(1.7,-1.6,0.0), vec3(0.9,0.6,0.5 + l)));
    vec3 q = p;
    q.xy *= rot(0.6);
    t = min(t, sdBox(q - vec3(1.2,0.0,0.0), vec3(0.5,4.0,0.5)));
    l = max(0.0,p.x+0.2)*max(0.0,p.x+0.2)*0.1;
    t = min(t, sdBox(p - vec3(1.2,-0.4,0.0),vec3(1.6,0.2,0.5 + l)));
    t = min(t, sdCappedCylinder(p - vec3(-1.0,6.0,0.0),5.0,0.5 + l));
    t = smax(t, -sdCappedCylinder(p - vec3(-1.0,6.0,0.0),4.0,5.0),0.2);
    t = smax(t, -sdBox(p - vec3(-3.5,0.0,0.0), vec3(3.0,16.0,5.0)),0.2); 
    t = smax(t, -sdBox(q - vec3(7.0,0.0,0.0), vec3(4.0,10.0,5.0)),0.2);
    return smax(t, -sdBox(p - vec3(2.0,-3.0,0.0), vec3(4.0,1.0,2.0)),0.2);
}

float dfU3D(vec3 p)
{
    vec3 q = p;
    q.xy *= rot(-0.3);
    q.x *= 3.0;
    float t = sdCappedCylinder(q - vec3(0.0,2.0,0.0),4.0,0.5);
    t = min(t, sdBox(p - vec3(1.8,0.0,0.0), vec3(0.5,2.2,0.5)));
    float l = max(0.0,(q.x + 2.0)*-0.5)*max(0.0,(q.x + 2.0)*-0.5)*0.1;
    l = min(l, 2.0);
    t = min(t, sdCappedCylinder(p - vec3(-5.0,6.0,0.0),6.5,0.5 + l));
    t = smax(t, -sdCappedCylinder(p - vec3(-5.0,6.0,0.0),5.5,20.0),0.2);
    t = smax(t, -sdCappedCylinder(q - vec3(1.0,2.0,0.0),2.0,1.0),0.2);
    q = p;
    q.xy *= rot(0.6);
    t = smax(t, -sdBox(q - vec3(-5.4,6.0,0.0), vec3(4.0,6.0,10.0)),0.2);
    return smax(t, -sdBox(p - vec3(-5.0,8.0,0.0), vec3(8.0,6.0,20.0)),0.2);
}

float dfS2DPart(vec2 uv)
{
    float t = sdSegment(uv, vec2(0.5,1.35), vec2(1.4,1.1));
    t = min(t, sdSegment(uv, vec2(1.4,1.1), vec2(1.1,-0.0)));
    uv *= rot(0.9);
    uv.x *= 2.0;
    return min(t, sdArc(uv, vec2(1.0,0.0),vec2(1.0,0.0), 1.3, 0.0));
}

float dfS2D(vec2 uv) 
{
    float t = dfS2DPart(uv - vec2(0.0,0.8));
    uv *= rot(PI);
    return min(t, dfS2DPart(uv - vec2(0.0,0.8)));
}

float dfH2D(vec2 uv)
{
    float t = sdSegment(uv,vec2(-1.0,1.6),vec2(-1.0,-1.8));
    t = min(t, sdSegment(uv,vec2(-1.6,-1.8),vec2(-1.0,-1.8)));
    t = min(t, sdSegment(uv,vec2(-3.3,-1.8),vec2(-2.7,-1.8)));
    t = min(t, sdSegment(uv,vec2(-3.4,-1.0),vec2(-3.3,-1.8)));
    t = min(t, sdSegment(uv,vec2(-3.6,1.4),vec2(-3.5,0.3)));
    t = min(t, sdSegment(uv,vec2(-4.0,-0.4),vec2(-1.4,-0.4)));
    uv -= vec2(-2.0,4.7);
    uv *= rot(-0.4);
    return min(t, sdArc(uv, vec2(1.0,0.0),vec2(-0.45,1.0), 2.8, 0.));
}

float dfA2D(vec2 uv)
{
    float t = sdSegment(uv,vec2(0.0,1.8),vec2(0.0,-1.4));
    t = min(t, sdSegment(uv,vec2(0.4,-0.4),vec2(2.8,-0.4)));
    t = min(t, sdSegment(uv,vec2(1.4,-1.8),vec2(3.2,-1.8)));
    t = min(t, sdSegment(uv,vec2(3.2,-1.8),vec2(2.65,-1.0)));
    t = min(t, sdSegment(uv,vec2(1.25,1.1),vec2(1.8,0.3)));
    uv.y -= 4.8;
    uv *= rot(0.36);
    return min(t, sdArc(uv, vec2(1.0,0.0),vec2(-0.4,1.0), 3.0, 0.));
}

float dfU2D(vec2 uv)
{
    vec2 quv = uv - vec2(0.0,1.1);
    quv *= rot(-0.3);
    quv.x *= 3.0;
     float t = sdArc(quv, vec2(1.0,0.0),vec2(-1.0,0.0), 2.8, 0.0);
    t = min(t, sdSegment(uv, vec2(1.4,1.7), vec2(1.4,-1.8)));
    t = min(t, sdSegment(uv, vec2(1.4,-1.8), vec2(0.9,-1.8)));
    t = min(t, sdSegment(uv, vec2(-1.7,1.8), vec2(-0.6,1.8)));
    quv = uv - vec2(-4.0,4.3);
    quv *= rot(0.54);
    return min(t, sdArc(quv, vec2(1.0,0.0),vec2(-0.24,1.0), 3.4, 0.));    
}

float map(vec3 p) 
{
    float t = dfS3D(p - vec3(-5.2,0.0,0.0));
    t = min(t, dfH3D(p - vec3(-2.3,0.0,0.0)));
    t = min(t, dfA3D(p - vec3(0.2,0.0,0.0)));
    t = min(t, dfU3D(p - vec3(4.4,0.0,0.0)));
    return t -0.1;
}

vec3 normal(vec3 p) 
{  
    vec4 n = vec4(0.0);
    for (int i=ZERO; i<4; i++) 
    {
        vec4 s = vec4(p, 0.0);
        s[i] += EPS;
        n[i] = map(s.xyz);
    }
    return normalize(n.xyz-n.w);
}

//IQ - http://www.iquilezles.org/www/articles/raymarchingdf/raymarchingdf.htm
float AO(vec3 p, vec3 n) 
{    
    float ra = 0., w = 1., d = 0.;
    for (float i = 1.; i < 12.; i += 1.){
        d = i / 5.;
        ra += w * (d - map(p + n * d));
        w *= .5;
    }
    return 1. - clamp(ra, 0., 1.);
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float apprSoftShadow(vec3 ro, vec3 rd, float mint, float tmax, float w)
{
     float t = mint;
    float res = 1.0;
    for( int i=ZERO; i<256; i++ )
    {
         float h = map(ro + t*rd);
        res = min( res, h/(w*t) );
        t += clamp(h, 0.005, 0.30);
        if( res<-1.0 || t>tmax ) break;
    }
    res = max(res,-1.0); // clamp to [-1,1]

    return 0.25*(1.0+res)*(1.0+res)*(2.0-res); // smoothstep
}

float sparkles(vec2 uv)
{
    float t = length(uv - vec2(-3.9,1.9));
    t = min(t, length(uv - vec2(-6.4,-2.0)));
    t = min(t, length(uv - vec2(-1.0,1.7)));
    t = min(t, length(uv - vec2(-4.1,-0.4)));
    t = min(t, length(uv - vec2(-2.4,1.95)));
    t = min(t, length(uv - vec2(1.9,2.5)));
    t = min(t, length(uv - vec2(3.0,-0.4)));
    t = min(t, length(uv - vec2(4.3,1.8)));
    return min(t, length(uv - vec2(6.4,1.75)));
}

vec2 pol(vec3 rd)
{
    float a = (atan(rd.x,rd.y)/6.28318) + 0.5;
    return vec2(a,floor(a*24.0)/24.0);  
}

vec3 bg3(vec3 rd, vec3 hu, float nz)
{
    vec2 pa = pol(rd);
    float m = mod(abs(rd.y) + h1(pa.y*sign(rd.z))*4. - T*.08, .3); 
    return hu*step(.1, fract(pa.x * 24.))*h1(pa.y)*step(m, .16)*m*50.0*rd.y*rd.y +
           hu/(1.0 + rd.y*rd.y*1000.0)*nz;
}

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 C = glFragColor;

    vec2 uv = (U - R*.5) / R.y;
    float fl = 1.4,
          AT = mod(T, 40.),
          nz = noise(uv, 64., 16., float(frames), float(frames), .96);
    vec3 la = vec3(0),
         lp = vec3(4,6,-5),
         ro = vec3(0,sin(T*0.2),-8. - cos(T*0.4)*0.5),
         hu = rotHue(vec3(1,0.1,0.2), T*0.1),
         hu2 = rotHue(vec3(1,0.1,0.2), (T+6.0)*0.1);
    ro.xz *= rot(sin(T*0.1)*0.2);
    ro += 0.1*n13(T);
    //camera
    vec3 fwd = normalize(la-ro),
         rgt = normalize(vec3(fwd.z,0.0,-fwd.x)),
         rd = normalize(fwd + fl*uv.x*rgt + fl*uv.y*cross(fwd, rgt));
    //background
    float yy = rd.y*rd.y;
    vec2 pa = pol(rd); 
    vec3 pc1 = (hu/(1.0 + yy*32.0) +
                mix(hu,vec3(1),0.7)/(1.0 + yy*256.0)) * nz,
         pc2 = (hu*yy*8.0 +
                mix(hu,vec3(1),0.7)*yy*2.*clamp(nz,0.96,1.0)) * clamp(nz,0.98,1.0),
         pc3 = bg3(rd,hu,nz),
         pc4 = mix(mix(hu*nz,vec3(1),yy*4.0),
                   hu,
                   S(0.02, 0.0, length(fract(yy*6.0-T*0.4) - 0.5)) +
                  (S(0.46, 0.5, fract(pa.x*24.0)) * S(0.54, 0.5, fract(pa.x*24.0))))*yy*8.;
    //ray march
    float t = 0.0;   
    for (int i=ZERO; i<200; i++)
    {
        float ns = map(ro + rd*t);
        if (abs(ns)<EPS) break;
        t += ns *0.8;
        if (t>FAR) 
        {
            t = -1.0;
            break;
        }
        
    }
    //render
    if (t>0.0)
    {
        vec3 p = ro + rd*t,
             n = normal(p),
             rrd = reflect(rd,n),
             ld = normalize(lp - p),
             bgc = mix(hu,hu2,clamp((p.y*-1.)+sin(p.x*2.)*0.3,0.,1.));        
        float ao = AO(p,n),
              spec = pow(max(dot(reflect(-ld, n), -rd), 0.0), 8.0),
              spec2 = max(dot(reflect(-ld, n), -rd), 0.0),
              frs = pow(clamp(dot(n, rd) + 1.,0.,1.),1.),
              sh = apprSoftShadow(p, ld, 0.01, FAR, 0.1),
              spa = sparkles(p.xy);

        float hg = dfS2D(p.xy - vec2(-5.2,0.0));
        hg = min(hg, dfH2D(p.xy));
        hg = min(hg, dfA2D(p.xy));
        hg = min(hg, dfU2D(p.xy - vec2(5.0,0.0)));
        
        //neon
        pc1 = hu*2.0 / (1.0 + hg*hg*100.6);
        pc1 += hu2*max(0.0,n.y)*0.3;
        pc1 += vec3(2) * spec;
        pc1 *= ao;
        
        //hip-hop
        pc2 = vec3(0.4,0.6,0.6) + bgc / (1. + hg*hg*0.6);
        vec3 hg2 = mix(pc2,bgc,1.0/(1.0 + hg*hg*100.));
        pc2 = mix(pc2,hg2,S(0.0,1.0,abs(p.y+0.4)));
        pc2 = mix(pc2,bgc*2.0,1.0/(1.0 + spa*spa*6.0));
        vec3 hg3 = mix(pc2, vec3(2), 1.0/(1.0 + hg*hg*400.));        
        pc2 = mix(pc2,hg3,S(0.5,2.0,abs(p.y+0.4)));
        pc2 *= max(0.05,dot(ld,n));
        pc2 *= ao * sh;
        pc2 += vec3(0.3)*(spec + spec2);
        pc2 += vec3(1)/(1.0 + spa*spa*30.0);        

        //dark reflection
        pc3 = mix(mix(hu*0.4,vec3(0.2),0.4)*max(0.05,dot(ld,n)),
                  bg3(rrd,hu,nz)*0.5,
                  S(0.15,0.12,hg));
        pc3 += hu2*max(0.0,n.y)*0.3;
        pc3 += vec3(2)*spec;
        pc3 *= ao*sh;
        
        //silver
        pc4 = mix(hu,vec3(1),0.7)*max(0.,0.6+dot(ld,n)*0.4);
        pc4 += hu2*max(0.0,n.y)*0.4;
        pc4 += vec3(0.7)*spec2 + vec3(1)*spec;
        pc4 *= ao*(0.6 + sh*0.4);
        pc4 = mix(pc4,hu,1.0/(1.0 + hg*hg*60.));
        pc4 += vec3(2) / (1.0 + hg*hg*1000.);
        
    }
    //transitions
    vec2 axy = fract((uv-0.5)*40.0) - 0.5;
    vec3 pc = mix(pc1,pc2,step(length(axy),clamp(uv.y - (5. - AT),-0.1,1.4))); 
    pc = mix(pc4,pc,step(length(axy),clamp(length(uv) - (AT - 15.0),-0.1,1.4)));
    pc = mix(pc3,pc,step(length(axy),clamp(uv.y - (-25. + AT),-0.1,1.4)));
    pc = mix(pc1,pc,step(length(axy),clamp(length(uv) - (AT - 35.0),-0.1,1.4)));
    pc *= 1. + sin(uv.y*800. + T)*0.02;
    pc *= 1. + sin(uv.x*800. + T)*0.02;
    
    C = vec4(pc,1.0);

    glFragColor = C;
}
