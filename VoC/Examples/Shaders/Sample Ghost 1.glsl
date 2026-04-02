#version 420

// original https://www.shadertoy.com/view/tdtXD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot, Alkama and YX for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

#define time time

float BPM = 170./60.;
float PI = acos(-1.);

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

float hash1d (vec2 x)
{return fract(sin(dot(x,vec2(1.45,8.151)))*45485.489);}

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float moda (inout vec2 p, float rep)
{
    float per = 2.*PI/rep;
    float a = atan(p.y,p.x);
    float l = length(p);
    float id = floor(a/per);
    a = mod(a, per) - per*.5;
    p = vec2(cos(a),sin(a))*l;
    if (abs(id) >= rep/2.)id = abs(id);
    return id;
}

float stmin (float a, float b, float k, float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b),0.5*(u+a+abs(mod(u-a+st, 2.*st)-st)));
}

float sphe (vec3 p, float r)
{return length(p)-r;}

float od (vec3 p, float r)
{return dot(p, normalize(sign(p)))-r;}

float cyl (vec3 p, float r, float h)
{return max(length(p.xy)-r, abs(p.z)-h);}

float tunnel (vec3 p)
{
    p.x += texNoise(vec2(p.y, p.z+time*BPM*2.)*0.05).x;
    p.y += texNoise(vec2(p.x, p.z+time*BPM*2.)*0.05).x;
    return -cyl(p.xyz, 8., 1e10);
}

float g2 =0.;
float jellyfish (vec3 p)
{   
    moda (p.xy, 3.);
    p.x -= 4.;
    p.xy *= rot(sin(p.z*0.5+time));
    moda(p.xy, 3.);
    p.x -= 2.;
    p.yz *= rot(PI/2.);
    
    vec3 pp = p;
    p.y -= 2.;
    float o = min(sphe(p,.5),max(-sphe(p,1.2),od (p,0.8)));
    
    p = pp;
    p.xz *= rot(sin(p.y+time));
    moda(p.xz, 8.);
    p.x -= 0.5;
    float c = cyl(p.xzy, 0.1+p.y*0.05, 2.);
    float d = stmin(c, o, 0.5,3.);
    g2 += 0.1/(0.1+d*d);
    return d;
}

float g1 = 0.;
float strings (vec3 p)
{
    p.xy *= rot(p.z*0.3+time);
    moda(p.xy, 5.);
    p.x -= 6.;
    float d = cyl(p, 0.3, 1e10);
    g1 += 0.1/(0.1+d*d);
    return d;
}

float SDF (vec3 p)
{
    float anim = exp(-fract(PI*time*BPM/2.)*6.)*8.;
    p.x += texNoise(p.yz*anim).r*0.5;
    return min(tunnel(p), min(strings(p),jellyfish(p)));
}

void main(void)
{
    vec2 uv = 2.*(gl_FragCoord.xy/resolution.xy)-1.;
    uv.x *= resolution.x/resolution.y;
    
    float dither = hash1d(uv);
    
    vec3 ro = vec3(0.001,0.001,-4.); vec3 p = ro;
    vec3 rd = normalize(vec3(uv,1.));
    vec3 col = vec3(0.);
    
    float shad = 0.;
    bool hit = false;
    
    for (float i=0.; i<100.; i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            shad = i/100.;
            hit = true;
            break;
        }
        d *= 0.9+dither*0.1;
        p += d*rd;
    }
    float t = length(ro-p);    
    if (hit)
    {
        col = vec3(shad);
    }
    col += g2*vec3(0.5,0.3,0.)*0.2;
    col += g1*0.2;

    col = mix(col, vec3(0.,0.,0.08), 1.-exp(-0.005*t*t));
    
    glFragColor = vec4(pow(col, vec3(1.)), 1.);
}
