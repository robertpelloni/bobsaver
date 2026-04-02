#version 420

// original https://www.shadertoy.com/view/MlcfWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine

// Thanks to wsmind, leon, XT95, lsdlive, lamogui and Coyhot for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Cookie Collective rulz

#define ITER 64.
#define PI 3.141592
#define time time
#define BPM 143./2.
#define tempo BPM/60.

vec3 palette (float t, vec3 a, vec3 b, vec3 c, vec3 d)
{return a+b*cos(2.*PI*(c*t+d));}

float random (vec2 st)
{return fract(sin(dot(st.xy, vec2(12.2544, 35.1571)))*5418.548416);}

vec2 moda (vec2 p, float per)
{
    float a = atan(p.y, p.x);
    float l = length(p);
    a = mod(a-per/2., per)-per/2.;
    return vec2(cos(a),sin(a))*l;
}

vec2 mo(vec2 p, vec2 d)
{
    p = abs(p)-d;
    if (p.y > p.x) p.xy = p.yx;
    return p;
}

float stmin(float a, float b, float k, float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b), 0.5 * (u+a+abs(mod(u-a+st,2.*st)-st)));
}

float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 );
    return min( a, b ) - h*h*0.25/k;
}

mat2 rot(float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float sphe (vec3 p, float r)
{return length(p)-r;}

float od (vec3 p, float d)
{return dot(p, normalize(sign(p)))-d;}

float cyl (vec2 p, float r)
{return length(p)-r;}

float box( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sc (vec3 p, float d)
{
    p = abs(p);
    p = max(p.xyz, p.yzx);
    return min(p.x, min(p.y,p.z)) - d;
}

float prim1(vec3 p)
{
    float s = sphe(p,1.);
    p.xz *= rot(time*tempo);
    p.xz *= rot(p.y*0.5);
    p.xz = moda(p.xz, 2.* PI/5.);
    p.x -= .8;
    return smin(s,cyl(p.xz, 0.1), 0.5);
}

float prim2(vec3 p)
{
    float p1 = max(-od(p,.9), prim1(p));
    p.xz *= rot(time);
    p.xy *= rot(time);
    return min(p1, od(p, 0.5));
}

float prim3(vec3 p)
{
    p.xy = mo(p.xy, vec2(3.,2.));
    return prim2(p);
}

float prim4 (vec3 p)
{
    float per = 3.;
    p.xy *= rot(p.z*0.2);
    p.z = mod(p.z-per/2., per)- per/2.;
    return prim3(p);
}

float prim5 (vec3 p)
{
    float p1 = prim4(p);
    p.z -= time*tempo;
    p.xz *= rot(time);
    p.xy *= rot(time);
    float p2 = stmin(od(p, .5), sphe(p,.5), 0.5, 5.);
    return min(p1, p2);
}

float g = 0.;
float SDF(vec3 p)
{
    float d = prim5(p); 
    g += 0.1/(0.1+d*d);
    return d;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    //uv += texture(iChannel0, uv+time).r*0.02;
    
    vec3 ro = vec3(0.001,0.001,-10.+time*tempo); vec3 p = ro;
    vec3 rd = normalize(vec3(uv,1.));

    float shad = 0.;
    float dither = random(uv);

    for (float i=0.; i<ITER; i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            shad = i/ITER;
            break;
        }
        d *= 0.9 + dither*0.1;
        p += d*rd;
    }

    float t = length(ro-p);

    vec3 pal = palette
        (length(uv),
         vec3(0.5),
         vec3(0.5),
         vec3(0.5),
         vec3(0.1,0.,0.8));

    vec3 pal1 = palette
        (abs(uv.y),
         vec3(0.5),
         vec3(0.5),
         vec3(0.4),
         vec3(0.3,0.,0.));

    vec3 c = vec3(shad) * pal;
    c = mix(c, pal1*0.3, 1.- exp(-.001*t*t));
    c += g*0.08*length(uv);
    glFragColor = vec4(c,1.);
}
