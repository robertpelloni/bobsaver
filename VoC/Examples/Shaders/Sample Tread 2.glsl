#version 420

// original https://www.shadertoy.com/view/wscXWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define T time*2.

#define MAX_DIST 100.0
#define PI 3.1415927

mat2 rot(float x)
{
    float s = sin(x);
    float c = cos(x);
    return mat2(c,-s,s,c);
}

//thanks to iq for sharing this knowledge on his website
float torus(vec3 p, vec2 t)
{
    vec2 b = vec2(length(p.xz)-t.x,p.y);
    return length(b)-t.y;
}

float capsule(vec3 p, vec3 a, vec3 b, float r)
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
    return length(pa-ba*h)-r;
}

float box(vec3 p, vec3 d)
{
  vec3 q = abs(p) - d;
  return min(max(q.x,max(q.y,q.z)),0.0)+length(max(q,0.0));
}

float smin(float d1, float d2, float k)
{
    float h = clamp(0.5+0.5*(d2-d1)/k,0.0,1.0);
    return mix(d2,d1,h)-k*h*(1.0-h);
}

vec3 cam(vec3 ro, vec3 ta, vec2 uv)
{
    vec3 cf = normalize(ta-ro);
    vec3 cu = normalize(cross(cf,vec3(0,1,0)));
    vec3 cr = normalize(cross(cu,cf));
    return normalize(uv.x*cu+uv.y*cr+2.*cf);
}

vec2 map(vec3 p)
{
    float m = 0., r;
    vec3 cp = p+vec3(0,cos(p.z/3.),-T);//+vec3(0,cos(p.z/3.)*.3,0.-T);
    vec3 scp = cp;
    scp.xy*=rot(PI/2.);
    scp.xz*=rot(time*1.5);

    vec2 ap = vec2(atan(scp.y,scp.x),length(scp));
    
    vec3 tcp = scp;
    float bx = box(tcp,vec3(1,.05,.05));
    for(float i=0.;i<4.;i++){
        tcp.xz*=rot(PI/4.*i);
        bx=min(bx,box(tcp,vec3(1,.05,.05)));
    }
    
    float s = torus(scp,vec2(1,.2));
    float ss = length(scp)-.1;
    bx=max(bx,-ss);
    float c = capsule(cp+vec3(0,1.,-.65),vec3(0),vec3(0,0,-100),.6);
    float f = cp.y+1.;
    float tr =max(f,-c);
    f=smin(f,tr,1.);
    r=min(s,f);
    r=min(r,bx);
    if(r==s)m=1.;
    else if(r==bx)m=3.;
    else if(r>=c)m=2.;
    return vec2(r,m);
}

vec2 ray(vec3 ro, vec3 rd)
{
    float t=0., m=0.;
    
    for(int i=0;i<128;i++)
    {
        vec3 p = ro+rd*t;
        vec2 s = map(p);
        m=s.y;
        if(abs(s.x)<0.0001)break;
        t+=s.x/2.;
        if(t>MAX_DIST){t=-1.;break;}
    }
    
    return vec2(t,m);
}

vec3 normal(vec3 p)
{
    vec2 e=vec2(0.00005,0);
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

    vec3 ro = vec3(4,3,10.+T);
    vec3 ta = vec3(2,0,T);
    vec3 rd = cam(ro,ta,uv);
    
    vec2 r = ray(ro,rd);
    vec2 suv = uv+vec2(-1.5,-.75);
    float at = atan(suv.y,suv.x);
    vec3 col = vec3(0.2,.9,2.5)*(rd.y+.3)+(1.+cos(at*10.+time))/40.;

    if(r.x>0.)
    {
        vec3 mate = vec3(0.1,.2,.1);
        if(r.y>.5&&r.y<1.5)mate=vec3(0.01);
        else if(r.y==2.)mate=vec3(.3);
        else if(r.y==3.)mate=vec3(.8);
        vec3 p = ro+rd*r.x;
        vec3 n = normal(p);
        vec3 s = normalize(vec3(.5,.4,-.2));
        float dif = clamp(dot(s,n),0.,1.);
        float sky = clamp(0.5+0.5*dot(n,vec3(0,1,0)),0.,1.);
        float bou = clamp(0.5+0.5*dot(n,vec3(0,-1,0)),0.,1.);
        float sha = step(ray(p+n*0.0001,s).x,0.);
        col=mate*dif*sha;
        col+=mate*vec3(0.3,.3,.5)*sky;
        col+=mate*vec3(0.2,.2,.4)*bou;
    }
    col=pow(col,vec3(0.454545));
    glFragColor.rgb=col;
}
