#version 420

// original https://www.shadertoy.com/view/Wslyzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI acos(-1.0)
#define TAU PI*2.0
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

float lpNorm(vec2 p, float n)
{
    p = pow(abs(p), vec2(n));
    return pow(p.x+p.y, 1.0/n);
}

float lpNorm(vec3 p, float n)
{
    p = pow(abs(p), vec3(n));
    return pow(p.x+p.y+p.z, 1.0/n);
}

vec2 pSFold(vec2 p,float n)
{
    float h=floor(log2(n)),a =TAU*exp2(h)/n;
    for(float i=0.0; i<h+2.0; i++)
    {
         vec2 v = vec2(-cos(a),sin(a));
        float g= dot(p,v);
         p-= (g - sqrt(g * g + 5e-4))*v;
         a*=0.5;
    }
    return p;
}

float pattern(vec2 p)
{
    for(int i=0;i<3;i++)
    {
        p=pSFold(p,8.0);
        p.x-=0.3;
    }
    
    return dot(p,rot(0.02)*vec2(1,0));
}

float boxmap(vec3 p)
{
    vec3 m = pow(abs((p)), vec3(20));
    vec3 a = vec3(pattern(p.yz),pattern(p.zx),pattern(p.xy));
    return dot(a,m)/(m.x+m.y+m.z);
}

float map(vec3 p)
{   
    vec2 p2=vec2(boxmap(p),lpNorm(p,3.));
    float c= 5.0;
    p2.y=mod(p2.y,c)-c*0.5;
    return lpNorm(p2,8.0)-0.1;
}

vec3 calcNormal(vec3 pos){
  vec2 e = vec2(1,-1) * 0.002;
  return normalize(
    e.xyy*map(pos+e.xyy)+e.yyx*map(pos+e.yyx)+ 
    e.yxy*map(pos+e.yxy)+e.xxx*map(pos+e.xxx)
  );
}

float softshadow(in vec3 ro, in vec3 rd)
{
    float res = 1.0;
    float t = 0.05;
    for(int i = 0; i < 32; i++)
    {
        float h = map(ro + rd * t);
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.1);
        if(h < 0.001 || t > 5.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    vec3 ro=vec3(0,5,-10);
    ro= vec3(cos(time*0.5+0.5*cos(time*.3))*8.0-6.,sin(time*0.8+0.5*sin(time*0.3))+4.0,sin(time*0.3+1.2*sin(time*0.3))*10.);
    ro*=3.;
    vec3 ta=vec3(3);
    ta.xz*=rot(time);
    ta.xy*=rot(time*0.3);
    vec3 w = normalize(ta-ro),u=normalize(cross(w,vec3(0,1,0))),v=cross(w,u);
    vec3 rd=mat3(u,v,w)*normalize(vec3(uv,2.0));
    vec3 col=vec3(0.12);
    float t=1.0,d;
    for(int i=0;i<96;i++)
    {
        t+=d=map(ro+rd*t);
        if (d<0.001) break;
    }
    if(d<0.001)
    {
        vec3 p=ro+rd*t;
        vec3 n = calcNormal(p);
        vec3 li = normalize(vec3(2.0, 3.0, 3.0));
        float dif = clamp(dot(n, li), 0.0, 1.0);
        dif *= softshadow(p, li);
        col=vec3(1);
        col *= max(dif, 0.3);
        float rimd = pow(clamp(1.0 - dot(reflect(-li, n), -rd), 0.0, 1.0), 2.5);
        float frn = rimd + 2.2 * (1.0 - rimd);
        col *= frn*0.8;
        col *= max(0.5+0.5*n.y, 0.0);
        col *= exp2(-2.*pow(max(0.0, 1.0-map(p+n*0.3)/0.3),2.0));
        col += pow(clamp(dot(reflect(rd, n), li), 0.0, 1.0), 60.0);
        col = mix( col, vec3(0.0), 1.0-exp( -0.0005*t*t ) );
    }
    glFragColor = vec4(col, 1.0);
}
