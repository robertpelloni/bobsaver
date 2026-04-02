#version 420

// original https://www.shadertoy.com/view/3lG3Dc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Isosurface Heart" by klk. https://shadertoy.com/view/XtVSRh

// Many Thanks to IQ for wonderful idea of signed distance field!

#define PI 3.1415926535897932384626433832795

#define float3 vec3
#define float2 vec2
#define float4 vec4
#define float3x3 mat3

const float MAX_RAY_LENGTH=10000.0;

void RayPlane(float3 tp0, float3 dp1, float3 dp2, float3 rp0, float3 rd, out float t, out float3 uv, out float3 n)
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

float Arrows(float2 p, float t)
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

float Checker(float2 p, float t)
{
    float2 fxy=float2(p.x,p.y);
    fxy=abs(fract((fxy+0.5)/2.0)-0.5)-0.25;
    fxy=clamp(fxy*t+0.5,0.0,1.0);
    float f=mix(fxy.x,1.0-fxy.x,fxy.y);

    return f;
}

float PlaneTexture(float2 p, float t)
{
    return Arrows(p,t);
}

// Trace non-SDF objects
void Trace(float3 rp0, float3 rd, out float t, out float3 pos, out float3 n)
{
    float t1=MAX_RAY_LENGTH;
    float3 col1;
    float3 n1;
    RayPlane(float3(0.0,-10.0,0.0),float3(-1.0,0.0,0.0),float3(0.0,0,1.0),rp0, rd, t1, col1, n1);
    pos=rp0+rd*t1;
    t=t1;
}

// Smooth combine functions from IQ
float smin(float a, float b, float k)
{
    float h=clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h)-k*h*(1.0-h);
}

float smax( float a, float b, float k)
{
    return -smin(-a,-b,k);
}

float smin( float a, float b)
{
    return smin(a,b,0.1);
}

float smax( float a, float b)
{
    return smax(a,b,0.1);
}

float sq(float x){return x*x;}

float Torus(float x, float y, float z, float R, float r)
{
    return sqrt(sq(sqrt(sq(x)+sq(z))-R)+sq(y))-r;
}

float Torus(vec3 p, float R, float r)
{
    return sqrt(sq(sqrt(sq(p.x)+sq(p.z))-R)+sq(p.y))-r;
}

float Lid(float x, float y, float z)
{
    float v=sqrt(sq(x)+sq(y-0.55)+sq(z))-1.4;
    v=smin(v,Torus(y-2.,x,z,.2,.08),.1);
    v=smax(v,-sqrt(sq(x)+sq(y-0.55)+sq(z))+1.3);
    v=smax(v,sqrt(sq(x)+sq(y-2.5)+sq(z))-1.3);

    v=smax(v,-sqrt(sq(x-.25)+sq(z-.35))+0.05,.05);
    v=smin(v,Torus(x,(y-1.45)*.75,z,.72,.065),.2);
    return v;
}

float Nose(float x, float y, float z)
{
    z-=sin((y+0.8)*3.6)*.15;
    
    float v=sqrt(sq(x)+sq(z));
    
    v=abs(v-.3+sin(y*1.6+.5)*0.18)-.05;
    v=smax(v,-y-1.);
    v=smax(v,y-0.85,.075);
    
    return v;
}

float Teapot(float3 p)
{
    float x=p.x;
    float y=p.y;
    float z=p.z;

    float v=0.0;
    v=sqrt(x*x+z*z)-1.2-sin(y*1.5+2.0)*.4;
    v=smax(v,abs(y)-1.,0.3);

    
    float v1=sqrt(x*x*4.+sq(y+z*.1)*1.6+sq(z+1.2))-1.0;
    v1=smax(v1,-sqrt(sq(z+1.2)+sq(y+z*.12+.015)*1.8)+.8,.3);
    
    v=smin(v,Torus(y*1.2+.2+z*.3,x*.75,z+1.25+y*.2,.8,.1),.25);
    v=smin(v,sqrt(sq(x)+sq(y-1.1)+sq(z+1.8))-.05,.32);

    float v3=Nose(x,(y+z)*sqrt(.5)-1.6,(z-y)*sqrt(.5)-1.1);

    v=smin(v,v3,0.2);
    
    v=smax(v,smin(sin(y*1.4+2.0)*0.5+.95-sqrt(x*x+z*z),y+.8, .2));
    v=smax(v,-sqrt(sq(x)+sq(y+.15)+sq(z-1.5))+.12);

    v=smin(v,Torus(x,y-0.95,z,0.9,.075));
    v=smin(v,Torus(x,y+1.05,z,1.15,.05),0.15);
    
    
    float v2=Lid(x,y+.5,z);
    v=min(v,v2);

    return v;
}

