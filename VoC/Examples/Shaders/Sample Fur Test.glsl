#version 420

// original https://www.shadertoy.com/view/ws33zf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Using code from

// Inigo Quilez for the primitives
// https://www.shadertoy.com/view/Xds3zN

// NuSan for the noise function
// https://www.shadertoy.com/view/3dXSDH

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)
#define time time

float noise(vec3 p)
{
    vec3 ip=floor(p);
    p=fract(p);
    p=smoothstep(0.0,1.0,p);
    vec3 st=vec3(7,37,289);
    vec4 pos=dot(ip,st) + vec4(0.0,st.y,st.z,st.y+st.z);
    vec4 val=mix(fract(sin(pos)*7894.552), fract(sin(pos+st.x)*7894.552), p.x);
    vec2 val2=mix(val.xz,val.yw, p.y);
    return mix(val2.x,val2.y, p.z);
}

vec3 noise3(vec3 p) 
{
    float x=noise(p);
    float y=noise(p+sin(noise(p)));
    float z=noise(p+cos(noise(p)));
    return vec3(x,y,z);
}

float dot2(  vec3 v ) { return dot(v,v); }

float fur(vec3 pIn,vec3 p1,vec3 tU,vec3 tV,float h,float l,float sF,float sD,float speed,vec3 norm )
{
    vec3 fDir = normalize(noise3(p1*sD+time*speed))*2.0-1.0;
    float dot1= dot(norm,p1-pIn);
    vec3 Vnoise = ((pIn-p1)-(norm+fDir*2.0)*(1.0-dot1));
    vec3 noisV =(tU)*(dot((tU),Vnoise))+(tV)*(dot((tV),Vnoise));
    vec3 noisy =noisV*((cos(1.0-h)*0.2))*l;
    float noise=noise((pIn+noisy)*sF);
    return noise-(1.0-h);
}

mat2 rot(float a) 
{
    float ca=cos(a);
    float sa=sin(a);
    return mat2(ca,sa,-sa,ca);
}

float sphere(in vec3 p, in vec3 centerPos, float radius) 
{
    return length(p-centerPos) - radius;
}

float sdTorus( vec3 p, vec2 t,vec3 centerPos )
{
    vec2 q = vec2(length(p.xz+ centerPos.xz)-t.x,p.y+ centerPos.y);
    return length(q)-t.y;
}

float udQuad( vec3 p, vec3 a, vec3 b, vec3 c, vec3 d )
{
    
    vec3 ba = b - a; vec3 pa = p - a;
    vec3 cb = c - b; vec3 pb = p - b;
    vec3 dc = d - c; vec3 pc = p - c;
    vec3 ad = a - d; vec3 pd = p - d;
    vec3 nor = cross( ba, ad );

    return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(dc,nor),pc)) +
     sign(dot(cross(ad,nor),pd))<3.0)
     ?
     min( min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(dc*clamp(dot(dc,pc)/dot2(dc),0.0,1.0)-pc) ),
     dot2(ad*clamp(dot(ad,pd)/dot2(ad),0.0,1.0)-pd) )
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}

float map3(vec3 p)
{
    float s = sphere(p,vec3(0.0,0.0,25.0),20.0);
    float pl = udQuad(p,
              vec3(10000.0, 20.0, 10000.0),
              vec3(-10000.0, 20.0, 10000.0), 
              vec3(-10000.0, 20.0, -10000.0),
              vec3(10000.0, 20.0, -10000.0));
    float c = sdTorus(p,vec2(20.0,10.0),vec3(0.0,-10.0,25.0));
    float res = s;
    return min(min(res, pl),c);
}
  
float map(vec3 p)
{
    return sphere(p,vec3(0.0,0.0,0.0),20.0);
}
  
float mapFur(vec3 p,vec3 p1,vec3 tU,vec3 tV,float h,vec3 n)
{
    return fur(p,p1,tU,tV,h,10.0,3.0,0.05,1.0,n);
}
  
