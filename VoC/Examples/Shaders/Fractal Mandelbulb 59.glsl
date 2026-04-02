#version 420

// original https://www.shadertoy.com/view/fll3R8

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int I = 0;
const int NI = 200;
const float M = 100.;
const float EPS = .002;

#define PI 3.14159

#if HW_PERFORMANCE==0
#define AA 1
#else
#define AA 2  // make AA 1 for slow machines or 3 for fast machines

#endif

#define ZERO (min(frames,0))

mat3 cam(vec3 cO, vec3 t, float r)
{
    vec3 w = normalize(t - cO);
    vec3 up = vec3(sin(r),cos(r), 0.0);
    vec3 u = normalize(cross(up,w));
    vec3 v = normalize(cross(w,u));
    return mat3(u,v,w);
}

mat3 rotY(float a)
{ 
    float c = cos(a); float s = sin(a); 
    return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}

float bulb(vec3 p)
{
    float t = atan(p.y, p.x);
    float a = atan(p.z, sqrt(p.x*p.x + p.y*p.y));
    float r = length(p);
    float q = 10.; 
    
    float d = r;
    vec3 g;
    float Rq; 
    
    for(;I < NI; I++)
    {
        Rq = pow(r,q);
       
        g.x = Rq*sin(q*a)*cos(q*t) + p.x;
        g.y = Rq*sin(q*a)*sin(q*t) + p.y;
        g.z = Rq*cos(q*a) + p.z;
        
        if(length(g) > M)
        {
            break;
        }
        
        t = atan(g.x,g.y);
        a = atan(g.z, sqrt(g.x*g.x + g.y*g.y));
        r = length(g);
        d += (q*Rq*d+1.);
    }
    
    return r*log(r)/d;
}

float map(vec3 p)
{
    p*=rotY(time*0.1);
    return bulb(p);
}

vec3 norm(in vec3 p)
{
    vec2 e = vec2(EPS, 0.);
    return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), 
                          map(p + e.yxy) - map(p - e.yxy), 
                          map(p + e.yyx) - map(p - e.yyx)));
}

float rm(vec3 ro, vec3 rd, float tmin, float tmax)
{
    float d = tmin;
    float ds = 0.;
    for(; d <= tmax; d+=ds)
    {
        vec3 p = ro + rd * d;
        ds = map(p);
        if(ds < EPS)break;
    }
    return d;
}

vec3 shade(vec3 p, vec3 n, vec3 v)
{
    const vec3 lD = -normalize(vec3(.1, .32, .80));
    const vec3 lC = vec3(5.0);
   
    vec3 h = normalize(v+lD);
    
    float ri = float(I)/float(NI);

    vec3 cD = vec3(0.773, 0.522*(1.-ri), 0.286);
    vec3 cS = vec3(1.000, 0.937, 0.800);
    vec3 fO = mix( vec3(0.04), vec3(1.0, 0.86, 0.57), 1.-ri); 
     
    float kD = max(0.001, dot(n, lD));
    float kH = max(0.0, dot(n, h));
    float kHV = clamp(max(0.0, dot(v, h)), 0.0, 1.0);
    float kV = max(0.001, dot(n, v));
       
    vec3 F = fO + (1.-fO) * pow(1.-abs(kHV), 5.);
    float a = ri * ri;
    float s = (kH * a - kH) * kH + 1.0;
    float D = a / (PI * s * s);
    float attL = 2.0 * kD / (kD + sqrt(a + (1.0 - a) * (kD * kD)));
    float attV = 2.0 * kV / (kV + sqrt(a + (1.0 - a) * (kV * kV)));
    float G = attL * attV;
    vec3 b = F * D * G / (4. * kD * kV);
    cD = (1.0-F)* (1.0/PI)*cD;
    
    // Ra
    vec3 refl = -normalize(reflect(v, n));
    vec3 dA = vec3(0.0); //cD * pow(texture(iChannel0, n).rgb, vec3(2.2));
    vec3 sA = vec3(0.0); //F * pow(textureLod(iChannel0, refl, ri*11.).rgb, vec3(2.2));
    vec3 cA = dA + sA;
    
    return cA  + lC * kD * ( cD + cS * b);
}

vec3 draw(vec3 cO, mat3 mCam, vec2 U)
{
    const float fov = 2.2;
    vec2 uv = (2. * U - resolution.xy) / resolution.y;
    vec3 cD = normalize(mCam * vec3(uv, fov));

    float tmin = 0.1;
    float tmax = 10.;
    float d = rm(cO, cD, tmin, tmax);
    
    vec3 col = vec3(0);
    
    if(d >= tmax){return vec3(0.0); } // texture(iChannel0, cD).rgb;}
    
    float r = float(I)/float(NI);
   
    vec3 p = cO + cD * d;
    vec3 n = norm(p);
    vec3 l = normalize(vec3(0, -1, 1));
    float NdotL = max(0.,dot(n, -l));
    col = shade(p, n, cD) * (1.- r * 0.85);
    
    return col;
}

void main(void)
{
    vec2 U = gl_FragCoord.xy;

    float a = PI * 0.5 + 1.95 * PI * (2. ) / resolution.x;
    vec3 cO = vec3(cos(a), 0.0, sin(a)) * -3.;
    vec3 t = vec3(0.0, .02, 0.0);
    mat3 mCam = cam(cO, t, 0.0);
    
    #if AA<2
    vec3 col = draw( cO, mCam, U);
    #else
    vec3 col = vec3(0.0);
    for( int j=ZERO; j<AA; j++ )
    for( int i=ZERO; i<AA; i++ )
    {
        col += draw( cO, mCam, U + (vec2(i,j)/float(AA)));
    }
    col /= float(AA*AA);
    #endif
    
    glFragColor = vec4(col,1.0);
}
