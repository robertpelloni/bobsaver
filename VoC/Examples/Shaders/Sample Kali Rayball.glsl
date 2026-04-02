#version 420

// original https://www.shadertoy.com/view/dtsXDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float maxdist=20.;
const float det=.001;
const vec3 dirlight = vec3(1.,-2.,-1.);
float obj_id;
float on=1.;
vec3 pos,objpos;

mat2 rot(float a){
float c=cos(a),s=sin(a);
return mat2(c,s,-s,c);
}
float sphere(vec3 p, float radio) {
  return length(p)-radio;  
}

vec3 path(float t)
{
  vec3 p=vec3(sin(t+cos(t*1.35)),cos(t*.8564)*.25,cos(t*.4537)+.5)*6.;
  return p;
}

float obj(vec3 p) {
  float d=sphere(p,1.5)-length(sin(p*3.+time))*.55;
  d=max(d,-length(p)+2.15);
  d=max(d,length(p)-2.25);
  obj_id=1.;
  return d*.5+length(fract(p*10.))*.02;
}

float de(vec3 p) {
  vec3 po=p-objpos;
  vec3 p1=po,p2=po;
  p1.yz*=rot(time);
  p1.xz*=rot(time*.5);
  float ob3=obj(p1/1.5)*1.5;
  float ob1=min(obj(p1*1.5),ob3);
  p2.xy*=rot(time*5.);
  p2.xz*=rot(time*3.);
  float ob2=obj(p2/1.3)/1.3;
  float d=min(ob1,ob2);
  p1/=length(po)*.2;
  float lu=1000.;
  lu=min(lu,length(p1.xz-sin(p.y*3.)*length(p1)*.1)-sin(p1.y*10.+time*50.)*.1);
  lu=min(lu,length(p1.xy-sin(p.z*3.)*length(p1)*.1)-sin(p1.z*10.+time*50.)*.1);
  lu=min(lu,length(po)-1.);
  lu=min(lu,(length(fract(p*.2)-.5)-.01)*5.);
  d=min(d,lu);
  if (d==ob1) {
    pos=p1;
    obj_id=1.;    
  }
  if (d==ob2) {
    pos=p2;    
    obj_id=2.;    
  }
  if (d==lu) obj_id=3.;
  //pos=p;
  return d*.5;
}

vec3 normal(vec3 p) {
  vec3 e = vec3(0.,det*2.,0.);
  return normalize(vec3(de(p-e.yxx),de(p-e.xyx),de(p-e.xxy))-de(p));
}

float is_id(float id) {
  return 1.-step(.1,abs(id-obj_id));
}

vec3 color() {
  vec3 col=vec3(0.);
  vec3 text=1.-abs(fract(pos*6.+vec3(0.,sin(pos.x*10.+time*5.)*.5,time*2.))-.5);
  text=smoothstep(1.4,1.5,length(sin(pos*10.)))*vec3(2.,.8,3.)+.2;
  col+=text*is_id(1.);
  col+=vec3(2.,0.,3.)*is_id(2.);
  col+=vec3(1.,.0,1.)*is_id(3.)*3.;
  return col;
}

vec3 light(vec3 p, vec3 dir, vec3 n, vec3 col) {
  vec3 ldir=normalize(-p);
  float amb=.2;
  float diff=max(0.,dot(ldir,-n))*2.0*on;
  vec3 ref=reflect(dir,-n);
  float spec=pow(max(0.,dot(ldir,ref)),10.)*1.7*on;
  return col*(amb+diff)+spec*vec3(1,0,1);
}

vec3 march(vec3 from, vec3 dir) {
  vec3 p, col=vec3(0.), backcol=vec3(0.);
  float totdist=0.,d,g=0.;
  for (int i=0; i<180; i++) {
    p=from+dir*totdist;
    d=de(p);
    totdist+=d;
    if (d<det || totdist>maxdist) {
      break;
    }
    g+=.1/(.1+d*.5)*(is_id(3.));
  }
  if (d<det) {
    p-=det*dir*2.;
    vec3 obj_col=color();
    vec3 n=normal(p);
    col=light(p,dir,n,obj_col);
  } else {
    totdist=maxdist;
    p=from+dir*maxdist;
  }
  backcol=vec3(.8,.9,1.)*(1.-.7*smoothstep(0.,10.,-p.y-.5));
  vec2 uv=gl_FragCoord.xy/resolution.xy-.5;
  uv.x*=resolution.x/resolution.y;
  backcol=abs(sin(dir+time*2.))*.5*smoothstep(1.,.0,length(uv));
  backcol.rb*=rot(time);
  backcol.g*=.2;
  float depth = 1.-(maxdist-totdist)/maxdist;
  col=mix(col,backcol,pow(depth,.5));
  col+=g*.1*on*vec3(2,0,3)*exp(-1.5*depth);
  return col;
}

mat3 lookat(vec3 dir,vec3 up){
    dir=normalize(dir);vec3 rt=normalize(cross(dir,normalize(up)));
    return mat3(rt,cross(rt,dir),dir);
}

void main(void)
{
  float t=time;
  on=fract(t*6.);
  vec2 uv = gl_FragCoord.xy/resolution.xy-.5;
  uv.x*=resolution.x/resolution.y;
  uv*=rot(time);
  vec3 dir = normalize(vec3(uv,.5));
  vec3 from = vec3(0.,0.,-5.);
  from=path(t);
  objpos=vec3(tan(time*.5)*2.,cos(time)*5.,sin(time)*8.);
  vec3 target = objpos;
  vec3 to = normalize(target-from);
  dir.x+=to.y*.5;
  dir=lookat(target-from,vec3(0.,1.,0.))*dir;
  vec3 col=march(from, dir);
  glFragColor = vec4(col,1.);
}
