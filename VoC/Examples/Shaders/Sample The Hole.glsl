#version 420

// original https://www.shadertoy.com/view/3tfBzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DIST 100.0
#define R resolution.xy

mat2 rot(float x)
{
    float s = sin(x);
    float c = cos(x);
    return mat2(c,-s,s,c);
}

float box(vec3 p, vec3 d)
{
  vec3 q = abs(p) - d;
  return min(max(q.x,max(q.y,q.z)),0.0)+length(max(q,0.0));
}

float hex( vec3 p, vec2 h )
{
  vec3 k = vec3(-0.866, 0.5, 0.577);
  p = abs(p);
  p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
  float x = length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x);
  vec2 d = vec2(x, p.z-h.y );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float edgesize = .02;

float map(vec3 p)
{
    float a = (1.0+sin(time))/2.0;
    float r = box(p-vec3(0,0,60),vec3(30,20,50));
    float offset=10.*min(0.,(((10.0+edgesize)-p.z)/20.));
    float t = time/2.;
    p.x+=cos(t)*offset;
    p.y+=sin(t)*offset;
    
    vec3 hp = p;
    hp.xy*=rot(time);
    float h = hex(hp-vec3(0,0,60),vec2(.5,50));

    float r2 = hex(p-vec3(0,0,50),vec2(1.,50));
    p.xy=abs(p.xy);
    r2 = min(r2, hex(p-vec3(2.,0,0),vec2(1.,50)));
    r2 = min(r2, hex(p-vec3(1.5,1.7,0),vec2(1,50)));
    r2 = min(r2, hex(p-vec3(-.8,1,0),vec2(1.,50)));
    
    r=max(r,-r2);
    return min(r,h);
}

//ao and edge technique thanks to nusan
//https://www.shadertoy.com/view/WtyXDt
float getao(vec3 p, vec3 n, float dist) {
  return clamp(map(p+n*dist)/dist,0.0,1.0);
}

float ray(vec3 ro, vec3 rd, vec2 uv)
{
    float t = 0.;
    
    for(int i=0;i<200;i++)
    {
        vec3 p = ro+rd*t;
        float s = map(p);
        
        if(s<1e-5)break;
        t+=s;
        if(t>MAX_DIST){t=-1.;break;}
    }
    return t;
}

vec3 normal(vec3 p)
{
    vec2 e = vec2(0.0001,0);
    return normalize(vec3(
        map(p+e.xyy)-map(p-e.xyy),
        map(p+e.yxy)-map(p-e.yxy),
        map(p+e.yyx)-map(p-e.yyx)));
}

void main(void)
{
    
    vec2 uv = (2.*gl_FragCoord.xy-R)/R.y;
    
    vec3 ro = vec3(0,0,0);
    vec3 ta = vec3(0,0,10);
    vec3 cf = normalize(ta-ro);
    vec3 cu = normalize(cross(cf,vec3(0,1,0)));
    vec3 cr = normalize(cross(cu,cf));
    vec3 rd = normalize(uv.x*cu+uv.y*cr+2.*cf);
    
    float r = ray(ro,rd, gl_FragCoord.xy);
    
    vec3 col = vec3(1);
    
    float fog = 1.;
    
    if(r>0.)
    {
        vec3 p = ro+rd*r;
        vec3 n = normal(p);    
        
        float ao = getao(p,n,edgesize);
        float ao2 = getao(p,n,-edgesize);
        col-=(r-10.)/35.+smoothstep(1.,.9,ao*ao2)*10.;
    }
    
    glFragColor.rgb=col;
}
