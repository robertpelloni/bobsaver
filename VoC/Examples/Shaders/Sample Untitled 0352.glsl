#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI  = 3.141592653589793;
const float PI2 = PI* 2.;

#define saturate(x) clamp(x,0.,1.)

float tri(float x){return abs(2.*fract(x*.5-.25)-1.)*2.-1.;}
float sqr(float x){return -2.*(step(.5,fract(x*.5))-.5);}
float circuit(float x){return clamp(tri(x*4.)*.25,(sqr(x)-1.)*.5,(sqr(x+.5)+1.)*.5);}
float circuit2(float x){return clamp(tri(x*.5)*.5,0.,.25);}
float flow(float x,float d){return (1.+sin(x+d*time*5.+3.))*.3+.3;}
vec2 pp(vec2 p){float r=.5/p.y;return vec2(p.x*r, r);}

void main(void){
 float t=floor(time*30.)/15.;
 vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
 float l=0.,d=sign(p.y);
 vec2 r = p;
 vec2 q = p;
 q=pp(q);
 float n = floor(q.x/.5);
 q.x=mod(q.x,.5)-.25;
 p=pp(p);
 l+=step(abs(q.x+circuit(q.y+sign(p.y)*t+n)),.005);
 l+=pow(.001/abs(p.x+circuit(p.y+d*t)),flow(p.y,d));
 l+=pow(.001/abs(p.x+.75+circuit2(p.y+d*t)),(1.+sin(p.y+d*time*5.))*.3+.3);
 l+=pow(.001/abs(p.x-.75+circuit2(p.y+d*t)),(1.+sin(p.y+d*time*5.))*.3+.3);
 l=saturate(l);
 l*=abs(r.y*2.);
 l*=abs(sin(r.y*200.+sign(p.y)*time*5.))*.5+.5;
 l+=pow(.001/abs(p.x+circuit(p.x+d*time)),(1.+sin(p.x+d*time*5.+3.))*.3+.3);
 glFragColor = vec4(vec3(l)-vec3(.3,.1,0.), 1.0);
}
