#version 420

// original https://www.shadertoy.com/view/wsBfDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Distance glow made by balkhan
// Phantom Mode by aiekick

#define opRepEven(p,s) mod(p,s)-0.5*s 
#define opRepOdd(p,s) p-s*round(p/s)
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

float lpNorm(vec3 p, float n)
{
    p = pow(abs(p), vec3(n));
    return pow(p.x+p.y+p.z, 1.0/n);
}

vec2 pSFold(vec2 p,float n)
{
    float h=floor(log2(n)),a =6.2831*exp2(h)/n;
    for(float i=0.0; i<h+2.0; i++)
    {
         vec2 v = vec2(-cos(a),sin(a));
        float g= dot(p,v);
         p-= (g - sqrt(g * g + 5e-3))*v;
         a*=0.5;
    }
    return p;
}

vec2 sFold45(vec2 p, float k)
{
    vec2 v = vec2(-1,1)*0.7071;
    float g= dot(p,v);
     return p-(g-sqrt(g*g+k))*v;
}

float frameBox(vec3 p, vec3 s, float r)
{   
    p = abs(p)-s;
    p.yz=sFold45(p.yz, 1e-3);
    p.xy=sFold45(p.xy, 1e-3);
    p.x = max(0.0,p.x);
    return lpNorm(p,5.0)-r;
}

float sdRoundBox( vec3 p, vec3 b, float r )
{   
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float deObj(vec3 p)
{   
    return min(sdRoundBox(p,vec3(0.3),0.05),frameBox(p,vec3(0.8),0.1));
}

//+++++++++++++++++++++++++++++++
float g1=0.0,g2=0.0,pm=0.0;
bool fs=false;

float map(vec3 p)
{
    float de=1.0;
    p.z-=time*1.1;
    vec3 q= p;
    p.xy=pSFold(-p.xy,3.0);
    p.y-=8.5;
    p.xz=opRepEven(p.xz,8.5);
    
    float de1=length(p.yz)-1.;
    g1+=0.1/(0.1+de1*de1);
    de=min(de,de1);
    
    
    p.xz=pSFold(p.xz,8.0);
    p.z-=2.0;
    float rate=0.5;
    float s=1.0;
    for(int i=0;i<3;i++)
    {
        p.xy=abs(p.xy)-.8;
        p.xz=abs(p.xz)-0.5;
        p.xy*=rot(0.2);
        p.xz*=rot(-0.9);
        s*=rate;
        p*=rate;
        de=min(de,deObj(p/s));
    }
    
    if(fs)return de;
    q.z=opRepOdd(q.z,8.5);
    float de0=length(q)-1.5;
    pm = step(de0,de);
    g2+=0.1/(0.1+de0*de0);
    de=min(de,de0);
    return de;
    
}

vec3 calcNormal(vec3 pos){
  vec2 e = vec2(1,-1) * 0.002;
  return normalize(
    e.xyy*map(pos+e.xyy)+e.yyx*map(pos+e.yyx)+ 
    e.yxy*map(pos+e.yxy)+e.xxx*map(pos+e.xxx)
  );
}

float march(vec3 ro, vec3 rd, float near, float far)
{
    float t=near,d;
    for(int i=0;i<100;i++)
    {
        t+=d=map(ro+rd*t);
        if(d < 0.001)
        {
            if(pm<0.5) return t;
            t+=3.5;        }
        if (t>=far) return far;
    }
    return far;
}

float calcShadow( vec3 light, vec3 ld, float len ) {
    fs=true;
    float depth = march( light, ld, 0.0, len );    
    return step( len - depth, 0.01 );
}

void main(void)
{  
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    vec3 ro = vec3(-4,-3,3);
    vec3 ta = vec3(0);
    vec3 w = normalize(ta-ro);
    vec3 u = normalize(cross(w,normalize(vec3(0,1,3))));
    vec3 rd = mat3(u,cross(u,w),w)*normalize(vec3(uv,1.5));
    vec3 col;
    float maxd=50.0;
    float t=march(ro,rd,0.5,maxd);
    if(t<maxd)
    {
        vec3 p=ro+rd*t;
        col=vec3(1); 
        vec3 n = calcNormal(p);      
        vec3 lightPos=vec3(1,3,-2);
        vec3 li = lightPos - p;
        float len = length( li );
        li /= len;
        float dif = clamp(dot(n, li), 0.0, 1.0)*0.86;
        float sha = calcShadow( lightPos, -li, len );
        col *= vec3(1,0.6,0.2)*max(sha*dif, 0.2);
        float rimd = pow(clamp(1.0 - dot(reflect(-li, n), -rd), 0.0, 1.0), 2.5);
        float frn = rimd+2.2*(1.0-rimd);
        col *= frn*0.8;
        col *= max(0.5+0.5*n.y, 0.0);
        col *= exp2(-2.*pow(max(0.0, 1.0-map(p+n*0.3)/0.3),2.0));
        col += vec3(1,0.6,0.2)*pow(clamp(dot(reflect(rd, n), li), 0.0, 1.0), 20.0);
    }
    col+=vec3(0.1,0.1,0.6)*g1*0.12+vec3(1,0.6,0.2)*g2*0.1;
    col=pow(col,vec3(4.0,1.5,0.7));
    glFragColor.xyz = col;
}
