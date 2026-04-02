#version 420

// original https://www.shadertoy.com/view/4tKSzz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//precision highp float;
#define PI 3.1415926535897932384626433832795

#define float3 vec3
#define float2 vec2
#define float4 vec4
#define float3x3 mat3

const float MAX_RAY_LENGTH=10000.0;

void RP(float3 tp0, float3 dp1, float3 dp2, float3 rp0, float3 rd, out float t, out float3 uv, out float3 n)
{
    float3 dp0=rp0-tp0;

    float3 dett =cross(dp1,dp2);
    float3 detuv=cross(dp0,rd);

    float det=(-1.0)/dot(dett,rd);

    float u=(dot(detuv,dp2))*det;
    float v=(dot(detuv,dp1))*det;
    t=(dot(dett ,dp0))*det;
    if(t<0.0)
    {
        t=MAX_RAY_LENGTH;
        return;
    }
    
    uv=float3(u,v,0.0);
    n=normalize(dett);
}

float arws(float2 p, float t)
{
    float2 p1=float2(p.x+p.y,p.x-p.y);
    float2 f1xy=abs(fract(p1/sqrt(8.0))-0.5)-0.25;
    f1xy=clamp(f1xy*t+0.5,0.0,1.0);
    float f1=mix(f1xy.x,1.0-f1xy.x,f1xy.y);

    float2 fxy=float2(p.x-sqrt(0.125),p.y);
      fxy=abs(fract((fxy*sqrt(2.0)+0.5)/2.0)-0.5)-0.25;
    fxy=clamp(fxy*t/sqrt(2.0)+0.5,0.0,1.0);
    float f=mix(fxy.x,1.0-f1,fxy.y);

    return f;
}

void trace(float3 rp0, float3 rd, out float t, out float3 pos, out float3 n)
{
    float t1=MAX_RAY_LENGTH;
    float3 col1;
    float3 n1;
       RP(float3(0.0,-5.0,0.0),float3(-1.0,0.0,0.0),float3(0.0,0,1.0),rp0, rd, t1, col1, n1);
    pos=rp0+rd*t1;
    t=t1;
}

float value(float3 p)
{
    float mv=mouse.x*resolution.x/resolution.x;
    p.y-=1.0;
    float v=0.0;
    float a=atan(p.x,p.z);
    float a0=a*7.0/3.0+time;
    float a1=a0+PI/3.0*2.0;
    float a2=a0+PI/3.0*2.0*2.0;
    
    float d0=length(float2(p.x,p.z))-3.0;
    float v0=length(float2(d0+sin(a0)*0.5,p.y+cos(a0)*0.5));
    float v1=length(float2(d0+sin(a1)*0.5,p.y+cos(a1)*0.5));
    float v2=length(float2(d0+sin(a2)*0.5,p.y+cos(a2)*0.5));
    v=v0*v1/(v0+v1);
    v=v*v2/(v+v2);
   
    return v-0.05-(sin(a*5.0)+1.0)*0.09;
}

bool raymarch(float3 start, float3 d, float t0, float t1,float stp, float th, out float t)
{
    t=t0;
    
    for(int i=0;i<300;i++)
    {
        float3 p=start+d*t;
        float v=value(p);
        if(v<0.0)
            return true;
        t+=0.0025+v;
    }
    return false;
}

float3 calcN(float3 p)
{
    float3 n;
    float d=0.005;
    float n0=value(p);
    n.x=value(p+float3(d,0.0,0.0))-n0;
    n.y=value(p+float3(0.0,d,0.0))-n0;
    n.z=value(p+float3(0.0,0.0,d))-n0;

    n=normalize(n);
    return n;
}

float nrand( vec2 n )
{
    return fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 43758.5453);
}

