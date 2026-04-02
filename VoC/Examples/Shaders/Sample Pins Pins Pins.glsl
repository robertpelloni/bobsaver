#version 420

// original https://www.shadertoy.com/view/fl3yRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine

// Thanks to wsmind, leon, XT95, lsdlive, lamogui, 
// Coyhot, Alkama,YX, NuSan, slerpy, wwrighter 
// BigWings, FabriceNeyret and Blackle for teaching me

// Thanks LJ for giving me the spark :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  
// https://twitter.com/CookieDemoparty

// Based on this masterpiece 
// by iosounds https://www.instagram.com/p/CR5NXyWjFfZ/?utm_source=ig_web_copy_link

#define PI acos(-1.)
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

#define cyl(p,s,h) max(length(p.xy)-s, abs(p.z)-h)
#define cube(p,c) length(max(abs(p)-c,0.))

#define crep(p,c,l) p-=c*clamp(round(p/c),-l,l)
#define hash21(p) fract(sin(dot(p,vec2(12.5,23.4)))*1257.4)
#define palette(t,c,d) (vec3(.5)+vec3(.5)*cos(2.*PI*(c*t+d)))

float prim1(vec3 p, float sy)
{
   crep(p.xz,0.35,1.);
  return max(-length(p.xz)+.1,cube(p,vec3(0.15,sy,0.15)));  
}

vec2 edge (vec2 p)
{
  vec2 p2 = abs(p);
  if (p2.x>p2.y) return vec2((p.x<0.)?-1.:1.,0.);
  else return vec2(0., (p.y<0.)?-1.:1.);
}

float prims (vec3 p)
{
    vec2 center = floor(p.xz)+.5;
    vec2 neigh = center + edge(p.xz-center);
    float sy = mix(0.2,.5,hash21(center*.1));
    float me = prim1(vec3(p.x-center.x, p.y, p.z-center.y), sy)-0.01;
    vec3 newp = vec3(p.x-neigh.x, p.y, p.z-neigh.y);
    float next = cube(newp, vec3(0.499,.7,0.499));

    return min(me,next);
}

float g1 = 0.; vec2 id;
float cyls( vec3 p)
{
    id = floor(p.xz/.334);
    float h=.5+sin(length(id)-time*3.)*.1;

    float per = .334;

    p.xz = mod(p.xz,per)-per*.5;
    float d = cyl(p.xzy,0.08,h);

    g1 += 0.001/(0.001+d*d);

    return d;
}

float SDF (vec3 p)
{
  p.yz *= rot(-atan(1./sqrt(2.)));
  p.xz *= rot(PI/4.);
  
  return min(prims(p), cyls(p));
}

vec3 getnorm(vec3 p)
{
    vec2 eps = vec2(0.01,0.);
    return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
}
  
void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    float dither = hash21(uv);
    
    vec3 ro = vec3(uv*2.5,-30.), rd=vec3(0.,0.,1.),
    p=ro, col=vec3(.0), l=normalize(vec3(1.,2.,-1.));
    bool hit=false;
    
    for (float i=0.; i<64.;i++)
    {
      float d = SDF(p);
        if (d<0.001)
        {
            hit=true;
            break;
        }
        d *= .9+dither*.1;
        p += d*rd*.9;
    }

    if (hit)
    {
        vec3 n = getnorm(p);
        float light = dot(n,l)*.1+.1;
        col = vec3(light);
    }
    
    col += g1*palette(hash21(id),vec3(.5),vec3(.0,.36,.64))*0.1;
    
    glFragColor = vec4(sqrt(col),1.);
}
