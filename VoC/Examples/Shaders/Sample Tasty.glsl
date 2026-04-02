#version 420

// original https://www.shadertoy.com/view/tscSR2

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

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

void moda (inout vec2 p, float rep)
{
    float per = (2.*PI)/rep;
    float a = atan(p.y,p.x);
    float l = length(p);
    a = mod(a,per)-per*0.5;
    p = vec2(cos(a),sin(a))*l;
}

float cyl (vec3 p, float r, float h)
{return max(length(p.xy)-r,abs(p.z)-h);}

float pour (vec3 p, float rythm, float width)
{
    p.xz *= rot(sin(-p.y*rythm+time));
    moda(p.xz, 3.);
    p.x -= width;
    return cyl(p.xzy, width*0.5, 1e10);
}

float SDF (vec3 p)
{
    p.xz *= rot(p.y*0.5+time);
    float ry = 0.5,wi = 0.5;
    float d = pour(p, ry, wi);
    for (int i=-2; i<=2; i+=2)
    {
        ry += 0.2;
        wi -= 0.1;
        for (int j=-2; j<=2; j+=2)
        {
            vec3 offset = vec3(float(i),0.,float(j));
            d = smin(d, pour(p+offset, ry, wi), 2.);
        }
    }
    return d;
}

vec3 getnorm (vec3 p)
{
    vec2 eps = vec2(0.01,0.);
    return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
}

float lighting (vec3 n, vec3 l)
{return dot(n, normalize(l))*0.5+0.5;}

// courtesy of Alkama
vec3 pales (vec2 uv)
{
  uv *= rot(-time*.2);
  return floor(smoothstep(0.1, 0.2,cos(atan(uv.y, uv.x)*5.)))*vec3(0.4);
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 ro = vec3(0.001,0.001,-7.),
        p = ro,
        rd = normalize(vec3(uv,1.)),
        l = vec3(0.,5.,-2.),
        col = mix(vec3(0.),
                  mix(vec3(0.3,0.25,0.15), vec3(0.8,0.7,0.4), pales(uv)),
                  smoothstep(0.35,1.,abs(uv.x)));
    
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
        p += d*rd*0.5;
    }
    float t = length(ro-p);
    if (hit)
    {
        vec3 n = getnorm(p);
        col = mix(vec3(0.01,0.005,0.005), vec3(0.05,0.01,0.01), lighting(n,l));
        col += vec3(0.,0.02,0.05)*(1.-pow(clamp(dot(n,-rd),0.,1.),.2));
        vec3 h = normalize(l-rd);
        col += pow(max(dot(h,n) ,0.), 25.)*vec3(0.2,0.25,0.25);
        col *= vec3(1.-shad);
    }
    // Output to screen
    glFragColor = vec4(pow(col,vec3(0.4545)),1.0);
}