float plate0(float3 p)
{
    float v=(length(p.xz)*.8-p.y)/sqrt(1.64);
    v=smin(v,(length(p.xz)*.3-p.y+.7)/sqrt(1.09));
    v=smax(v,-p.y+.8,.1);
    return v;
}

float Plate(float3 p)
{
    float v;
    float vi=plate0(p);
    float vo=plate0(p+float3(0,-.1,0));
    v=smax(vi,-vo);
    v=smax(v,(length(p.xz)*2.+p.y)/sqrt(3.)-3.);
    v=smin(v,Torus(p.x,p.y-.7,p.z,0.8,.025),0.2);
    return v;
}

float Value(float3 p)
{
    float v;
    v=Teapot(p);
    //v=Plate(p);
    return v;
}

struct Ray
{
    vec3 p;
    vec3 d;
};

bool RayMarch(
    const in Ray r, 
    const float startT, const float endT, 
    const float stp, 
    const int N,
    out float t, out float v, out int i)
{
    float t0=startT;
    t=t0;
    v=Value(r.p+r.d*t);

    if(v<0.)
        return true;

    i=0;
    for(int j=0;j<1;j+=0)
    {
        t+=max(v*.85, stp);
        float v1=Value(r.p+r.d*t);
        if(v1<0.)
        {
            // Linear interpolation between two last steps
            t=t0+(t-t0)*v/(v-v1);
            v=Value(r.p+r.d*t);
            return true;
        }
        if(t>endT)
            return false;
        i++;
        if(i>N)
            return false;
        v=v1;
        t0=t;
    }
    return false;
}

float3 CalcNormal(float3 p, float n0)
{
    float3 n;
    float d=0.001;
    n.x=Value(p+float3(d,0.0,0.0))-n0;
    n.y=Value(p+float3(0.0,d,0.0))-n0;
    n.z=Value(p+float3(0.0,0.0,d))-n0;

    n=normalize(n);
    return n;
}

struct Sphere
{
    vec3 p;
    float r;
};

bool RaySphere(in Ray r, in Sphere s, out float t0, out float t1)
{
    float3 l=s.p-r.p;
    float tc=dot(l,r.d);
    if(tc<0.0)
    {
        return false;
    };

    float d2=s.r*s.r+tc*tc-dot(l,l);

    if(d2<0.0)
    {
        return false;
    };

    float thc=sqrt(d2);
    t0=tc-thc;
    t1=tc+thc;
    return true;
}

