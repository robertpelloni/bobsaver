#version 420

// original https://www.shadertoy.com/view/WsdBRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI acos(-1.)
#define TAU PI*2.
#define hue(t) (cos((vec3(0,2,-2)/3.+t)*TAU)*.5+.5)

void rot(inout vec3 p,vec3 a,float t){
    a=normalize(a);
    vec3 v=cross(a,p),u=cross(v,a);
    p=u*cos(t)+v*sin(t)+a*dot(p,a);   
}

void main(void)
{
    vec2 p=(gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    p=vec2(atan(p.y,p.x)/PI,length(p));
    for(float i=0.;i<10.;i++)
    {
        vec3 q=vec3(p.x,1.5/p.y-i-fract(-time),i);
        for(int j=0;j<6;j++)
        {
            q.xy=abs(q.xy)-.5;
            q.xz=abs(q.xz)-.2;
            rot(q,vec3(2,-3,8),time*.5+cos(time*.2)*.5);
        }
        glFragColor.xyz+=mix(vec3(1),hue(i*.2+time),.8)*.006/abs(q.y);
    }
}
