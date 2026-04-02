#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/NdGGRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float maxd=80.0;

vec3 rot(inout vec3 p,vec3 axis,float theta){
    axis=normalize(axis);
    return mix(axis*dot(p,axis),p,cos(theta))+sin(theta)*cross(p,axis);
}

vec2 polarAbs(vec2 p,float n)
{
  n*=0.5;
  float a = asin(sin(atan(p.x,p.y)*n))/n;
  return vec2(sin(a),cos(a))*length(p);
}

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

#define hash(p)fract(sin(p*12345.5))

vec3 randVec(float s)
{
    vec2 n=hash(vec2(s,s+2315.3));
    return vec3(cos(n.y)*cos(n.x),sin(n.y),cos(n.y)*sin(n.x));
}

vec3 randCurve(float t,float n)
{
    vec3 p = vec3(0);
    for (int i=0; i<3; i++){
        p+=randVec(n+=365.)*sin((t*=1.3)+sin(t*.6)*.5);
    }
    return p;
}

vec3 targetVector0()
{
    return randVec(32892.+floor(time/2.));
}

vec3 axisVector()
{
    vec3 a = targetVector0();
    vec3 b = a.yzx;
    for(int i=0;i<100;i++)
    {
        if (all(equal(a, b))==false) break;
        b.z += 0.1;
        b = normalize(b);
    }
    vec3 w = a;
    vec3 u = normalize(cross(b,w));
    vec3 v = cross(w,u);
    return v;
}

vec3 targetVectorA()
{
    vec3 v = targetVector0();
    vec3 a = axisVector();
    float t = -time;
    return rot(v,a,t);    
}

vec3 targetVectorB()
{
    vec3 v = targetVector0();
    vec3 a = axisVector();
    float t = time;
    return rot(v,a,t);
}

float deA(vec3 p)
{
    float de =1.;
    vec3 target = targetVectorA();
    vec3 axis = axisVector();
    vec3 w = normalize(target);
    vec3 u = normalize(cross(axis,w));
    vec3 v = cross(w,u);
    //p = inverse(mat3(u,v,w)) * p;
    p = p * mat3(u,v,w);
    vec3 q=p;
    p.x -= clamp(p.x, -0.1, 0.1);
    p.y -= clamp(p.y, -0.02, 0.02);
    p.z -= clamp(p.z, 0.1, 1.0);
    de = min(de,length(p)-.01);
    q.xz=polarAbs(q.xz,24.);
    q.z-=1.12;
    return min(de,(lpNorm(q,5.0)-.091+q.z*.3)*.8);
}

float deB(vec3 p)
{
    float de=1.;
    vec3 target = targetVectorB();
    vec3 axis = axisVector();
    vec3 w = normalize(target);
    vec3 u = normalize(cross(axis,w));
    vec3 v = cross(w,u);
    p = vec3(dot(p,u), dot(p,v), dot(p,w));
    de=min(de,lpNorm(vec2(length(p.yz)-.95,p.x),5.0)-.07);
    de=min(de,lpNorm(vec2(length(p.xz)-1.,p.y),5.0)-.1);
    de=min(de,lpNorm(vec2(length(p.xz)-.15,p.y),5.0)-.07);
    p.x -= clamp(p.x, -0.1, 0.1);
    p.y -= clamp(p.y, -0.02, 0.02);
    p.z -= clamp(p.z, 0.1, 1.0);
    de=min(de, length(p)-.01);
    return de;
}

float deC(vec3 p)
{
    vec3 targetA = normalize(targetVectorA());
    vec3 targetB = normalize(targetVectorB());
    // cross() test
    vec3 cx = cross(targetA, targetB);
    vec3 axis = targetA;
    vec3 w = normalize(cx);
    vec3 u = normalize(cross(axis,w));
    vec3 v = cross(w,u);
    p = transpose(mat3(u,v,w)) * p;
    //p = p * mat3(u,v,w);       
    float len = length(cx); 
    p.z -= clamp(p.z, 0.0, len);
    return lpNorm(p,3.)-.1;
}

float map(vec3 p)
{
    float de = 1.;
    de = min(de, deA(p));
    de = min(de, deB(p));
    de = min(de, deC(p));
    de = min(de, p.y + 1.2);
    return de;
}

vec3 calcNormal(vec3 p)
{
  vec3 n=vec3(0);
  for(int i=0; i<4; i++){
    vec3 e=.001*(vec3(9>>i&1, i>>1&1, i&1)*2.-1.);
    n+=e*map(p+e);
  }
  return normalize(n);
}

float march(vec3 ro, vec3 rd, float near, float far)
{
    float t=near,d;
    for(int i=0;i<100;i++)
    {
        t+=d=map(ro+rd*t);
        if (d<0.001) return t;
        if (t>=far) return far;
    }
    return far;
}

vec3 doColor(vec3 p)
{
    if(deC(p)<0.001) return vec3(1.8,0.5,0.2);
    return vec3(0.3,0.5,0.8)+cos(p*0.3)*.5+.5;
}

void main(void)
{  
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    vec3 ro=vec3(1.5);
    vec3 ta =randCurve(time*.3,1234.6)*.4;
    vec3 w = normalize(ta-ro);
    vec3 u = normalize(cross(w,vec3(0,1,0)));
    vec3 rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2.0));
    vec3 col= vec3(0.05,0.05,0.1);
    float t=march(ro,rd,0.0,maxd);
    if(t<maxd)
    {
        vec3 p=ro+rd*t;
        col=doColor(p); 
        vec3 n = calcNormal(p);      
        vec3 lightPos=vec3(5,5,1);
        vec3 li = lightPos - p;
        float len = length( li );
        li /= len;
        float dif = clamp(dot(n, li), 0.0, 1.0);
        col *= max(dif, 0.3);
        float rimd = pow(clamp(1.0 - dot(reflect(-li, n), -rd), 0.0, 1.0), 2.5);
        float frn = rimd+2.2*(1.0-rimd);
        col *= frn*0.7;
        col *= max(0.5+0.5*n.y, 0.0);
        col *= exp2(-2.*pow(max(0.0, 1.0-map(p+n*0.3)/0.3),2.0));
        col += vec3(0.8,0.6,0.2)*pow(clamp(dot(reflect(rd, n), li), 0.0, 1.0), 80.0);
        col = mix(vec3(0.1,0.1,0.2),col,  exp(-0.01*t*t));
        col = clamp(col,0.0,.9);
            
    }
    col=pow(col,vec3(1.5));
    glFragColor.xyz = col;
}

