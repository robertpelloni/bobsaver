#version 420

// original https://www.shadertoy.com/view/WddSz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DIST 100.0
#define PI 3.1415927

mat2 rot(float x)
{
    float s = sin(x);
    float c = cos(x);
    return mat2(c,-s,s,c);
}

float box(vec3 p, vec3 d)
{
  vec3 q = abs(p) - d;
  return min(max(q.x,max(q.y,q.z)),0.0)+length(max(q,0.0));
}

float sphere(vec3 p, float d)
{
    return length(p)-d;
}

float sphere(vec3 p, float d, vec3 s)
{
    p/=s;
    return sphere(p,d);
}

float capsule(vec3 p, float h, float r)
{
    p.y -= clamp( p.y, 0.0, h );
    return length( p ) - r;
}

vec2 map(vec3 p)
{
    vec3 rp = p;
    rp.x-=10.;
    p.x+=10.;
    vec3 bp = p;
    p.xz*=rot(time);
       bp.xz*=rot(time);
    float w =box(p,vec3(5,.5,5));
    float s = sphere(p,3.);
    w=max(w,-s);
    float yd = 10.;
    float t =cos(time*2.)*yd;    
    float dur = 3.143;
    float tf = (time*2.)/dur;
    float ti = floor(tf);
    float tti = clamp(fract(tf)*1.2,.5,.6)*10.;
    bp.y-=t;
    bp.xz*=rot(-(ti+tti)*PI/4.);
    bp.xy*=rot(-(ti+tti)*PI/4.);
    
    float b = box(bp,vec3(2.5));
    float bs = sphere(bp,3.);
    b=mix(b,bs,1.-abs(t)/yd);
    rp.xz*=rot(-time);
    float b2 = box(rp,vec3(5,.5,5));
    float s2 = sphere(rp,3.);
    float ct = (1.+cos(time*4.))/2.;
    vec3 rrp = rp;
    rrp.xz*=rot((ti+tti)*PI/4.);
    s2=mix(s2,box(rrp,vec3(3)),ct);
    b2=max(b2,-s2);
    rp.y-=3.+abs(t/1.5);
    tti = clamp(fract(tf)*1.2,0.,.1)*10.;
    rp.xz*=rot((ti+tti)*PI/4.);
    
    float b3 = box(rp,vec3(3));
    float m = 0.0;
    float r = min(w,b);
    r=min(r,b2);
    r=min(r,b3);
    if(r==b||r==b3)m=1.;
    return vec2(r,m);
}

vec2 ray(vec3 ro, vec3 rd)
{
    float t = 0., m=0.;
    for(int i=0;i<128;i++)
    {
        vec3 p = ro+rd*t;
        vec2 s = map(p);
        m=s.y;
        if(s.x<0.00001)break;
        t+=s.x;
        if(t>MAX_DIST){t=-1.;break;}
    }
    return vec2(t,m);
}

vec3 normal(vec3 p)
{
    vec2 e = vec2(0.00005,0);
    return normalize(vec3(
        map(p+e.xyy).x-map(p-e.xyy).x,
        map(p+e.yxy).x-map(p-e.yxy).x,
        map(p+e.yyx).x-map(p-e.yyx).x
        ));
}

void main(void)
{
    vec2 f = gl_FragCoord.xy;

    vec2 uv = (2.*f-resolution.xy)/resolution.y;
    
    vec3 ro = vec3(0,10,-30);
    vec3 ta = vec3(0,1,0);
    vec3 cf = normalize(ta-ro);
    vec3 cu = normalize(cross(cf,vec3(0,1,0)));
    vec3 cr = normalize(cross(cu,cf));
    vec3 rd = normalize(uv.x*cu+uv.y*cr+2.*cf);
    
    vec2 r = ray(ro,rd);
    
    vec3 col = vec3(1);
    
    if(r.x>0.)
    {
        vec3 mate = vec3(.5);
        if(r.y>.5)mate=vec3(3.);
        vec3 p = ro+rd*r.x;
        vec3 n = normal(p);
        vec3 sun = normalize(vec3(0.,.5,-.5));
        float dif = clamp(dot(n,sun),0.,1.);
        float sky = clamp(dot(n,vec3(0,1,0)),0.,1.);
        float bou = clamp(dot(n,vec3(0,-1,0)),0.,1.);
        col =mate* vec3(.1,.2,.3)*dif;
        col+=mate*vec3(0.2,.3,.5)*sky;
        col+=bou*.5;
        
    }
    glFragColor.rgb=col;
}
