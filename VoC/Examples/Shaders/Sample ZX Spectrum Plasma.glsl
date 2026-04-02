#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3t2GDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define float3 vec3
#define float2 vec2
#define float4 vec4

#define pal(c) vec3(c/4&1,c/2&1,c&1)*( c<8 ? .66 : 1.)

struct NC
{
    int i0;
    int i1;
    int w;
};

NC near(float3 col)
{
    const float3 W=float3(0.299,0.587,0.114);
    NC res;
    float rv=100.0;
    float luma0=dot(col,W);
    for(int i=0;i<15;i++)
    {
        for(int j=i+1;j<16;j++)
        {
            for(int f=0;f<4;f++)
            {
                float3 icol=mix(pal(i),pal(j),float(f)*.25);
                float3 dist=(col-icol);
                dist*=W;

                float d=length(dist);
                if(d<rv)
                {
                    res=NC(i,j,f);
                    rv=d;
                }
            }
        }
    }
    return res;
}

vec3 col(int x, int y)
{
    float time=time;
    vec2 uv = vec2(float(x), float(y))/160.0;
    vec2 uv0=uv;
    float i0=1.1;
    float i1=0.9;
    float i2=0.5;
    float i3=0.6;
    float i4=0.0;
    float r=0.0;
    float g=0.0;
    float b=0.0;
    float w=0.0;
    for(int s=0;s<4;s++)
    {
        vec2 d;
        d=vec2(cos(uv.y*i0-i4+time/i1),-sin(uv.x*i0-i4+time/i1))/i3;
        d+=vec2(-d.y,d.x)*0.7;
        uv.xy+=d;
        
        i0=(i0-0.2)*1.1;
        i1=(i1-2.0)*1.05;
        i2=(i2-1.51)*1.06;
        i3*=0.8237;
        i4+=0.05;
        r+=(sin(uv.x-time)*0.75+0.5)/i2;
        b+=(sin(uv.y+time)*0.75+0.5)/i2;
        g+=(sin((uv.x+uv.y+sin(time*0.5))*0.5)*0.75+0.5)/i2;
        w+=1.0/i2;
    }
    r/=w;
    g/=w;
    b/=w;
    return vec3(r,g,b);
}

float4 border(int y)
{
    return float4(pal(int(float(y)+time*90.+sin(time))/12%8),1);
}

float dp(float i)
{ 
    i=floor(i);
    return i*2.0-floor(i/2.0)-floor(i/3.0)*4.0;
}

float fmod(float x, float m)
{
    return fract(x/m)*m;
}

float dith(float2 xy)
{
    float x=floor(xy.x);
    float y=floor(xy.y);
    float v=0.0;
    float sz=16.0;
    float mul=1.0;
    for(int i=0;i<5;i++)
    {
            v+=dp(
                fmod(fmod(x/sz,2.0)+2.0*fmod(y/sz,2.0),4.0)
            )*mul;
        sz/=2.0;
        mul*=4.0;
    }
    return float(v)/float(mul-1.0);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy)/resolution.xy;

    int ix;
    int iy;
    
    int sc=int(resolution.y/192.);
    
    ix=int(gl_FragCoord.x)/sc;
    iy=int(gl_FragCoord.y)/sc;
    
    int bx=int(resolution.x)/sc-256;
    int by=int(resolution.y)/sc-192;
    
    if((ix<=bx/2)||(ix>=256+bx/2))
    {
        glFragColor=border(iy);
        return;
    }
    else
        ix-=bx/2;

    if((iy<=by/2)||(iy>=192+by/2))
    {
        glFragColor=border(iy);
        return;
    }
    else
        iy-=by/2;
    
    int x0=(ix/8)*8;
    int y0=(iy/8)*8;

    int fx=ix-x0;
    int fy=iy-y0;

    NC nc=near(col(x0+4, y0+4));
    //if(mouse*resolution.xy.z>0.)
    //{        
    //    float3 c=col(ix, iy);
    //    glFragColor = vec4(c,1.0);
    //}
    //else
    //{
        glFragColor = vec4(pal(nc.i0),1.0);
        switch(nc.w)
        {
            case 1:if((fx%2+fy%2)==2)glFragColor = vec4(pal(nc.i1),1.0);break;
            case 2:if((fx+fy)%2==0)glFragColor = vec4(pal(nc.i1),1.0);break;
            case 3:if((fx%2+fy%2)<2)glFragColor = vec4(pal(nc.i1),1.0);break;
        }
    //}
}
