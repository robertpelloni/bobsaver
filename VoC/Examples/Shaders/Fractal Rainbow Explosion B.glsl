#version 420

// original https://www.shadertoy.com/view/MtdcRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define iterKifs 90.
#define time time*2.

//someone elses shader, modified by ollj
//source lost, may evenbe be from glslsandbox.

#define dd(a) dot(a,a)
vec2 ddm(mat2 a){return vec2(dd(a[0]),dd(a[1]));}
vec3 ddm(mat3 a){return vec3(dd(a[0]),dd(a[1]),dd(a[2]));}
vec4 ddm(mat4 a){return vec4(dd(a[0]),dd(a[1]),dd(a[2]),dd(a[3]));}
#define u5(a)((a)*.5+.5)
#define u2(a)((a)*2.-1.)
vec2 c2(vec2 a){return a*vec2(1,-1);}
vec2 cs(vec2 a){return vec2(cos(a.x),sin(a.y));}
float suv(vec2 a){return a.x+a.y;}
float suv(vec3 a){return a.x+a.y+a.z;}
vec2 suv2(vec4 a){return vec2(suv(a.xy),suv(a.zw));}//sum modulo 2
vec4 abab(float a,float b){return vec4(a,b,a,b);}

float evalDx(float a,vec4 b){return((a*b.w+b.z)*b.y)+b.x;}
float rt(float a,vec3 b){return evalDx(a,b.yzxz);}

#define ViewZoom 1.
#define fra(u) (u-.5*resolution.xy)*ViewZoom/resolution.y
vec2 fra2(vec2 u){float r=resolution.x/resolution.y;u-=.5;u*=ViewZoom;u.x*=r;return u;}//fra2(u)=fra(u*resolution)

/**/

void main(void) { //WARNING - variables void ( out vec4 O, in vec2 U ){ need changing to glFragColor and gl_FragCoord
    vec2 U=gl_FragCoord.xy;
    vec4 O=glFragColor;
vec2 m=(U.xy-resolution.xy/2.0)/min(resolution.y,resolution.x)*30.
 ;mat2 w=mat2(m,m)
 ;m=(time+360.)*vec2(.1,.3)
 ;vec2 mspt=(vec2(suv(sin(m.x*vec3(1,.5,1.3)))+suv(cos(m.x*vec2(-0.4,.2)))//5x harmonics over 2 domains
     ,suv(cos(m.x*vec3(1,.8,1.5)))+suv(sin(m.x*vec2(-1.1,.1))))+1.)*.35//...scaled back to roughly[0,1]
 ;vec3 r=vec3(0)
 ;float Z=.4+mspt.y*.3,n=.99+sin(time*.03)*.003,a=(1.-mspt.x)*.5
 ;vec2 u=cs(suv2(vec4(.024,.23,.03,.01)*abab(m.y,a)))*vec2(3.1,3.3)
 ,t=1.1*cs(suv2(vec4(.03,.01,.033,.23)*abab(m.y,a)))
 ;for(float i=0.;i<iterKifs;i++
){vec2 p=vec2(dd(w[0]),dd(w[1]))
  ;if(p.y>1.)w[1]/=p.y;;if(p.x>1.)w[0]/=p.x;//;w[0]=mix(w[0],1./w[0],step(1.,p.x))//<-substitution fails because of mixint 1/x
  ;p=mix(1./p,p,step(p,vec2(1)))//;if(p>1.)p=1./p;
  ;r.x=evalDx(r.x,vec3(p,n).yzxz)
  ;if(i<iterKifs-1.
 ){r.y=evalDx(r.y,vec3(p,n).yzxz)
   ;if(i<iterKifs-2.)r.z=evalDx(r.z,vec3(p,n).yzxz);}
  ;w[0]=vec2(dot(w[0],c2(t)),dot(w[0],t.yx))*Z+vec2(.033,.14)
  ;w[1]=vec2(dot(w[1],c2(u)),dot(w[1],u.yx))*Z-vec2(.023,.22);}
 ;vec3 s=fract(r)
 ;s-=u5(sign(mod(r,2.)-1.))*u2(s)//;s=mix(1.-s,s,step(r,vec3(1.)))
 ;O=vec4(s,1)
/**/
;
    glFragColor=O;

}
