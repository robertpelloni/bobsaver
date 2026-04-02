#version 420

// original https://www.shadertoy.com/view/stsGzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100.

mat2 rot(float a)
{
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

#define rep(p,s) (fract(p/s-0.5)-0.5)*s

float sphere(vec3 p, float r)
{
    return length(p) - r;
}

float box(vec3 p, vec3 s)
{
    p = abs(p) - s;
    return max(p.x, max(p.y, p.z));
}

float smin(float a, float b, float h)
{
    float k = clamp((a-b)/ h * .5 + .5, 0., 1.);
    return mix(a,b,k) - k * (1.-k) * h;
}

vec3 smin(vec3 a, vec3 b, float h)
{
    vec3 k = clamp((a-b)/ h * .5 + .5, 0., 1.);
    return mix(a,b,k) - k * (1.-k) * h;
}

vec3 tunnel(vec3 p)
{
    vec3 off = vec3(0);
    float dd = p.z * 0.02;
    dd = floor(dd) + smoothstep(0., 1., smoothstep(0., 1., fract(dd)));
    dd *= 1.7;
    off.x += sin(dd) * 10.;
    off.y += sin(dd * 0.7) * 10.;

    return off;
}

vec3 kif(vec3 p, float t)
{
  float d;
  float s = 10.;
  for(int i = 0; i < 5; ++i)
  {
    p.xy *= rot(t);
    p.xz *= rot(t*.7);
    p = smin(p, -p, -1.);
    p -= s;
    
    //p -= s + sin(t - length(p));
    s *= 0.4;
  }
  
  return p;
}

float at = 0.;
float atsph = 0.;
float atbsph = 0.;
float map(vec3 p)
{
    
    vec3 p1 = p;
    vec3 p2 = rep(p, 100.);
    
    p1 = kif(p2, time * 0.1);
    p1.xy *= rot(time * 0.3);
    p1.xz *= rot(time * 0.7);
    float d1 = box(p1, vec3(0.01));
    float d2 = sphere(p2, 10.5);
    float d3 = sphere(p2, .8);
    float d4 = sphere(p2, 3.);
    
    float d = max(d1, d2);

    at += 0.1 / (0.01 + abs(d2));
    atsph += 0.1 / (0.0 + abs(d3));
    d3 = min(d3, d4);
    atbsph += 0.3 / (0.01 + abs(d4));
    d = min(d, d3);

    return d;
}

void cam(inout vec3 p)
{
    float t = time * 0.05;
    p.xy *= rot(t);
    p.xz *= rot(t * 0.7);
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1.);

    vec3 s = vec3(0, 0, -50);
    vec3 r = vec3(uv, 1);
    //s -= tunnel(s);

    cam(s);
    cam(r);

    s.z += time * 10.;
    s.x += sin(time / 16.) * 25.;

    vec3 p = s;
    float d = 0.;

    float i = 0.;
    float dd = 0.;
    vec3 off = vec3(0.1, 0, 0);
    for(i = 0.; i < MAX_STEPS; i++)
    {
        d = map(p);
        dd += d;
        d *= 0.4;
        //vec3 n = normalize(map(p) - vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
        if(d < 0.001)
        {
            d = 0.1;
        }
        p += r*d;
    }
    
    atsph *= 50.;
    
    vec3 col = vec3(0);
    //col += vec3(pow(1.-i/(MAX_STEPS + 1.), 3.)) * 1.;
    col += pow(at * 0.016, 6.) * vec3(0.5,0,0.5);
    col += pow(atsph * 0.016, 3.) * vec3(1,0,0);
    col += pow(atbsph * 0.2, sin(time * 2.)*.1+1.1) * vec3(0,1.,0.);

    //float dist = length(p-s);
    //col -= 1. / dist;
    

    glFragColor = vec4(col, 1.);
}
