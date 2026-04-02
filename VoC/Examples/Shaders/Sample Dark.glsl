#version 420

// original https://www.shadertoy.com/view/WsdSzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DIST 100.
#define PI 3.1415927

mat2 rot(float v)
{
    float s= sin(v);
    float c = cos(v);
    return mat2(c,-s,s,c);
}

vec3 cam(vec3 ro, vec3 ta, vec2 uv)
{
    vec3 cf = normalize(ta-ro);
    vec3 cu = normalize(cross(cf,vec3(0,1,0)));
    vec3 cr = normalize(cross(cu,cf));
    return normalize(uv.x*cu+uv.y*cr+2.*cf);
}

float g;
float map(vec3 p)
{
    float r=0.;
    float d = 1.3;
    vec3 lp=p+vec3(cos(time*1.5)*d,sin(time)*d,-3. + cos(time)*7.);
    float s = length(lp)-.1;
    g+=0.01/(0.01+s*s);
    float hw = 3.;
    float hh = 3.+cos(time);
    p.xy*=rot(mod(time,PI)+p.z/20.);
    float f = p.y+hh;
    float rw = dot(p+vec3(hw,0,0),normalize(vec3(1,0,0)));
    float lw = dot(p-vec3(hw,0,0),normalize(vec3(-1,0,0)));
    float tw = dot(p-vec3(0,hh,0),normalize(vec3(0,-1,0)));
    
    r=min(s,f);
    r=min(r,rw);
    r=min(r,lw);
    r=min(r,tw);
    
    return r;
}

float ray(vec3 ro, vec3 rd)
{
    float t=0.;
    for(int i=0;i<128;i++)
    {
        vec3 p = ro+rd*t;
        float s = map(p);
        if(s<0.000001)break;
        t+=s;
        if(t>MAX_DIST){t=-1.;break;}
    }
    
    return t;
}

vec3 normal(vec3 p)
{
    vec2 e = vec2(0.00005,0.);
    return normalize(vec3(
        map(p+e.xyy)-map(p-e.xyy),
        map(p+e.yxy)-map(p-e.yxy),
        map(p+e.yyx)-map(p-e.yyx)
        ));
}

void main(void)
{
    vec2 f = gl_FragCoord.xy;    
    vec2 uv = (2.*f-resolution.xy)/resolution.y;
    
    vec3 ro = vec3(0,0,-10);
    vec3 ta = vec3(0);
    vec3 rd = cam(ro,ta,uv);
    
    float r = ray(ro,rd);
    vec3 col = vec3(0);
    
    if(r>0.)
    {
        vec3 p = ro+rd*r;
        vec3 n = normal(p);
        vec3 sun = normalize(vec3(0,0,.1));
        float dif = clamp(dot(sun,n),0.,1.);
        col=vec3(0.5)*dif;
    }
    
    glFragColor.rgb=col+g/3.;
}
