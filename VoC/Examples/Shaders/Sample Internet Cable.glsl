#version 420

// original https://www.shadertoy.com/view/3djczc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot, Alkama and YX for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

#define dt (time*0.35)
#define hr vec2(1., sqrt(3.))
#define PI 3.141592
#define TAU (2.*PI)

float hash21 (vec2 x)
{return fract(sin(dot(x,vec2(32.5,36.4)))*12458.5);}

float moda (inout vec2 p, float rep)
{
    float per = TAU/rep;
    float a = atan(p.y,p.x);
    float l = length(p);
    float id = floor(a/per);
    a = mod(a,per)-per*0.5;
    p = vec2(cos(a),sin(a))*l;
    if (id > rep*0.5) id = abs(id);
    return id;  
}

float stmin(float a, float b, float k, float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b), 0.5*(u+a+abs(mod(u-a+st,2.*st)-st)));
}

vec4 hgrid (vec2 uv, float detail)
{
    uv *= detail;
    vec2 ga = mod(uv,hr)-hr*0.5;
    vec2 gb = mod(uv-hr*0.5,hr)-hr*0.5;
    vec2 guv = (dot(ga,ga)<dot(gb,gb))? ga:gb;
    vec2 gid = uv - guv;
    guv.y = max(abs(guv.x),dot(abs(guv),normalize(hr)));
    return vec4(guv,gid);
}

mat2 rot( float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float tore (vec3 p, vec2 t)
{return length(vec2(length(p.xz)-t.x,p.y))-t.y;}

float g1 = 0.;
float lumieres (vec3 p)
{
    p.xz *= rot(time);
    float lid = moda(p.xz, 8.);
    p.x -= 5.;
    p.xy *= rot(sin(time)*lid*2.);
    moda(p.xy, 5.);
    p.x -= 1.9;
    float d =  length(p)-0.2;
    g1 += 0.01/(0.01+d*d);
    return d;
}

float g2 = 0.;
float pieuvre (vec3 p)
{
    p.xz *= rot(dt);
    p.y += cos(p.z+time)*0.6;
    p.x -= 5.5+sin(p.z+time)*0.4;
    float od = stmin(length(p)-0.6,dot(p, normalize(sign(p)))-0.5,0.2,5.);
    p.z += 1.8;
    p.xy *= rot(sin(p.z+time));
    moda(p.xy, 5.);
    p.x -= 0.4;
    float c = max(length(p.xy)-(0.01+p.z*0.1),abs(p.z)-1.5);
    float d = stmin(c,od, 0.2, 5.);
    g2 += 0.001/(0.001+d*d);
    return d;
}

vec3 new_p;
float pieu;
float SDF (vec3 p)
{
    p.xz *= rot(-dt);
    new_p = p;
    pieu = pieuvre(p);
    return min(min(pieu,lumieres(p)),-tore(p,vec2(5.,2.)));
}

float lignes (vec2 uv, float detail)
{
    uv *= detail;
    uv = fract(uv)-0.5;
    return smoothstep(0.1,0.15, abs(uv.y)) * smoothstep(0.2,0.25, abs(uv.x)-0.1);
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    uv.x = mix(abs(uv.x)-0.55,uv.x, clamp(floor(sin(time*PI/4.))+1.,0.,1.));

    float dither = hash21(uv);

    vec3 ro = vec3(1.,0.0,-6.),
        p=ro,
        rd = normalize(vec3(uv+vec2(0.9,-0.1),1.2)),
        col = vec3(0.);

    float shad,d=0.;
    for(float i=0.; i<64.; i++)
    {
        d = SDF(p);
        if (d<0.001)
        {
            shad = i/64.;
            break;
        }
        d *= 0.9+dither*0.1;
        p +=d*rd;
    }
    
    
    float majorAngle = atan(new_p.z,new_p.x);
    float minorAngle = atan(new_p.y, length(new_p.xz)-5.);
    vec2 tuv = vec2(majorAngle*PI,minorAngle);
    vec4 hg = hgrid(tuv,3.);
    
    float mask = smoothstep(0.1,0.12,abs((sin(length(vec2(minorAngle))-time))-1.));
    vec3 hcol = vec3(smoothstep(0.3,0.43+sin(length(hg.zw)-time),hg.y));
    vec3 lcol =  vec3(0.,0.8,0.)*(1.-lignes(vec2(majorAngle, minorAngle), 5.));
    
    if (d == pieu) col = vec3(shad);
    else col = mix(lcol, hcol, mask);
    
    col *= vec3(1.-shad); 
    col += g1*vec3(0.1,0.8,0.3);
    col += g2*vec3(0.7,0.1,0.2);

    glFragColor = vec4(col,1.);
}
