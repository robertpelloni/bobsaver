#version 420

// original https://www.shadertoy.com/view/tsS3Rt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot and Alkama for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Cookie Collective rulz

#define ITER 100.
#define PI acos(-1.)
#define time time

float random (vec2 st) 
{return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123);}

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a), cos(a));}

vec2 moda (vec2 p, float per)
{
    float a = atan(p.y,p.x);
    float l= length(p);
    a = mod(a-per/2., per)-per/2.;
    return vec2(cos(a),sin(a))*l;
}

void mo (inout vec2 p, vec2 d)
{
  p = abs(p)-d;
  if (p.y > p.x) p.xy = p.yx; 
}

vec3 palette (float t, vec3 a, vec3 b, vec3 c, vec3 d)
{return a+b+cos(2.*PI*(c*t+d));}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float stmin(float a, float b , float k , float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b) , 0.5*(u+a+abs(mod(u-a+st, 2.*st)-st)));
}

float sphe (vec3 p, float r)
{return length(p)-r;}

float box (vec3 p, vec3 c)
{
  vec3 q = abs(p)-c;
  return min(0., max(q.x,max(q.y,q.z))) + length(max(q,0.));
}

float od (vec3 p, float d)
{return dot(p, normalize(sign(p)))-d;}

float cyl (vec3 p, float r, float h)
{return max(length(p.xy)-r,abs(p.z)-h);}

float g1 = 0.;
float globe (vec3 p)
{
    float d = sphe(vec3(p.x, p.y-1.,p.z), 1.);
    g1 += 0.1/(0.1+d*d);
    return d;
}

float prim1 (vec3 p)
{
    float t1 = floor(time);
    float t2 = fract(time);
    t2 = pow(t2, 6.);

    float anim = PI/4.*(t1+t2);

    p.xz*= rot(anim);
    float b = box (p, vec3(1.,0.5,1.));
    float o = od (p, 1.);
    float s = globe(p);

    p.y += 0.7;
    p.xz = moda(p.xz, PI/2.);
    p.x -= 1.5;
    float c = cyl(p.yzx, 0.4-p.x*0.2, 2.);
    return stmin(s,stmin(o,b,0.5, 5.), 0.2, 3.); 
}

float prim2 (vec3 p)
{
    vec3 pp = p;
    p.y += 2.;
    float c = cyl(p.xzy, 0.4, 2.);

    p = pp;
    p.y += 1.5  ;
    p.xz = moda(p.xz, 2.*PI/5.);
    p.x -= 5.;
    p.y += sin(p.x-time)*0.3;

    float d = min(c,cyl (p.yzx, 0.1-p.x*0.1, 5.));
    return d;
}

float prim3 (vec3 p)
{
    float p1 = prim1(p);
    float p2 = prim2(p);
    return min(p1,p2);
}

float g2 = 0.;
float heart (vec3 p)
{
    float d = sphe(p, 0.8-sin(time)*0.5+0.5);
    g2 += 0.1/(0.1+d*d);
    return d;
}

float id = 0.;
float prim4 (vec3 p)
{
    p.x -= 15.*(floor(time*0.4) + smoothstep(0.,1.,smoothstep(0.1,0.3,fract(time*0.4))));
    float per = 15.;
    id = floor((p.x-per/2.)/per);
    p.x = mod(p.x-per/2., per)-per/2.;
    p.xz *= rot(PI/2.);
    vec3 pp = p;
    p.xz *= rot(time*0.6);
    float s = min(heart(p),max(-od(p, 1.7),sphe(p, 2.)));
    p = pp;
    p.yz = moda(p.yz, 2.*PI/3.);
    p.y -= 5.;
    return smin(s,prim3(p), 0.5);
}

float g3 = 0.;
float od_frame(vec3 p)
{
    float o = od (p, 1.);
    g3 += 0.1/(0.1+o*o);
    return o;
}

float frame (vec3 p)
{
    float per = 5.;

    mo(p.xy, vec2(10., 7.));
    p.x += sin(p.y*0.1);
    p.y += sin(p.x*2.);
    vec3 pp = p;
    p.y = mod(p.y, per)-per/2.;
    float o = od_frame(p);

    p = pp;
    p.xz *= rot(time);
    p.xz *= rot(p.y*0.7);
    p.xz = moda(p.xz, 2.*PI/5.);
    p.x -= 0.6;
    float c = cyl(p.xzy, 0.2, 1e9);
    return smin(o,c, 0.2);
}

float SDF (vec3 p)
{
    float f = frame(p);
    if (abs(p.x) < 10. && abs(p.y) < 7.) return min(f,prim4(vec3(p.x, p.y+0.3 , p.z-5.)));
    else return f;
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    float dither = random(uv);

    vec3 ro = vec3(0.01,0.01, -19.); vec3 p = ro;
    vec3 rd = normalize(vec3(uv,1.));

    float shad = 0.;

    for (float i=0.; i<ITER; i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            shad = i/ITER;
            break;
        }
        d*= 0.7 + dither*0.1;
        p+=d*rd;
    }

    vec3 pal = palette(id,
                       vec3(0.5),
                       vec3(0.5),
                       vec3(0.1+fract(id*3.)/3.),
                       vec3(0.,0.3,0.7));

    vec3 col = vec3(shad);
    col += g1 * vec3(0.5,0.2,0.1)*0.2;
    col += g2 *pal*0.03;
    col += g3 * vec3(0.1,0.5,0.5)*0.06;
    glFragColor = vec4(col, 1.);
}
