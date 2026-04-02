#version 420

// original https://www.shadertoy.com/view/tlKBRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t time
#define bpm 60.
#define B (60./bpm)
#define b (mod(t,B)/B)

#define f(p)if(p.x<p.y)p=p.yx;

vec3 rot(vec3 p,vec3 a,float t){
  a=normalize(a);
  return mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a);
}

void main(void)
{
    vec2 uv = (2.* gl_FragCoord.xy - resolution.xy )/resolution.y;
    vec3 p,c=vec3(0),d=normalize(vec3(uv,2));
    float g=0.,e,s,a;
    for(float i=0.;i<99.;i++){
        p=g*d;
        p.z-=7.;
        p=rot(p,vec3(1,1,1),mix(.5,1.2,mod(t,4.)/4.));
        s=2.;
        p=abs(p)-1.8;
        f(p.xy)
        f(p.xz)
        for(int i=0;i<10;i++){
            p=.8-abs(p-1.2);
            f(p.xz)
            s*=e=3./clamp(dot(p,p),.0,1.2);
            p=abs(p)*e-vec3(.3,9.+b*b*5.,6);
        }
        a=1.;
        p-=clamp(p,-a,a);
        g+=e=length(p)/s;
        e<.001?c+=pow(cos(i/64.),5.)*.02
            *mix(vec3(1),(cos(vec3(1,2,3)+log(s)+t)*.5+.5),.5)
            :p;
    }
    glFragColor = vec4(c,1.0);
}
