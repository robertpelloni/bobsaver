#version 420

// original https://www.shadertoy.com/view/wlGGRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define BUMP 0

#define PI acos(-1.0)
#define TAU PI*2.0
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

#define opRepLim(p,s,l) p-s*clamp(round(p/s),-l,l);
#define hash(n)fract(sin(n+1234.5)*55555.0)

vec3 randVec(float n)
{
    vec3 v=vec3(1,0,0);
    v.xy*=rot(asin(hash(n)*2.-1.));
    n+=123.0;
    v.xz*=rot((hash(n)*2.-1.)*PI);
    return v;
}

float noise(vec3 p)
{
    vec3 r=vec3(1,99,999);
    vec4 s=dot(floor(p),r)+vec4(0,r.y,r.z,r.y+r.z);
    p=smoothstep(0.,1.,fract(p));
    s=mix(hash(s),hash(s+1.),p.x);
    s.xy=mix(s.xz,s.yw,p.y);
    return mix(s.x,s.y,p.z);
}

float fbm(vec3 p)
{
       float n = 0.0;
    float amp = 0.8;
    for (int i=0; i<4; i++)
    {
        n += noise(p)*amp;
        amp *= 0.5;
    }
    return min(n, 1.0);
}

float deRing(vec3 p)
{
    p.x-=clamp(p.x,-1.0,1.0);
    return length(vec2(length(p.xy)-1.0,p.z))-0.5;
}

float deChain(vec3 p)
{
    float de = 1e9;
    vec3 q;
    q=p;
    q.x=opRepLim(q.x,6.0,8.0);
    de=min(de, deRing(q));
    q=p;
    q.x-=3.0;
    q.x=opRepLim(q.x,6.0,8.0);
    de=min(de, deRing(q.xzy));
#if BUMP
    de+=fbm(p*5.0)*0.01;
#endif
    return de;
}

float map(vec3 p)
{
    float de = 1e9;
    for(float i=0.0; i<10.0; i++)
    {
        vec3 q = p;
        q+=randVec(i*3.22)*10.0-5.0;
        vec3 v = randVec(i+7753.2223);
        vec3 w=normalize(v);
        vec3 u=normalize(cross(w,v.yzx));
        q *= mat3(u,cross(u,w),w);
        de=min(de, deChain(q));
    }    
    return de;
}

vec3 calcNormal(vec3 pos){
  vec2 e = vec2(1,-1) * 0.002;
  return normalize(
    e.xyy*map(pos+e.xyy)+e.yyx*map(pos+e.yyx)+ 
    e.yxy*map(pos+e.yxy)+e.xxx*map(pos+e.xxx)
  );
}

#define quantize(t, a)floor(t*a)/a

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    float s=uv.y;
    float g=quantize(fract(uv.y+time*0.5),30.0);
    uv.x += 0.1*sin(time*8.0+g*10.0)*
        step(hash(floor(time*2.0))*0.4+0.6,hash(g))*
        step(0.95,sin(time*0.5+1.5*sin(time*2.0)));
    vec3 ro=vec3(0,5,-10);
    ro= vec3(cos(time*0.5+0.5*cos(time*.3))*8.0-6.,sin(time*0.8+0.5*sin(time*0.3))+4.0,sin(time*0.3+1.2*sin(time*0.3))*10.);
    ro*=3.5;
    vec3 ta=vec3(3);
    ta.xz*=rot(time);
    ta.xy*=rot(time*0.3);
    vec3 w = normalize(ta-ro),u=normalize(cross(w,vec3(0,1,0))),v=cross(w,u);
    vec3 rd=mat3(u,v,w)*normalize(vec3(uv,2.0));
    vec3 col=vec3(0.12,0.1,0.03)+fbm(vec3(uv,time*0.5)*0.8)*0.3;
    float t=1.0,d;
    for(int i=0;i<96;i++)
    {
        t+=d=map(ro+rd*t);
        if (d<0.001) break;
    }
    if(d<0.001)
    {
        vec3 p=ro+rd*t;
        vec3 nor = calcNormal(p);
        vec3 li = normalize(vec3(1));
        vec3 bg=col;
        col= vec3(1,0.95,0.85);
        col*=exp2(-2.*pow(max(0.0, 1.0-map(p+nor*0.3)/0.3),2.0));
        col*=max(0.,dot(nor,li));
        col*=max(0.0,0.5+nor.y*0.5);
        col+=pow(max(0.0,dot(reflect(normalize(p-ro),nor),li)),20.0);
        col = mix(bg, col, exp(-t*t*0.0003));
    }
    col *= sin(s * 250.0 - time * 5.0) * 0.2 + 0.9;
    glFragColor = vec4(col, 1.0);
}
