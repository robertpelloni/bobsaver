#version 420

// original https://www.shadertoy.com/view/Mt3BDN

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
#define BPM 25./2.
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

float prim1 (vec3 p)
{
    float s = sphe(p, 1.);
    p.xz = moda(p.xz, 2.*PI/4.);
    p.x -= 1.;
    return max(s, -od (p,.5));
}

float prim2(vec3 p)
{
    p.xy = mo(p.xy, vec2(2.));
    float p1 = prim1(p);
    p.xz *= rot(time*tempo);
    p.xz *= rot(p.y);
    p.xz = moda(p.xz, 2.*PI/8.);
    p.x -= 1.;
    return stmin(cyl(p.xz, 0.1), p1, 0.5, 4.);
}

float prim3(vec3 p)
{
    p.xy = moda(p.xy, 2.*PI/3.);
    p.x -= 4.;
    return prim2(p);
}

float prim4 (vec3 p)
{
    float per = 3.;
    p.xy *= rot(p.z*0.5);
    p.z = mod(p.z-per/2., per)-per/2.;
    return prim3(p);
}

float prim5(vec3 p)
{
    p.xz *= rot(time*tempo);
    p.xy *= rot(time * tempo);
    p *= 1.5;
    return stmin(sphe(p,1.), od(p,1.), 0.5, 4.);
}

float g = 0.;
float SDF(vec3 p)
{
    float d = min(prim4(p), prim5(p));
    g+=0.1/(0.1+d*d); 
    return d;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    vec3 ro = vec3(0.001,0.001,-10.); vec3 p = ro;
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
        p += d*rd * 0.8;
    }

    float t = length(ro-p);

    vec3 pal = palette
        (abs(uv.y),
         vec3(0.5),
         vec3(0.5),
         vec3(0.5),
         vec3(0.5,0.3,0.2));

    vec3 c = vec3(shad) * pal;
    c = mix(c, vec3(0.,0.,0.2), 1.-exp(-0.01*t*t));
    c += g*0.05*(1.-length(uv));
    glFragColor = vec4(pow(c, vec3(0.45)),1.);
}
