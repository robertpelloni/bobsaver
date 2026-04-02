#version 420

// original https://www.shadertoy.com/view/3llcWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t time + 5.
#define screen(a, b) a + b - a*b
#define s(t, b, g) smoothstep(t+b*t, t-b*t, abs(g-.5) )

//hash functions from https://www.shadertoy.com/view/4djSRW
vec2 hash22(vec2 p)
{
    p *= 733.424;
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec3 hash33(vec3 p3)
{
    p3 *= 733.424;
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}
    
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p3)
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 voronoi2d(vec2 p, float s, bool m) {
    vec2 gv = fract(p)-.5;
    vec2 iv = floor(p);
    vec2 id;
    
    vec2 o;
    float res = 8.;
    
    for(int y=-1; y<=1; y++)
    for(int x=-1; x<=1; x++)
    {
        o = vec2(x, y);

        vec2 n = hash22(iv+o);
        vec2 p = o+.5*sin(t*n);
        vec2 a = gv-p;
        a = abs(a);
        
        float d;
        if(m)
            d = (a.x+a.y)/s; //manhattan
        else
            d = max(a.x, a.y)/s; //chebychev

        if(hash12(n)>.5 ? d<1. : 1.<res) {
            res = d;
            id = iv+p;
        }
    }
    return vec3(res, id*float(res<1.) );
}

vec4 voronoi3d(vec3 p, float s, bool m) {
    vec3 gv = fract(p)-.5;
    vec3 iv = floor(p);
    vec3 id;
    
    vec3 o;
    float res = 8.;
    
    for(int z=-1; z<=1; z++)
    for(int y=-1; y<=1; y++)
    for(int x=-1; x<=1; x++)
    {
        vec3 o = vec3(x, y, z);

        vec3 n = hash33(iv+o);
        vec3 p = o+.5*sin(t*n);
        vec3 a = gv-p;
        a = abs(a);
        
        float d;
        if(m)
            d = (a.x+a.y+a.z)/s; //manhattan
        else
            d = max(max(a.x, a.y), a.z)/s; //chebychev

        if(hash13(n)>.5 ? d<1. : 1.<res) {
            res = d;
            id = iv+p;
        }
    }
    return vec4(res, id*float(res<1.) );
}

void main(void)
{   
    vec2 R = resolution.xy;
    vec2 uv1 = (gl_FragCoord.xy-.5*R.xy)/R.y;
    vec3 uv2 = vec3(gl_FragCoord.xy/R.xy, R.x/R.y);
    uv1 *= 8.;
    
    float size = 1.;
    bool method = uv2.x<.5;
    
    float v = voronoi2d(uv1, size, method).x;
    
    if(uv2.y>.5)
        v = step(.9, v)*float(v<1.);
    else
        v = voronoi3d(vec3(uv1, 0), size, method).w*.5+.5;
    
    v = screen(v, s(.0025,          .2, uv2.x ) );
    v = screen(v, s(.0025*uv2.z, .2, uv2.y ) );

    glFragColor = vec4(v);
}
