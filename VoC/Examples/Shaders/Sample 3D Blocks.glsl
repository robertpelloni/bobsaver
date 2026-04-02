#version 420

// original https://www.shadertoy.com/view/WlBXzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AREA 60

float r1D(float r)
{
    return fract(sin(r*12.43)*519803.43);
}

float rand(vec2 p)
{
  return fract(sin(dot(p,vec2(12.43,98.21)))*519803.43);
}

float map(vec2 v, float s, vec2 z)
{
    if (z.x >= 0. && z.y >= 0.)
    {
        v*=z;
        v*=s;
        return rand(floor(v));
    }
    if (z.x < 0. && z.y >= 0.)
    {
        v*=z;
        v*=s;
        return rand(vec2(ceil(v.x-1.), floor(v.y)));
    }
    if (z.x < 0. && z.y < 0.)
    {
        v*=z;
        v*=s;
        return rand(ceil(v-1.));
    }
    if (z.x >= 0. && z.y < 0.)
    {
        v*=z;
        v*=s;
        return rand(vec2(floor(v.x), ceil(v.y-1.)));
    }
}

float grid2D(vec3 ro, vec3 rd, vec2 st)
{
    vec3 p;
    vec3 u=ro;
    
    int j = 1;
    for (int i=0;i<AREA;i+=0)
    {
        if (j > AREA)
            break;
        float h=0.;
        if (rd.x != 0.)
        {
            p.x=floor(u.x)+1.;
            h=(p.x-u.x)/rd.x;
            p.y=h*rd.y+u.y;
        }
        else    p.y=floor(u.y)+1.;
        if (p.y>=floor(u.y)+1.)
        {
            p.y=floor(u.y)+1.;
            h=(p.y-u.y)/rd.y;
            p.x=h*rd.x+u.x;
        }
        else{j++;}
        
        float g=(p.x-u.x)/rd.x;
        p.z=g*rd.z+u.z;
        float t=map(u.xy,1.,sign(st))*abs(sin(time)*rand(floor(u.xy))+1.);
        if (u.z<t)
        {
            return length(u-ro);
            break;
        }
        if (p.z<t)
        {
            float z = p.z-t;
            h=z/rd.z;
            float x = h*rd.x;
            h=x/rd.x;
            float y = h*rd.y;
            u = p-vec3(x,y,z);
            return length(u-ro);
        }
        u=p;
    }
    return 0.;
}

vec3 normal(vec3 p, vec2 st)
{
    float d = length(p);
    vec2 e = vec2(.01, 0.);
       vec3 n = vec3(map(p.xy-e.xy,1.,sign(st))-map(p.xy+e.xy,1.,sign(st)),
                  map(p.xy-e.yx,1.,sign(st))-map(p.xy+e.yx,1.,sign(st)),
                  e.x);
    return normalize(n);
}

#define B vec3(.6,.1,1.)
#define G vec3(.6,1.,.1)

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy*2.-1.;
    uv.x*=resolution.x/resolution.y;
    
    vec2 st=uv;
    vec3 ro=vec3(0.,0.,10.);
       vec3 rd=normalize(vec3(abs(st),-1.));
    
    vec3 col=vec3(0.);
    
    float d = grid2D(ro, rd, st);
    vec3 p = ro+rd*d;
    vec3 n = normal(p,st);
    vec3 l = vec3(cos(time),sin(time),.25)*10.;
    vec3 ld = normalize(l-p);
    float diff = max(dot(ld,n),0.);
    col += diff*p.z+(p.z+.1)*.1;
    glFragColor = vec4(sqrt(col*mix(B,G,p.z*1.5)), 0.);
}
