#version 420

// original https://www.shadertoy.com/view/3sfXRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot and Alkama for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Cookie Collective rulz

#define ITER 100.
#define PI  3.141592
#define time time

float rand (vec2 st)
{return fract(sin(dot(st, vec2(12.181, 35.154)))*2445.458);}

float stmin (float a, float b, float k , float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b), 0.5 * (u+a+abs(mod(u-a+st, 2.*st)-st)));
}

// iq smooth minimum function: https://www.iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0., max(q.z,max(q.x,q.y))) + length(max(q,0.));
}

float cylH (vec3 p, float r, float h)
{return max(length(p.xy)-r, abs(p.z)-h);}

// iq hexagonal function : https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdHexPrism( vec3 p, vec2 h )
{
    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
    vec2 d = vec2(
        length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
        p.z-h.y );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float od (vec3 p, float d)
{
    p.xz *= rot(time);
    p.yz *= rot(time);
    return dot(p, normalize(sign(p)))-d;
}

float vortex (vec3 p)
{
    p *= 2.;
    p.xz *= rot(p.y + time);
    //p.x += sin(p.y);
    p.y += sin(p.x*0.8 + p.y*1.5+ time);
    p.x += sin(p.y+time*2.);
    return cylH(p.xzy, 5.-p.y*0.6, 8.)/2.;
}

float g1 = 0.;
float ball(vec3 p)
{
    float d = length(p)-1.3;
    g1 += 0.1/(0.1*d*d);
    return d;
}

float water (vec3 p)
{

    p.y -= .5;
    float s = ball (vec3(p.x, p.y-4.+sin(time)*0.5, p.z));
    float v = vortex(p);
    p.y += sin(length(p.xz*2.)-time)*0.1;
    return smin(smin(v, s, 3.), max(sdHexPrism(p.xzy, vec2(4.2, 2.)),abs(p.y)-0.5), 15.);
}

float pillars (vec3 p)
{
    p.x = abs(p.x);
    p.z -= 2.;
    p.x -= 8.8;
    p.y -= 2.;
    return box(p, vec3(0.5+abs(p.y)*0.3, 2., 0.5+abs(p.y)*0.3));
}

float gems (vec3 p)
{
    p.x = abs(p.x);
    p.z -= 2.;
    p.x -= 8.8;
    p.y -= 6.;
    return od(p,.8);
}

float background (vec3 p)
{
    float b = -box(vec3(p.x, p.y-15., p.z+45.), vec3(13.,15., 50));
    float h1 = max(-sdHexPrism(p.xzy, vec2(4.2, 2.)),sdHexPrism(p.xzy, vec2(5., 1.5)));
    return stmin(pillars(p),stmin(h1,b, 1. , 3.),0.5, 3.);
}

int mat = 0;
float SDF (vec3 p)
{
    float g = gems(p);
    float b = background(p);
    float w = water(p);
    float d = min(g,min(b, w));
    // tricks learned during YX stream
    if (d == b) mat = 1;
    if (d == g) mat = 2;
    if (d == w) mat = 3; 
    return d;
}

vec3 get_cam (vec3 ro, vec3 target, vec2  uv, float fov)
{
    vec3 forward = normalize(target-ro);
    vec3 left = normalize(cross(vec3(0.,1.,0.), forward));
    vec3 up = normalize(cross(forward, left));
    return normalize(forward*fov + left*uv.x + up*uv.y);
}

vec3 norms (vec3 p)
{
    vec2 eps = vec2(0.01,0.);
    return normalize(vec3( SDF(p+eps.xyy) - SDF(p-eps.xyy),
                          SDF(p+eps.yxy) - SDF(p-eps.yxy),
                          SDF(p+eps.yyx) - SDF(p-eps.yyx)
                         )
                    );
}

float dir_light(vec3 n, vec3 l)
{return dot(n, normalize(l))*0.5 + 0.5;}

float point_light (vec3 p, vec3 n, vec3 lpos)
{
    vec3 ldir = normalize(lpos-p);
    float att = length(lpos-p);
    float dotNL = dot(n, ldir)*0.5+0.5;
    return dotNL / ((0.1*att*att));
}

float spec_light (vec3 l, vec3 rd, vec3 n, float spec_power)
{
    vec3 h = normalize(l - rd);
    float spe = pow(max(dot(h,n),0.),spec_power);
    return spe;
}

float fresnel (vec3 rd, vec3 n, float fre_power)
{
    return pow(1.-clamp(dot(n, -rd), 0., 1.), fre_power);
}

void back_mat (inout vec3 col, vec3 n, vec3 p ,vec3 rd)
{
    vec3 dir_pos = vec3(-2.,5,5.);
    col = mix(vec3(0.3,0.1,0.2), vec3(0.3,0.6,0.8), dir_light(n, dir_pos));
}

void water_mat(inout vec3 col, vec3 n, vec3 p , vec3 rd)
{
    vec3 point_pos = vec3(0.,5., -5.);
    vec3 light_dir = normalize(vec3(0.,12., 4.));
    col += fresnel (rd, n, 3.)*vec3(0.3,0.1,.2);
    col += spec_light(light_dir, rd, n , 20.);
    col += point_light(p, n, point_pos)*vec3(0.3,0.6,0.8);
}

void gems_mat (inout vec3 col, vec3 n, vec3 p , vec3 rd)
{
    vec3 dir_pos = vec3(0.,3.,-5.);
    col += fresnel (rd, n, 1.5)*vec3(0.3,0.1,0.8);
    col += spec_light(dir_pos, rd, n , 5.);
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    float dither = rand(uv);

    vec3 ro = vec3(-3.,7., -14); vec3 p = ro;
    vec3 target = vec3(0., 2., 0.);
    vec3 rd = get_cam(ro, target, uv, 1.);
    vec3 col = vec3(0.);

    bool hit = false;
    float shad = 0.;
    for(float i = 0.; i<ITER; i++)
    {
        float d = SDF(p);
        if (d<0.01)
        {
            hit = true;
            shad = i/ITER;
            break;
        }
        d *= 0.5 + dither*0.1;
        p += d*rd;
    }

    if (hit)
    {
        vec3 n = norms(p);
        if (mat == 1) back_mat(col, n, p, rd);
        if (mat == 2)
        {
            col = vec3(0.1,0.5,0.3);
            gems_mat(col, n, p, rd);
        } 
        if (mat == 3) 
        {
            col = vec3(0.4);
            water_mat(col, n, p, rd);
        }
    }
    // fake AO
    col *= 1.-shad;
    glFragColor = vec4(pow(col, vec3(1.2)),1.);
}