float getao(vec3 p, vec3 n, float dist) 
{
    return clamp(map3(p+n*dist)/dist, 0.0, 1.0);
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    vec3 s=vec3(0.0,0.0,-100.0);
    float t2=(time*0.5+10.0);
    s.y = -abs(cos(t2*0.5)*100.0);
    s.xz *= rot(t2*0.5);

    vec3 t=vec3(0.0,0.0,0.0);
    vec3 cz=normalize(t-s);
    vec3 cx=normalize(cross(cz,vec3(0.0,1.0,0.0)));
    vec3 cy=normalize(cross(cz,cx));
    vec3 r=normalize(uv.x*cx+uv.y*cy+cz*0.7);

    vec3 p=s;
    vec2 off=vec2(0.001,0.0);
    vec3 n;
    vec3 pIn;
    vec3 tU;
    vec3 tV;
    float h;
    vec3 up;
    float depth = 1.0;
    for(int cpt=0;cpt<2;cpt++)
    {
        bool hit = false;
        float d=0.0;
        float dd=0.0;
        for(int i=0; i<60; ++i) 
        {
            d=map3(p);
            if(d<0.0001 ){hit = true; break;}
            if(dd>400.0) {dd=400.0;hit = true; break;}
            p+=d*r*0.8;
            dd+=d;
        }
        depth = (1.0-length(p-s)/300.0);
        bool hit2;
        if(depth>0.0)
        {
            n=normalize(map3(p)-vec3(map3(p-off.xyy), map3(p-off.yxy), map3(p-off.yyx)));
            up=normalize(vec3(0.001,0.952315,0.0001));
            vec3 right=normalize(vec3(0.001,0.001,0.952315));
            tU = normalize(cross(right,n));
            tV = normalize(cross(n,tU));
            vec3 dirT = normalize(r*(1.0-dot(r,tU))+r*(1.0-dot(r,tV)));
            float hmax =2.0;
            float distmax = 5.0;
            vec3 maxDirI = r*distmax;
            float step = 100.0;
            vec3 dirI = maxDirI/step;
            h=1.0;
            float dotI = 1.0-max(dot(dirI,dirT),0.0);
            pIn=p;
            float d2=0.0;
            hit2 = false;
            
            for(int i=0; i<100; ++i) 
            {
                h = (clamp(dot(normalize(dirI),-n),0.2,1.0)*length(dirI)*float(i))/hmax;
                d2=mapFur(p+dirI*float(i),p,tU,tV,h,normalize(n));  
                pIn=p+dirI*float(i);
                if(d2>0.001){hit2=true; break;}
            }
        }
        if(hit)
            if(hit2)
                break;

            
    }
    
    vec3 l=normalize(vec3(-1,-2,-3));
    vec3 color1 = vec3(0.7,0.7,0.9);
    vec3 color2 = vec3(0.6,0.6,1.0);
    float dotr=(dot(r,l));
    vec3 sky = mix(color1,color2,min(dotr,1.0));
    off=vec2(0.0001,0.0);
    vec3 nStrand=normalize(mapFur(pIn,p,tU,tV,h,n)-vec3(mapFur(pIn-off.xyy,p,tU,tV,h,n), mapFur(pIn-off.yxy,p,tU,tV,h,n), mapFur(pIn-off.yyx,p,tU,tV,h,n)));
    vec3 col=vec3(0.0);
    vec3 ambient = sky*(1.0-max(dot(n,up),0.0)*0.8+0.2);
    float ao = (getao(p, n, 12.0) * 0.5 + 0.5) * (getao(p, n, 2.0) * 0.3 + 0.7) * (getao(p, n, 0.5) * 0.1 + 0.9);
    col = ((dot(normalize(nStrand+n),l)*0.5+0.5)*0.1+ambient*0.9)*ao;
    col = mix(sky,clamp(col,0.0,1.0)*clamp(1.0-h,0.2,1.0),clamp(ceil(depth),0.0,1.0));
    glFragColor = vec4(col,1.0);
}
