#version 420

// original https://www.shadertoy.com/view/mdt3W4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time
#define resolution resolution
#define so abs(sin(time*10.2) + cos(time*3.4)) * 0.5
#define st abs(sin(time*5.2) + abs(cos(time*1.4))) * 0.5

float det=.001, br=0., ct = 0., cs = 0., cbs = 0., cls = 0., cld = 0., clf = 0.;
vec3 pos, sphpos;
mat3 lookat(vec3 dir, vec3 up) {
  vec3 rt=normalize(cross(dir,up));
  return mat3(rt,cross(rt,dir),dir);
}
vec3 path(float t) {
  return vec3(sin(t+cos(t)*.1)*.2,cos(t*.2),t);
}
mat2 rot(float a) {
  float s=sin(a);
  float c=cos(a);
  return mat2(c,s,-s,c);
}

float tt(vec3 pp, bool dualRot) {

  pp.x+=sin(ct*.5);
  pp.y+=sin(ct*.3);
  pp*=cs;
  
  pp.xy*=rot(pp.z*2.);
  pp.xz*=rot(ct*2.);
  pp.yz*=rot(ct);
  
  if(dualRot)
  {
      pp.xy*=rot(pp.x*2.);
      pp.xz*=rot(pp.z*2.);
      pp.yz*=rot(pp.y*2.);
  }

  float br2=length(pp)-cbs;
  
  br2=min(br2,length(pp.xy)+cld);
  br2=min(br2,length(pp.xz)+cld);
  br2=min(br2,length(pp.yz)+cld);
  
  br2=min(br2,length(pp.yy)+clf);
  br2=min(br2,length(pp.zz)+clf);
  br2=min(br2,length(pp.xx)+clf);
  
  br2=max(br2,length(pp)-cls);
  
  br=min(br2,br);
  float d=br2;
  return d;
}

struct Information
{
    float d;
    int i;
};

Information de(vec3 p) {
  br=1000.;
  vec3 pp=p-sphpos;
  
  float result, co;
  
  ct = time + abs(sin(time*0.2) + cos(time*.4)) + 2.25;
  cs = 1.0;
  cbs = 0.15;
  cls = 0.77;
  cld = .007;
  clf = .02;
  co=tt(pp, true);
  
  float pos = sin(time*1.1);
  pp = vec3(pp.x + 0.2*pos, pp.y - 0.2*pos, pp.z - 0.4*pos);
  ct = time + abs(sin(time*0.5)) + 2.55;
  cs = 1.2;
  cbs = 0.075;
  cls = 0.37;
  cld = .01;
  clf = .015;
  result=min(tt(pp, true), co);
  int index = result < co ? 1 : 0;
    
  pos = sin(time*.7);
  pp = vec3(pp.x - 0.15*pos, pp.y + 0.15*pos, pp.z + 0.3*pos);
  ct = time + abs(sin(time*0.2)) + 2.55;
  cs = 1.2;
  cbs = 0.05;
  cls = 0.34;
  cld = .01;
  clf = .015;
  co=min(tt(pp, true), result);
  index = co < result ? 1 : index;
    
  pos = sin(time*.5);
  pp = vec3(pp.x - .2*pos, pp.y - 0.1*pos, pp.z + 0.2*pos);
  ct = time + abs(sin(time*0.7)) + 2.55;
  cs = 1.2;
  cbs = 0.05;
  cls = 0.27;
  cld = .01;
  clf = .015;
  result=min(tt(pp, true), co);
  index = result < co ? 1 : index;
  
  pp = vec3(pp.x - 0.2*pos, pp.y -0.1 *pos , pp.z);
  ct = time-3.;
  cs = 1.8;
  cbs = 0.25;
  cls = 0.67;
  cld = .007;
  clf = .5;
  co=min(tt(pp, false), result);
  index = co < result ? 2 : index;
  
  Information info;
  info.d = co*(index==2?.2:.7);;
  info.i = index;
  
  return info;
}

vec3 march(vec3 from, vec3 dir) {
  vec2 uv=vec2(atan(dir.x,dir.y)+time*.5,length(dir.xy)+sin(time*.2));
  vec3 col=vec3(0,0,0);
  float d=0.,td=0.,g=0., ltd=0.;
  Information info;
  vec3 p=from;
  int i;
  for (int it=0;it<100; it++) {
    p+=dir*d;
    info=de(p);
    d=info.d;
    if (d<det)
    {
        i = info.i;
        break;
    }
    if(td>5.)
    {
        i = 4;
        break;
    }
        
    td+=d;
    g+=.1/(br*40.0);
  }

  const vec3 nC = vec3(0.0,0.0,0.0);
  const vec3 nH = vec3(0.5,0.25,0.5);
  const vec3 c0 = vec3(0.25,0.45,0.75);
  const vec3 c1 = vec3(0.65,0.55,0.25);
  const vec3 c2 = vec3(0.75,0.25,0.25);
  const vec3 c4 = vec3(2.0,1.0,2.0);
  vec3 color = (i==0?c0:nC)+(i==1?c1:nC)+(i==2?c2:nC);
  
  vec3 glo=g*(.5+so)*.15*(i==4?c4:nH) + color*(1.+.5*st);
  glo.rb*=rot(dir.y*1.5);
  col+=glo;
  col*=vec3(.8,.7,.7);
  return col;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
  float t=time;
  vec3 from= path(t);
  sphpos=path(t+.5);
  from.z-=2.2;
  vec3 fw=normalize(path(t+.5)-(from));
  vec3 up=vec3(fw.x*2.,1.,0.);
  vec3 dir=normalize(vec3(uv,1.));
  dir=lookat(fw,up)*dir;
  float timeFactor = 2.0f;
  vec3 col=march(from,dir);
  glFragColor =vec4(col,1.);
}

