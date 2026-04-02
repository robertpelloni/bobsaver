#version 420

// original https://www.shadertoy.com/view/7dXXRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
float t;
#define smin(a,b,k) min(a,b)-pow(max(k-abs(a-b),0.)/k,k)*k*(1.0/6.0)
float h(float x){return fract(sin(x*4534.34));}
float sb(vec3 p,vec3 s){p=abs(p)-s;return max(max(p.x,p.y),p.z);}
float c(float t,float s){
  t/=s;
  return mix(h(floor(t)), h(floor(t+1.)), pow(smoothstep(0.,1.,fract(t)),20.));
}
float meta(vec3 p){
  vec3 p1=p,p2=p,p3=p;
  p1.xz*=rot(t*.3454);
  p2.xy*=rot(t*.65765);
  p3.yz*=rot(t*.768);
  float a=length(p1-vec3(5.,0.,0.))-3.;
  float b=length(p2-vec3(0.,5.,0.))-5.;
  float c=length(p3-vec3(0.,0.,5.))-4.;
  float mi=3.;
  return smin(smin(a,b,mi),c,mi);
}
#define pi 3.141543535
float dgrd;
float g1,g2;
float balls;
float m(vec3 p){float d=meta(p);
  g2+=.4/(1.+d*d*d);
  balls=1./(1.+d);
  float dist = 6.;
  float grd=-abs(p.y)+dist;
  float rr=20.;
  vec3 p2=p;
  //p2.xz*=rot(1.35*pi+c(t,50.)+t*.5);
  p2.xz=abs(p2.xz)-45.;
  for(float i=0.;i<9.;i++){
    p2.xz*=rot(fract(t*.0245)*sin(t*.01+c(t,50.))*.5);
    p2.yx*=rot(1.-exp(cos(t*.0354))*.5+.5);
    p2.yz*=rot(floor(t*.05465));
    
    p2=abs(p2)-2.+i;
  }
  p2=(fract(p2/rr+.5)-.5)*rr;
  float cols=sb(p2,vec3(1., abs(p2.y), .1));
  
  dgrd+=1./(1.+grd);
  g1+=1./(1.+cols);
  
  d=smin(d,grd,1.);
  d=smin(d,cols*.44,.5);
  return d;
}
vec3 nm(vec3 p){
  vec2 e=vec2(0.01,0.);
  return m(p)-normalize(vec3(m(p-e.xyy),m(p-e.yxy),m(p-e.yyx)));
  
}
void main(void)
{
    t=mod(time, 50.);
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

  float fov=1.-length(uv)*.5;
  vec3 s=vec3(.0001, 0.001, -20.),r=normalize(vec3(uv,fov));
  s.xz*=rot(t);r.xz*=rot(t);
  float i,MAX=90.,d,dd;
  for(i=0.;i<MAX;i++)if(d=m(s),dd+=d,s+=d*r,abs(d)<.001) if(dgrd>5. || balls<5.) r=reflect(r,nm(s)),
    s+=d*r*9e2; else break;
  vec3 col=vec3(.0);
  col+=i/MAX;
  //col+=g1*vec3(0.346,0.546546,0.)*.01;
  col+=g2*vec3(0.0,0.,0.7576)*.1;
  if(dgrd>5.){
    vec3 paisage=vec3(0.345,0.04656,.01)*.05;
    paisage.yz*=rot(sin(t)*.5+.5);
    col+=dgrd*paisage;
    
  }
  col*=1.-max(dd/80.,0.);
    glFragColor = vec4(col,1);
}
