#version 420

uniform float time; uniform vec2 resolution;

out vec4 glFragColor;
#define PI 3.14159265358979323846264
vec3 m9(vec3 x) {return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec2 m9(vec2 r){return r-floor(r*(1./289.))*289.;}vec3 pe(vec3 r)
{return m9((r*34.+1.)*r);}float sn(vec2 r)
{const vec4 s=vec4(.211325,.366025,-.57735,.0243902);
vec2 v=floor(r+dot(r,s.gg)),g=r-v+dot(v,s.rr),n;n.r=step(g.g,g.r);n.g=1.-n.r;n=g.r>g.g?vec2(1.,0.)
:vec2(0.,1.);g=g;vec4 d=g.rgrg+s.rrbb;d.rg-=n;v=m9(v);vec3 m=pe(pe(v.g+vec3(0.,n.g,1.))
+v.r+vec3(0.,n.r,1.)),f=max(.5-vec3(dot(g,g),dot(d.rg,d.rg),dot(d.ba,d.ba)),0.);
f=f*f;f=f*f;vec3 a=2.*fract(m*s.aaa)-1.,b=abs(a)-.5,I=floor(a+.5),c=a-I;f*=1.79284-.853735*(c*c+b*b);
vec3 p;p.r=c.r*g.r+b.r*g.g;p.gb=c.gb*d.rb+b.gb*d.ga;return 130.*dot(f,p);}float clouds(vec2 r)
{float v=sn(r);v+=.5*sn(r*2.);v+=.25*sn(r*4.);v+=.125*sn(r*8.);
v+=.0625*sn(r*16.);v+=.03125*sn(r*32.);v+=.03125*sn(r*32.);return v;}void main()
{vec2 v=2.*gl_FragCoord.rg/resolution.rg-1.;v.r*=resolution.r/resolution.g;float r=length(v),
g=atan(v.g,v.r);r=2.*asin(r)/PI;vec2 f=vec2(r*cos(g),r*sin(g));f=f/2.+.5;
f.r+=time*.03;f.g+=time*.009;float s=clouds(f*3.),d=smoothstep(.1,0.,s);
vec3 n=vec3(.298039,.576471,.254902);n=mix(vec3(.513725,.435294,.152941),n,smoothstep(.2,.7,1.-s));
n=mix(vec3(.368627,.262745,.121569),n,smoothstep(0.,.18,s));n+=s*.3;vec2 p=gl_FragCoord.rg/resolution.rg-.5;
p.r*=resolution.r/resolution.g;float a=length(p);vec3 m=vec3(.317647,.47451,.709804);
m-=(1.-s*4.)*.03;m=mix(n,m,d);m=clamp(m,0.,1.);m*=smoothstep(.5,.495,a);m*=smoothstep(.65,.32,a);
vec3 c=vec3(smoothstep(.6,.4,a))*vec3(.6,.8,1.5);glFragColor=vec4(m,1.);}
