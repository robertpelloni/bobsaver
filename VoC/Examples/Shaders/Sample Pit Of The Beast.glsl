#version 420

// original https://www.shadertoy.com/view/ttXGD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot, Alkama and YX for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Cookie Collective rulz

#define time time

vec2 hr = vec2(1., sqrt(3.));
float detail = 5.;
float ITER = 100.;
float PI = 3.141593;

float rand (vec2 st)
{return fract(sin(dot(vec2(2.45,3.45), st))*11.44);}

float stmin (float a, float b, float k, float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b), 0.5*(u+a+abs(mod(u-a+st,2.*st)-st)));
}

mat2 rot(float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

void moda(inout vec2 p, float rep)
{
    float per = 2.*PI/rep;
    float a = atan(p.y,p.x);
    float l = length(p);
    a = mod(a-per*0.5, per)-per*0.5;
    p = vec2(cos(a),sin(a))*l;
}

vec4 hg (vec2 uv)
{
    uv *= detail;

    vec2 ga = mod(uv, hr)-hr*0.5;
    vec2 gb = mod(uv - hr*0.5, hr)-hr*0.5;
    vec2 guv = dot(ga,ga) < dot(gb,gb) ? ga : gb;

    vec2 gid = uv-guv;

    vec2 uu = abs(guv);
    guv.y = .5 - max(uu.x, dot(uu, normalize(hr)));

    return vec4(guv,gid);
}

vec2 hid;
float dm (vec2 uv)
{
    vec4 hxs = hg(uv);
    hid = hxs.zw;
    return smoothstep(0.05,0.06-sin(time)*0.1+0.1,hxs.y) * sin(length(hid)-time);
}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z))) + length(max(q,0.));
}

float cyl (vec3 p, float r, float h)
{ return max(length(p.xy)-r, abs(p.z)-h); }   

float od (vec3 p, float d)
{return dot(p, normalize(sign(p)))-d;}

float room (vec3 p)
{
    p.y -=3.5;
    float b = -box(p, vec3(10.,4.,10.));

    float c = 1e10;
    float aoffset = 0.;
    float offset = 0.;
    for (int i=0; i<3; i++)
    {
        p.xz *= rot(PI/(4.+aoffset));
        moda(p.xz, 5.);
        p.x -= 2.+offset;
        c = min(c, cyl(p.xzy, 0.25, 10.));

        aoffset += 2.;
        offset ++;
    }

    return stmin(b, c, 0.3, 4.);
}

float pit (vec3 p)
{
    float c = cyl(p.xzy, 2.,5.);
    return max(abs(c)-0.14, p.y-.7);
}

float g1 = 0.;
float water (vec3 p)
{
    vec3 pp = p;
    p.y += .3;
    p.y += dm(p.xz)*0.07;
    float d = max(abs(p.y)-.8,cyl(pp.xzy, 2.,5.));  
    g1 += 0.01/(0.01+d*d);
    return d;
} 

float g2 = 0.;
float monster (vec3 p)
{
    vec3 pp = p;
    p.y -= .8+sin(time)*0.1;
    float o = od(p, 0.3);

    p = pp;
    p.xz*=rot(sin(p.y-time));
    moda(p.xz, 6.);
    p.x -= 1.;
    float c = cyl(p.xzy, 0.3-p.y*0.1, 5.);

    float d =  min(c,o);
    g2 += 0.01/(0.01+d*d);
    return d;
}

float SDF (vec3 p)
{
    float m = monster(p);
    float r = room(p);
    float w = water(p);
    float well = pit(p);
    float d = min(m,min(stmin(r, well, .5, 5.),w));

    return d;
}

vec3 getnormal(vec3 p)
{
    vec2 eps = vec2(0.01,0.);
    //return normalize(SDF(p)-vec3(SDF(p-eps.xyy), SDF(p-eps.yxy),SDF(p-eps.yyx)));
    return normalize(vec3(SDF(p+eps.xyy)-SDF(p-eps.xyy),
                          SDF(p+eps.yxy)-SDF(p-eps.yxy),
                          SDF(p+eps.yyx)-SDF(p-eps.yyx)
                         )
                    );
}

float dir_lighting (vec3 n, vec3 l)
{return dot(n, normalize(l)) * 0.5 + 0.5;}

vec3 getcam (vec3 ro, vec3 tar, vec2 uv)
{
    vec3 f = normalize(tar-ro);
    vec3 l = normalize(cross(vec3(0.,1.,0.),f));
    vec3 u = cross(f,l);
    return normalize(f + l*uv.x + u*uv.y);
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);
    
    vec3 col = vec3(0.);
    vec3 ro = vec3(4.*cos(time*0.5),2.5,-4.*sin(-time*0.5)); vec3 p = ro;
    vec3 rd = normalize(vec3(uv,1.));
    rd = getcam(ro, vec3(0.,0.5,0.), uv);
    float shad = 0.;
    bool hit = false;

    for (float i=0.; i<ITER; i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            hit = true;
            shad = i/ITER;
            break;
        }     
        p += d*rd*0.8;
    }
    float t = length(ro-p);
    if (hit)
    {
        vec3 l = vec3(8., 1., 3.);
        vec3 n = getnormal(p);
        col = mix(vec3(0.3,0.,0.2), vec3(0.5,0.7,0.8), dir_lighting(n, l));

        col += vec3(rand(hid),0.3,1.)*g1*0.3;
        col -= g2*0.2;
    }

    else col = vec3(0.);

    col = mix(col, vec3(0.1,0.15,0.2), 1.-exp(-0.04*t*t));
    glFragColor = vec4(col, 1.);
}
