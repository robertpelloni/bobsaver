#version 420

uniform vec2  resolution;     // resolution (width, height)
uniform vec2  mouse;          // mouse      (0.0 ~ 1.0)
uniform float time;           // time       (1second == 1.0)
uniform sampler2D backbuffer; // previous scene

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

vec2 pmod(vec2 p, float r)
{
    float a = mod(atan(p.y, p.x), TAU / r) - 0.5 * TAU / r;
    return length(p) * vec2(sin(a), cos(a));
}

vec3 hue(float t){
return cos((vec3(0,2,-2)/3.+t)*TAU)*.5+.5;
}

float map(vec3 p)
{
    //p.z -=time*3.0;
    p.xy = rotate(p.xy,time*0.2);
    p.yz = rotate(p.yz,time*0.1);
    //p = mod(p,5.0)-2.5;
    //p.xy = pmod(p.xy,8.0);
    //p.y-=2.0;
    //p.y= mod(p.y,2.0)-1.0;
   for(int i=0;i<5;i++)
    {
        p.xy = pmod(p.xy,12.0);
        p.y-=4.0;
        p.yz = pmod(p.yz,16.0);
        p.z-=6.8;
    }
    //return dot(abs(p),normalize(vec3(1)))-0.5;
    return dot(abs(p),rotate(normalize(vec3(2,1,3)),normalize(vec3(7,1,2)),1.8))-0.3;
    //return dot(abs(p),rotate(normalize(vec3(2,1,3)),normalize(vec3(5,1,2)),1.8*sin(time)))-0.4-sin(time+2.3)*0.2;
    //return dot(abs(p),rotate(normalize(vec3(2,1,3)),normalize(vec3(1)),sin(2.0*time+3.0*sin(time*0.5))*0.5+1.5))-0.5;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / resolution.y;
     vec3 ro=vec3(0,0,3.5);
     vec3 ta = vec3(1,0,0);
     ta.xz=rotate(ta.xz,time*0.5);
     
     vec3 w=normalize(ta-ro);
     vec3 u=normalize(cross(w,vec3(0,1,0)));
    vec3 rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
    vec3 col = vec3(0);
    float d,t=0.0;
    for(float i=1.0;i>0.0;i-=1.0/80.0)
    {
         t+=d=map(ro+t*rd);
        if(d<0.001)
        {
            col+=mix(vec3(1),hue(length(ro+t*rd)*0.1+time*0.1),0.6)*i*i;
            break;
        }
    }
    glFragColor = vec4(col, 1.0);
}
