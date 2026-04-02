#version 420

// original https://www.shadertoy.com/view/tsc3WN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time*.51

float box(vec3 p, vec3 s) {
  p=abs(p)-s;
return max(p.x, max(p.y,p.z));
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float rnd(float t) {
  return fract(sin(t*457.332)*584.321);

}
float curve(float t, float d) {
  float g=t/d;
  return mix(floor(g), floor(g+1.), pow(smoothstep(0.,1.,fract(g)), 10.));
}

float at=0.;
float map(vec3 p) {
  //vec3 bp=p;
  float t3=time*0.2;
  p.xz *= rot(sin(p.y * 0.02 + t3)*1.1);
  p.xy *= rot(sin(p.z * 0.04 + t3)*.1);
  vec3 bp=p;
  float dist = 150.;
  p = (fract(p/dist-0.5)-0.5)*dist;
  for(float i=0.; i<5.; ++i) {
    float t = curve(time, 550.8+0.05*i);
    p.xy *= rot(t*0.3);
    p.xz *= rot(t*0.2+i);
    p=abs(p);
    p-= 5.;
    p.z-=2.;//  расстояние между кривыми
  }
  float d = box(p, vec3(.51,10,5.2));//  длина блоков по x y z
  d = min(d, length(p.zy)-0.2);
  vec3 bp2 = bp;
  bp2 = (fract(bp2/20.-0.5)-0.5)*50.;//  отражение в блоках 20.
  float k = box(bp2, vec3(10.,0.2,0.2));
  k = min(k, box(bp2, vec3(0.2,10,0.2)));
  k = min(k, box(bp2, vec3(0.2,0.2,10)));
  at += 0.2/(0.2+k);
  d = min(d, k);
  d = max(d, -(length(bp)-30.));//  высота блоков
  d *= 0.97;//  глубина .7
  return d;
}

void cam(inout vec3 p) {

  float t = time + curve(time, 11.5)*0.9 + curve(time, 14.7)*2.9;//  кривая камеры обзора  1.5 4.7
  p.yz *= rot(t*0.2);// .2
  p.xz *= rot(t*0.5);// .5
}

void main(void)
{
  vec2 uv=vec2(gl_FragCoord.x/resolution.x,gl_FragCoord.y/resolution.y);
  uv-=.5;
  uv/=vec2(resolution.y/resolution.x,1.);
  vec3 s=vec3(0.,0.,-110.);
  vec3 r=normalize(vec3(-uv,1.));
  cam(s);
  cam(r);
  float maxdist = 1000.;// .200
  vec3 p=s;
float i=0.;
  float dd=0.;
  for(i=0.; i<128.; ++i) {// глубина
    float d=map(p);
    if(d<0.001) {//  epsilon
      i+=d/0.001;
      break;
    }
    if(dd>maxdist) { dd=maxdist; break; }
    p+=d*r;
    dd+=d;
  }
  vec2 off=vec2(0.01,0);
  vec3 n=normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
  vec3 col=vec3(0.);
  vec3 l = normalize(-vec3(1.,3.,2.));
  float fog = 1.-clamp(dd/maxdist,0.,1.);
  vec3 sky = mix(vec3(0.5,0.3,2.2), vec3(2.5,0.3,0.2), pow(abs(r.y),2.));
  float ao= clamp(map(p+n),0.,1.) * clamp(map(p+n*4.)/4.,0.,1.);
  col += max(dot(n,l),0.);
  col += pow(1.-abs(dot(n,r)), 5.) * sky * 2.;
  col *= fog * ao;
  col += pow(at * 0.04,0.5) * vec3(2.,1.1,0.5);
  col += sky * pow((1.-fog)*1.2, 3.);
  float tt=time*0.93 - dd*0.02;//  радуга блоков .3  .01
  col.xy *= rot(tt);
  col.yz *= rot(tt*5.3);
  col=abs(col);
  col *= .89;
  col *= 1.32-length(uv);
  vec4 out_color=vec4(1.);
  out_color = vec4(col, 1.);
  glFragColor=vec4(out_color);
}