void main(void)
{
    float3 campos=float3(-12.0,3.0,0.0);
    float3 look_at=float3(0.0,0.5,0.0);
    float3 up=float3(0,1,0);
    float3 forward;
    float3 right;

    float3 light=float3(0,10,10);

    float T=time*0.45;
    
    light.x=cos(T)*10.0;
    light.z=sin(T)*10.0;
    light.y=5.0;
    
    float mposx=mouse.x*resolution.xy.x;
    float mposy=mouse.y*resolution.xy.y;
    //if(mouse*resolution.xy.z<0.0)mposx=-mouse*resolution.xy.z;
    //if(mouse*resolution.xy.w<0.0)mposy=-mouse*resolution.xy.w;
    
    float a1=(0.6+(mposy/resolution.y-0.5)*0.7)*PI;
    float a2=mposx/resolution.x*PI*2.0-PI/3.0;

    if(mouse.y*resolution.xy.y<10.0)
    {
        a1=PI*0.55;
        a2=PI+0.3;
    }

    campos.y=cos(a1)*campos.x;
    float camx=sin(a1)*campos.x;
    campos.x=cos(a2)*camx;
    campos.z=sin(a2)*camx;
    
    forward=normalize(look_at-campos);
    right=normalize(cross(up,forward));
    up=normalize(cross(forward,right));

    float2 scr = gl_FragCoord.xy /resolution.xy;
    scr=2.0*scr-1.0;

    float2 scr2ray=scr;
    scr2ray.x*=(resolution.x/resolution.y);
    float2 uv=scr2ray;
    float3 ray=normalize(forward+(up*uv.y+right*uv.x)*0.2);

    float3 col=float3(0.0,0.5,0.0);
    float3 n;
    float t;

    float3 fogcol=mix(float3(0.87,0.8,0.83),float3(0.3,0.6,1.0),clamp(1.0-(1.0-ray.y)*(1.0-ray.y),0.,1.));
    glFragColor.rgb=fogcol;
    float3 tpos;
    Trace(campos, ray, t, tpos, n);
    col=mix(float3(0.97,0.95,0.83),float3(0.1,0.15,0.4), smoothstep(0.0,1.0,PlaneTexture(tpos.xz*0.2,36000.0/t/t)));
    float3 tolight=normalize(light);

    // Debug visualization of SDF values 
    if(false)
    {
        float t1=MAX_RAY_LENGTH;
        float3 col1;
        float3 colp=vec3(0);
        float3 n1;
        RayPlane(float3(0.,0.,0.),float3(0.0,1.0,0.0),float3(1.0,0,0.0),campos, ray, t1, col1, n1);
        float3 pos=campos+ray*t1;
        if(t1<t)
        {
            t=t1;
            float v=Value(pos);
            colp.r=v>0.?fract(v):0.5;
            colp.b=v<0.?fract(v):0.5;
            colp.g=.5-abs(clamp(fract(v*10.),0.,1.)-0.5);
        }
        col.rgb+=colp.rgb*0.5;
        glFragColor.rgb=col;
    }

    if(t<MAX_RAY_LENGTH)
    {
        col=mix(fogcol,col,exp(-t*0.005));
        glFragColor.rgb=col;
    }

    {
        float ts0, ts1;
        float3 start=campos;
        float n0;
        Sphere bound=Sphere(vec3(.0,.3,.2),2.5);

        // Try bounding sphere first
        bool hit=RaySphere(Ray(start,ray), bound, ts0, ts1);
        //if(hit)glFragColor.rgb*=0.95;
        int nt=-1;

        float tp;

        if(hit)
        {
            hit=RayMarch(Ray(start,ray),ts0,ts1,.025,180,tp,n0,nt);
        }

        if(hit)
        {
            if(tp<t)
            {
                t=tp;
                float3 p=start+ray*tp;
                float3 n=CalcNormal(p,n0);
                if(nt<0)
                {
                    n=normalize(p-bound.p);
                }

                float3 halfn=normalize(tolight-ray);

                float lamb=pow(clamp(dot(n,tolight),0.0,1.0),1.0)*0.9+0.1;
                float3 refray=reflect(ray,n);

                float spec1=clamp(dot(halfn,n),0.0,1.0);
                float spec2=clamp(dot(tolight,refray),0.0,1.0);

                float3 reffog=mix(
                    float3(0.87,0.8,0.83),
                    float3(0.3,0.6,1.0),
                    clamp(1.0-(1.0-refray.y)*(1.0-refray.y),0.,1.));

                float3 n1;

                col=lamb*float3(0.78,0.79,0.8);
                float3 rpos;
                float3 rcol;
                float tr;
                Trace(p, reflect(ray,n), tr, rpos, n1);
                float fresn=clamp(1.0-dot(ray,-n),0.0,1.0);
                if(tp<MAX_RAY_LENGTH)
                {
                    rcol=mix(float3(0.87,0.85,0.83),float3(0.1,0.12,0.4),
                        smoothstep(0.0,1.0,PlaneTexture(rpos.xz*0.2,600.0/tr/tr)));
                    rcol=mix(reffog,rcol,exp(-tr*0.02));
                }
                else
                {
                    rcol=reffog;
                }
                {
                    col=mix(col,rcol,pow(fresn,1.2)*0.50);
                    col+=rcol*(pow(fresn,2.6)*0.2+0.1);
                    col=mix(col,float3(1,1,1),pow(spec2,40.0)*.4);
                    col=mix(col,float3(1,1,1),.8*pow(spec2,180.0));
                }
                glFragColor.rgb=col;
            }
        }

        // Color coded steps count
        if(false)
        {
            if(nt>8)
                glFragColor.g+=.2;
            if(nt>16)
                glFragColor.r+=.4;
            if(nt>32)
                glFragColor.g-=.2;
            if(nt>48)
                glFragColor.rb+=vec2(-.4,.4);
        }
    }
    glFragColor.a=1.;
}
