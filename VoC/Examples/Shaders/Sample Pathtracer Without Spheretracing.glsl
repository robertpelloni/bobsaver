#version 420

// original https://www.shadertoy.com/view/MtGyWK

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.28318530718
#define PI 3.14159265358

#define FAR 1e+31
#define INF (1./.0)

#define AA 1.0
#define DOF 0.05

//Make this number as high
//as your machine can handle
#define SAMPLES 80

#define BOUNCES 3
#define TINT 0.5

// Utility

mat3 rx(float a){ float sa=sin(a), ca=cos(a); return mat3(1.,0.,0.,0.,ca,sa,0.,-sa,ca); }
mat3 ry(float a){ float sa=sin(a), ca=cos(a); return mat3(ca,0.,sa,0.,1.,0.,-sa,0.,ca); }
mat3 rz(float a){ float sa=sin(a), ca=cos(a); return mat3(ca,sa,0.,-sa,ca,0.,0.,0.,1.); }

float box(vec3 p){ p=abs(p); return max(max(p.x, p.y), p.z); }
float box(vec2 p){ p=abs(p); return max(p.x, p.y); }

// Hashing functions

vec2 hash23(vec3 p3)
{
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec3 hashSp(uint seed)
{
    float a=(float((seed*0x73493U)&0xfffffU)/float(0x100000))*2.-1.;
    float b=6.283*(float((seed*0xAF71fU)&0xfffffU)/float(0x100000));
    float c=sqrt(1.-a*a);
    return vec3(c*cos(b),a,c*sin(b));
}

vec3 hashRd(uint seed)
{
    float r = float((seed*0xF4A37U)&0xfffffU)/float(0x100000);
    return sqrt(r) * hashSp(seed);
}

vec3 hashHs(vec3 n, uint seed)
{
    vec3 r = hashSp( seed );
    return dot(r,n)>0.?r:-r;
}

// Tracing

float t;
vec3 sp, sn, mat;
int samp;

float sphere(vec3 ro, vec3 rd)
{
    vec3 p = ro + ( dot(-ro, rd) * rd);
    float nt = length(p - ro) - sqrt(1. - dot(p,p));
    if(nt < .01)nt = 1e+31;
    
    if(nt < t)
    {
        t = nt;
        sp = ro + rd * t;
        sn = normalize(sp);
    }
    
    return nt;
}

float plane(vec3 ro, vec3 rd, vec3 n, float d)
{
    float nt = -(dot(ro,n) + d) / dot(n, rd);
    if(nt < .01)nt = 1e+31;
    
    if(nt < t)
    {
        t = nt;
        sp = ro + rd * t;
        sn = n;
    }
    
    return nt;
}

float tracer(vec3 ro, vec3 rd)
{   
    t = INF;
    
    float ball = sphere(ro, rd);
    
    float lit_wall = INF;
    lit_wall = min(lit_wall, plane(ro, rd, vec3( 0, 1, 0), 1.));
    lit_wall = min(lit_wall, plane(ro, rd, vec3( 0, 0,-1), 2.));
    lit_wall = min(lit_wall, plane(ro, rd, vec3(-1, 0, 0), 6.));
    
    lit_wall = min(lit_wall, plane(ro, rd, vec3( 1, 0, 0), 8.));
    lit_wall = min(lit_wall, plane(ro, rd, vec3( 0, 0, 1), 8.));
    
    //plane(ro, rd, vec3( 1, 0, 0), 8.);
    //plane(ro, rd, vec3( 0, 0, 1), 8.);
    plane(ro, rd, vec3( 0,-1, 0), 8.);
    
    mat = vec3(.8, 0, 0);
    
    if(t == lit_wall)
    {
        float tm = time + .2;
        float h = sp.y + .6*round(sp.x/3.);
        mat.y = step(.75, fract(.7*round(4.*tm) - h - 0.05));
        mat.z = sin(h-tm);
    }
    else if(t == ball)mat = vec3(0,0,0);
    
    //mat.yz = hash23(round(sp)+0.001*time);
    //mat.y *= mat.y * mat.y;
    //mat.z = 2. * mat.z - 1.;
    
    return t;
}

// Rendering

void camera(out vec3 ro, out vec3 rd, in vec2 p, uint seed)
{
    #ifdef AA
    p.xy += AA * (hash23(vec3(p.xy, samp))-.5);
    #endif
    
    vec2 uv = (2.*p.xy-resolution.xy)/resolution.x;
    vec2 rv = vec2(.2 + .2*cos(time), -.7 + .6*sin(time));
    
    #ifdef DOF
    rv += DOF * hashRd(seed).xy;
    //rv += DOF * (hash23(vec3(samp, p.xy))-.5);
    #endif
    
    mat3 rm = ry(rv.y) * rx(rv.x);
    ro = rm * vec3(-.5, 0, -3) + vec3(-.5,0,0);
    rd = rm * normalize(vec3(uv, 1));
}

vec4 render(vec2 coord)
{
    uvec2 temp = uvec2(coord + 4.*resolution.yx);
    uint seed = temp.x * temp.y * uint(samp+1);
    
    vec3 emit = vec3(0), ro, rd;
    camera(ro, rd, coord, seed);
    
    for(int i=0; i < BOUNCES; i++)
    {
        tracer(ro, rd);
        if(t > FAR)break;
        
        emit += 0.5 * mat.y * vec3(1.+mat.z, 1.-TINT, 1.-mat.z);
        
        seed ^= uint(samp) / uint(i+1);
        rd = normalize(mix(reflect(rd, sn), hashRd(seed), mat.x));
        if(dot(rd,sn) < .0)rd = -rd;
        ro = sp;
    }
    
    emit = 10. * emit / (box(emit)+1.);
    emit = pow(emit, vec3(.4545));
    
    #ifdef EMITCLAMP
    emit = clamp(vec3(0), vec3(1), emit);
    #endif
    
    return vec4(emit, 1);
}

void main(void)
{
    vec4 acc = vec4(0);
    for(int i=0; i<SAMPLES; i++)
    {
        samp = SAMPLES * frames + i;
        acc += render(gl_FragCoord.xy);
    }
    
    acc /= acc.w;
    
    glFragColor = acc;
}
