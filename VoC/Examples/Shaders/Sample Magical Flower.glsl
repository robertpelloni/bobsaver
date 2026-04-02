#version 420

// original https://www.shadertoy.com/view/wlXXz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI acos(-1.0)
#define TAU PI*2.0

vec2 rotate(vec2 p, float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a))*p;
}

vec3 rotate(vec3 p,vec3 axis,float theta)
{
    vec3 v = cross(axis,p), u = cross(v, axis);
    return u * cos(theta) + v * sin(theta) + axis * dot(p, axis);   
}

vec3 hue(float t){
return cos((vec3(0,2,-2)/3.+t)*TAU)*.5+.5;
}

vec2 pmod(vec2 p, float r)
{
    float a = mod(atan(p.y, p.x), TAU / r) - 0.5 * TAU / r;
    return length(p) * vec2(sin(a), cos(a));
}

float map(vec3 p)
{
    p.xy = rotate(p.xy,time*0.2);
    p.yz = rotate(p.yz,time*0.1);
    for(int i=0;i<3;i++)
    {
        p.xy = pmod(p.xy,18.0);
        p.y-=mix(8.5,6.5,step(0.5,fract(time*0.2+3.0)));
        p.yz = pmod(p.yz,16.0);
        p.z-=mix(6.5,11.0,step(0.5,fract(time*0.1)));
    }
    return dot(abs(p),
               rotate(
                   normalize(vec3(2,1,3)),
                   normalize(vec3(5,1,2)),
                   1.4*sin(time*0.5))
              )
            -0.5-sin(time*0.8+2.3)*0.2;
}

void main(void)
{
   vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
     vec3 ro=vec3(0,5,43.0);
     vec3 ta = vec3(3.5,0,0);
     ta.xz=rotate(ta.xz,time*0.6);    
     vec3 w=normalize(ta-ro);
     vec3 u=normalize(cross(w,vec3(0,1,0)));
    vec3 rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
    vec3 col = hue(0.55)*0.25;
    float d,t=0.0;
    for(float i=1.0;i>0.0;i-=1.0/80.0)
    {
         t+=d=map(ro+t*rd);
        if(d<0.001)
        {
            col+=mix(vec3(1),hue(length(ro+t*rd)*0.1+time*0.1),0.8)*i*i;
            break;
        }
    }
    glFragColor = vec4(col, 1.0);
}
