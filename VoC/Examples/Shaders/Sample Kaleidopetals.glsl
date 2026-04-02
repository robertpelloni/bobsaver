#version 420

// original https://www.shadertoy.com/view/4lKcRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 look(vec2 xy, vec3 origin, vec3 target)
{
    vec3 up=normalize(vec3(0.,1.,0.));
    vec3 fwd=normalize(target-origin);
    vec3 right=normalize(cross(fwd,up));
    up=normalize(cross(fwd,right));
    return normalize(fwd+right*xy.x+up*xy.y);
}
float map(vec3 p)
{
    for(int i=0;i<6;i++)
    {
        p-=0.33;
        float d=atan(p.y,p.x);
        float m=length(p.yx);
        d+=0.6;
        p.y=sin(d)*m;
        p.x=cos(d)*m;
        d=atan(p.z,p.x);
        m=length(p.zx);
        d+=0.7;
        p.z=sin(d)*m;
        p.x=cos(d)*m;
        p=abs(p);
    }
    return length(p)-.2;
}
#define MAX_DISTANCE 5.
float march(vec3 origin, vec3 ray)
{
    float t=.2;
    for(int i=0;i<17; i++)
    {
        float d=map(origin+ray*t);
        if(d<0.001||d>=MAX_DISTANCE) break;
        t+=d;
    }
    return min(t,MAX_DISTANCE);
}
void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv=(uv-0.5)*2.;
    uv.x=uv.x*resolution.x/resolution.y;   
    vec3 camera=vec3(sin(time),sin(time),cos(time))*2.;
    float shade=1.-march(camera,look(uv,camera,vec3(0.)))/MAX_DISTANCE;
    shade=pow(shade,3.);
    glFragColor = vec4(vec3(shade)*vec3(2.*shade,0.7,1.),1.0);
}
