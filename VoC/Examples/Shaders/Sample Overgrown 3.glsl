#version 420

// original https://www.shadertoy.com/view/WdcXRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot, Alkama and YX for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

#define ITER 64.
#define PI 3.141592

// taken from YX here : https://www.shadertoy.com/view/tdlXW4
// rough shadertoy approximation of the bonzomatic noise texture
vec4 texNoise(vec2 uv)
{
    float f = 0.;
    //f += texture(iChannel0, uv*.125).r*.5;
    //f += texture(iChannel0, uv*.25).r*.25;
    //f += texture(iChannel0, uv*.5).r*.125;
    //f += texture(iChannel0, uv*1.).r*.125;
    f=pow(f,1.2);
    return vec4(f*.45+.05);
}

float hash11 (float x)
{return fract(sin(x)*124.5);}

float stmin(float a, float b, float k, float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b),0.5*(u+a+abs(mod(u-a+st,2.*st)-st)));
}

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float moda (inout vec2 p, float rep)
{
    float per = 2.*PI/rep;
    float a = atan(p.y,p.x);
    float l = length(p);
    float id = floor(a/per);
    a = mod(a,per)-per*0.5;
    p = vec2(cos(a),sin(a))*l;
    if (abs(id)>= rep/2.) id = abs(id);
    return id;
}

float cyl (vec2 p, float r)
{return length(p)-r;}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z))) + length(max(q,0.));
}

float leaf (vec3 p)
{
    p.xz *= rot(PI);
    p.y += sin((p.x+3.5)*1.5)*0.5;
    return box(p, vec3(1.5,0.01+p.x*0.02,0.28+sin(p.x*2.)*0.3));
}

float vine (vec3 p)
{
    float c = cyl(p.xz,0.5);
   
    p.y = mod(p.y, 3.)-3.*0.5;
    moda(p.xz, 3.);
    p.x -= 2.;
    
    return stmin(c,leaf(p),0.3, 3.);
}

float s_id;
float sprout (vec3 p)
{
    p.xz *= rot(time*0.2);
    p.xz *= rot(p.y*0.5);
    s_id = moda(p.xz, 7.);
    p.x -= .8+sin(p.y+time)*0.3;
    return vine(p);
}

float SDF (vec3 p)
{
    p.y += time*0.5; 
    return sprout(p);
}

vec3 getnorm (vec3 p)
{
    vec2 eps = vec2(0.01, 0.);
    return normalize(SDF(p)- vec3(SDF(p-eps.xyy), SDF(p-eps.yxy), SDF(p-eps.yyx)));
}

float dir_light (vec3 n, vec3 l)
{return dot(n, normalize(l))*0.5+0.5;}

vec3 getcam (vec3 ro, vec3 tar, vec2 uv)
{
    vec3 f = normalize(tar-ro);
    vec3 l = normalize(cross(vec3(0.,1.,0.),f));
    vec3 u = normalize(cross(f,l));
    return normalize(f + l*uv.x + u*uv.y);
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 ro = vec3(0.001,-1.5,-4.),
        p = ro,
        rd = getcam(ro, vec3(0.,0.8,0.), uv),
        l = vec3(2.,0.,.5),
        col = vec3(0.,0.3-uv.y*0.2,0.5);
    
    bool hit = false;
    float shad = 0.;
    
    for (float i=0.; i<ITER; i++)
    {
        float d = SDF(p);
        if (d<0.01)
        {
            hit = true;
            shad = i/ITER;
            break;
        }
        
        p+=d*rd*0.5;
    }
    
    float t = length(ro-p);
    
       if (hit)
    {
        vec3 n = getnorm(p);
        vec3 v_col = vec3(hash11(s_id)*0.8,1.,hash11(s_id+0.5));
        col = mix(vec3(0.,0.1,0.3), v_col, dir_light(n,l));
        col *= 1.-shad;
    }
       vec3 back_col = mix(vec3(0.,0.3-uv.y*0.2,0.5), 
                        vec3(0.8,0.8,0.9), 
                        texNoise(uv*0.03+vec2(0.,time*0.004)).g*0.8);
    col = mix(col,back_col, 1.-exp(-0.03*t*t));
    
    // vignetting (from iq)
    vec2 q = gl_FragCoord.xy / resolution.xy;
    col *= .5 + 0.5 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), 0.7);
    
    // Output to screen
    glFragColor = vec4(sqrt(col),1.0);
}
