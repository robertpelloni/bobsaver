#version 420

// original https://www.shadertoy.com/view/wstXzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot, Alkama and YX for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

#define PI 3.141592
#define ITER 100.

float hash21 (vec2 x)
{return fract(sin(dot(x,vec2(14.4,16.5)))*1245.4);}

mat2 rot(float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float moda (inout vec2 p, float rep)
{
    float per = (2.*PI)/rep;
    float a = atan(p.y, p.x);
    float l = length(p);
    float id = floor(a/per);
    a = mod(a,per)-per*0.5;
    p = vec2(cos(a),sin(a))*l;
    if (abs(id)>= rep*.5) id = abs(id);
    return id;
}

void mo (inout vec2 p, vec2 d)
{
    p = abs(p)-d;
    if (p.y>p.x) p = p.yx;
}

float cyl(vec3 p, float r, float h)
{return max(length(p.xy)-r,abs(p.z)-h);}

float box (vec3 p, vec3 c)
{return length(max(abs(p)-c,0.));}

float stem_id;
float stem (vec3 p)
{
    p.xz *= rot(p.y-time);
    stem_id = moda(p.xz, 5.);
    p.x -= (p.y >= 0.) ? 0.15+p.y*0.2 : 0.15;
    return cyl(p.xzy, 0.1-p.y*0.02, 4.);
}

float spi (vec3 p)
{
    p.y -= p.x*p.x*0.2;
    p.x -= 1.;
    return cyl(p.yzx, 0.05-p.x*0.1, 1.);
}

float spikes (vec3 p)
{
    float d = 1e10;
    for (int i=0; i<6;i++)
    {
        float ratio = float(i)/4.;
        p.y += .6;
        p.xz *= rot(PI/3.);
        d = min(d, spi(p));
    }
    return d;
}

float g1 = 0.;
float flower(vec3 p)
{
    p *= 1.5;
    p.y -= 6.;
    mo(p.xy, vec2(0.5));
    mo(p.xz, vec2(.5));
    p.yz *= rot(time);
    p.x -= .8;
    float d = box(p, vec3(.05-sin(p.y-.5),1.,0.05));
    g1 += 0.1/(0.1+d*d);
    return d/1.5;
}

int mat_id;
float SDF(vec3 p)
{
    float g = abs(p.y+4.5+sin(length(p.xz)-time)*0.1)-0.1;
    float sp = spikes(p);
    float f = flower(p);
    float st = stem(p);

    float d = min(min(sp,f),min(st,g));

    if (d == g) mat_id = 1;
    if (d == sp) mat_id = 2;
    if (d == f) mat_id = 3;
    if (d == st) mat_id = 4;

    return d;
}

vec3 getcam (vec3 ro, vec3 ta, vec2 uv)
{
    vec3 f = normalize(ta-ro);
    vec3 l = normalize(cross(vec3(0.,1.,0.),f));
    vec3 u = normalize(cross(f,l)); 
    return normalize(f*0.8 + l*uv.x + u*uv.y);
}

vec3 getnorm (vec3 p)
{
    vec2 eps = vec2(0.01,0.);
    return normalize(SDF(p)-vec3(SDF(p-eps.xyy), SDF(p-eps.yxy), SDF(p-eps.yyx)));
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    float dither = hash21(uv);

    vec3 ro = vec3(2.,5.,-3.2),
        p = ro,
        ta = vec3(-1.8,2.,0.),
        rd = getcam(ro,ta,uv),
        col = vec3(0.);

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
        d *= 0.4 + dither*0.1;
        p += d*rd;
    }

    if (hit)
    {
        vec3 n = getnorm(p);

        if (mat_id == 1)
        {    
            vec3 l_blood = vec3(-2.,5.,-3.);
            vec3 h = normalize(l_blood-rd);
            vec3 albedo = vec3(0.3,0.,0.);        
            vec3 fre = pow(clamp(1.-dot(n,-rd),0.,1.), 4.) * vec3(0.8,0.5,0.7);       
            float spe = pow(max(0.,dot(h,n)),22.);

            col = albedo+fre+spe*3.;
        }

        if (mat_id == 2)
        {
            col = vec3(abs(p.x*2.),0.1,0.0);
        }

        if (mat_id == 3)
        {
            vec3 albedo = vec3(length(p)*0.15,0.1,0.0);

            vec3 l_flower = vec3(0.,2.,-2.);
            vec3 h = normalize(l_flower-rd);
            float spe = pow(max(0.,dot(h,n)),5.);

            col = albedo+spe;
        }

        if (mat_id == 4)
        {
            col = vec3(.8,abs(stem_id)*0.2,abs(stem_id)*0.1);
        } 
        col *= 1.-shad;
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
