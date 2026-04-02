#version 420

// original https://www.shadertoy.com/view/3llSz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI acos(-1.0)
#define TAU PI*2.0
#define PITCH 23.0

mat2 rotate(float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

vec3 rotate(vec3 p,vec3 axis,float theta)
{
    vec3 v = cross(axis,p), u = cross(v, axis);
    return u * cos(theta) + v * sin(theta) + axis * dot(p, axis);   
}

vec3 hue(float t){
    return cos((vec3(0.,2./3.,-2./3.)+t)*TAU)*.5+.5;
}

float lengthN(vec2 p, float n)
{
    p = pow(abs(p), vec2(n));
    return pow(p.x+p.y, 1.0/n);
}

float hash(float n)
{
    return fract(sin(n)*5555.5);
}

float smin(in float a, in float b, in float k)
{
    float h = clamp(0.5+0.5*(b-a)/k,0.0,1.0);
    return mix(b,a,h)-k*h*(1.0-h);
}

// glslsandbox.com/e#37069.3 
float deTetra(vec3 p, float r)
{
    float g=0.577,s = 0.0;
    float e=10.0;
    s+=pow(max(0.0,dot(p,vec3(-g,-g,-g))),e);
    s+=pow(max(0.0,dot(p,vec3(g,-g,g))),e);
    s+=pow(max(0.0,dot(p,vec3(g,g,-g))),e);
    s+=pow(max(0.0,dot(p,vec3(-g,g,g))),e);
    s=pow(s,1./e);
    return s-r;
}

float deStellate(vec3 p,float r)
{
    float c=8.0;
    p.xy-=0.5*PITCH;
    vec3 seed = vec3(vec2(floor(p.xy/PITCH)),floor(p.z/c))+0.234;
    p.z=mod(p.z,c)-0.5*c;
    p.xy=mod(p.xy,PITCH)-0.5*PITCH;
    p = rotate(p,
        normalize(vec3(hash(seed.x),hash(seed.y),hash(seed.z))*2.0-1.0),
        time*(1.3+hash(dot(seed,vec3(1,15,99)))*3.0)
        );
    return smin(deTetra(p,r),deTetra(-p,r),.1);
}

float deTube(vec3 p)
{
    p.xy-=0.5*PITCH;
    vec2 seed=floor(p.xy/PITCH);
    float z = p.z+time*5.+hash(dot(seed,vec2(1,50)))*50.0;
    p.z -= time*5.0;
    p.y-=sin(z*0.15+0.6*sin(z*.5))*1.2;
    p.x-=cos(z*0.12+0.5*cos(z*.3))*1.2;  
    p.xy=mod(p.xy,PITCH)-0.5*PITCH;
    
    float de =1e9,num=7.0;
    for(float i=-1.0;i<2.0;i+=2.0)
    {
        vec3 q=p;
          q.xy *= rotate((smoothstep(-1.0,1.0,(mod(q.z,3.0)-1.5))+floor(q.z/3.0))*PI/num*i);
        float a = mod(atan(q.x,q.y),TAU/num)-0.5*TAU/num;
        q.xy = length(q.xy)*vec2(sin(a),cos(a));
          q.y -= 3.0;
        de= smin(de,lengthN(q.xy,5.0)-0.15,0.1);
    }
    return de*0.8;
}

vec3 transform(vec3 p)
{
    float c= 26.0;
    float it = floor(time/c);
    float t = mod(time, c);
    t -= clamp(t, 0.0, 5.0);
    p = rotate(p,normalize(vec3(1,hash(it)*2.0-1.0,1)),t*0.3);
    return p;
}

float map(vec3 p)
{
    p = transform(p);
    return min(deTube(p),deStellate(p,0.6));  
 }

vec3 calcNormal(vec3 pos){
  vec2 e = vec2(1,-1) * 0.002;
  return normalize(
    e.xyy*map(pos+e.xyy)+e.yyx*map(pos+e.yyx)+ 
    e.yxy*map(pos+e.yxy)+e.xxx*map(pos+e.xxx)
  );
}

vec3 doColor(vec3 p){
    p = transform(p);
    if (deStellate(p,0.6)<0.001) return hue(0.0);
    return hue(0.05)*0.5;
 }

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    vec3 ro = vec3(0.0, 0.0, 18.0);
     vec3 rd = normalize(vec3(uv, -3));
    vec3 col = clamp((hue(0.7)+0.2)*0.4*length(uv),0.0,1.0);
    float t = 0.0, d;
     for(int i = 0; i < 128; i++)
      {
        t += d = min(map(ro + rd * t),1.0);
        if(d < 0.001) break;
      }
      if(d < 0.001)
      {
          vec3 p = ro + rd * t;
         vec3 nor = calcNormal(p);
        vec3 li = normalize(vec3(1));
        vec3 bg = col;
        col = doColor(p);
        col *= clamp(dot(nor, li), 0.3, 1.0);
        col *= max(0.5 + 0.5 * nor.y, 0.0);
        col += pow(clamp(dot(reflect(normalize(p - ro), nor), li), 0.0, 1.0), 80.0);
        col = clamp(col,0.0,1.0);
        col = mix(bg, col, exp(-t*t*0.0001));
          col = pow(col, vec3(0.9));        
    }
    glFragColor = vec4(col,1);
}
