#version 420

// original https://www.shadertoy.com/view/4tycDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time mod(time,50.)/64.

float h(vec3 x){
    vec3 y=vec3(7,26,3);
    vec4 m=vec4(0,y.yz,y.y+y.z)+dot(floor(x),y);
    x=(x-=floor(x))*x*(3.-2.*x);
    m=mix(fract(sin(m)*437.),fract(sin(m+y.x)*437.),x.x);
    m.xy=mix(m.xz,m.yw,x.y);
    return mix(m.x,m.y,x.z);
}

float r(vec3 y){
    float m=0.;
    float v=1.;
    float f=2.;
    m+=(v/=2.)*h((f*=2.)*y);
    m+=(v/=2.)*h((f*=2.)*y);
    m+=(v/=2.)*h((f*=2.)*y);
    m+=(v/=2.)*h((f*=2.)*y);
    m+=(v/=2.)*h((f*=2.)*y);
    return m;
}

float d(vec3 y){
    return min(y.y+7.-r(y/10.)*2.-h(y.xzz*20.)/3.,
               min(max(max(min(abs(y.y)-.01,abs(y.x)-.01),-(y.z-=time*80.)-.1),length(y)-.4),length(y.xy)+(y.z-=.8)*y.z*.4-.4));
}

void main(void)
{
    vec3 f=vec3(1,2,time*60.+1.);
    //Originally hardcoded for 1080p
    vec3 a=vec3(gl_FragCoord.xy/resolution.y-vec2(1,1.3),1)/length(vec3(gl_FragCoord.xy/resolution.y-vec2(1,1.3),1));
    vec3 z=f+a/-a.y;
    float l=0.;
    while(l++<64.)f+=a*d(f)/2.;
    while(l++<100.&&max(time*2.,0.)>(r(z/3.)-abs(z.y+.5))&&f.y<(z+=a/-a.y*(1./32.+h(z*10000.)*.03)).y)
        glFragColor.xyz=max(time*2.,0.)<(r(z/3.)-abs(z.y+.5))?vec3(((r(z/3.)-abs(z.y+.5))-(r(z/3.+.05)-abs(z.y+.5)))/.6+.6):vec3((d(f+.4)-d(f))*2.*(f.y<-1.?vec3(.4,.5,.2):vec3(.5)));
    glFragColor.x+=max(-f.y*3.-27.+time*15.,0.),glFragColor+=h(f*10.-f.z*5.-time*200.)/4.*max(-f.y*3.-27.+time*15.,0.);
}