void main(void)
{
    float3 campos=float3(-10.0,3.0,0.0);
    float3 look_at=float3(0.0,0.5,0.0);
    float3 up=float3(0,1,0);
    float3 forward;
    float3 right;

    float3 light=float3(0,10,10);

    float T=time*0.45;
    
    light.x=cos(T)*10.0;
    light.z=sin(T)*10.0;
    light.y=5.0;
    
    float mposx=resolution.x;
    float mposy=resolution.y*2/3;

    float a1=(0.6+(mposy/resolution.y-0.5)*0.7)*PI;

    //if(mouse*resolution.xy.y<0.01)
    //    a1=PI*0.75;

    float a2=mposx/resolution.x*PI*2.0-PI/3.0;
    campos.y=cos(a1)*campos.x;
    float camx=sin(a1)*campos.x;
    campos.x=cos(a2)*camx;
    campos.z=sin(a2)*camx;
    light=campos*2.0;
    light.x=0.0;
    light.z=15.0;
    light.y=25.0;
//    campos+=look_at;
    
    forward=normalize(look_at-campos);
    right=normalize(cross(up,forward));
    up=normalize(cross(forward,right));
    
  
    float2 scr = gl_FragCoord.xy /resolution.xy;
    scr=2.0*scr-1.0;

    float2 scr2ray=scr;
    scr2ray.x*=(resolution.x/resolution.y);
    float2 uv=scr2ray;
    float3 ray=normalize(forward+(up*uv.y+right*uv.x)*0.5);

    float3 col=float3(0.0,0.5,0.0);
    float3 n;
    float t;
    glFragColor.rgb=float3(0.5,0.3,0.1);
    float3 fogcol=mix(float3(0.87,0.8,0.83),float3(0.3,0.6,1.0),1.0-(1.0-ray.y)*(1.0-ray.y));
       glFragColor.rgb=fogcol;
    float3 tpos;
    trace(campos, ray, t, tpos, n);
    col=mix(float3(0.87,0.85,0.83),float3(0.1,0.15,0.4),
                smoothstep(0.0,1.0,arws(tpos.xz*0.2,16000.0/t/t)));

    if(t<MAX_RAY_LENGTH)
    {
        
        col=mix(fogcol,col,exp(-t*0.01));
        glFragColor.rgb=col;
    }
    {
        float t1;
        float3 start=campos;
        if(raymarch(start,ray,2.5-nrand(scr),11.0,0.0,8.5,t1))
        {
            if(t1<t)
            {
                float3 p=start+ray*t1;
                float3 n=calcN(p);
                float3 tolight=normalize(light-p);
                float3 halfn=normalize(tolight-ray);
                
                float lamb=pow(clamp(dot(n,tolight),0.0,1.0),1.5)*0.8+0.2;
                float3 refray=reflect(ray,n);

                float spec1=clamp(dot(halfn,n),0.0,1.0);
                float spec2=clamp(dot(tolight,refray),0.0,1.0);

                float3 reffog=mix(float3(0.87,0.8,0.83),float3(0.3,0.6,1.0),1.0-(1.0-refray.y)*(1.0-refray.y));

                float3 n1;
                col=lamb*float3(0.8,0.81,0.83)*1.3;
                float3 rpos;
                float3 rcol;
                trace(p, reflect(ray,n), t1, rpos, n1);
                if(t1<MAX_RAY_LENGTH)
                {
                    rcol=mix(float3(0.87,0.85,0.83),float3(0.1,0.12,0.4),
                        smoothstep(0.0,1.0,arws(rpos.xz*0.2,2000.0/t1/t1/t1)));
                    rcol=mix(reffog,rcol,exp(-t1*0.02));
                }
                else
                {
                    rcol=reffog;
                }
                {
                    col=mix(col,rcol,pow(clamp(1.0-dot(ray,-n),0.0,1.0),0.8)*0.65+0.4);
                    col*=float3(1.0,0.8,0.5);
                    col=mix(col,float3(1,1.03,1.2),pow(spec1,20.0)*0.8+0.6*pow(spec2,80.0));
                    col*=float3(1.1,0.95,0.65);
//                    col=rcol;
                    
//                    glFragColor.rgb=mix(col,glFragColor.rgb,pow(dot(ray,n),15.0));
                }
//                glFragColor.rgb=0.5+n*0.5;
                glFragColor.rgb=col;
//                glFragColor.rgb=float3(pow(spec2,10.0));
            }
        }
    }
    
    glFragColor.a=1.0;
   
}
