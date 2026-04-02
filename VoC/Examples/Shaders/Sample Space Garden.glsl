#version 420

// original https://www.shadertoy.com/view/stSGRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define fs(i) (fract(sin(i*114.514)*1919.810))
#define lofi(i,j) (floor((i)/(j))*(j))

float seed;

const float PI=acos(-1.);
const float TAU=PI*2.;

// Pinieon !!!!!!!!

float random(){
  seed=fs(seed+1.);
  return seed;
}

vec3 randomSphere(){
  float phi=TAU*random();
  float theta=acos(random()*2.-1.);
  return vec3(cos(phi)*sin(theta),sin(phi)*sin(theta),cos(theta));
}

vec3 randomHemisphere(vec3 n){
  vec3 d=randomSphere();
  return dot(d,n)<0.0?-d:d;
}

mat2 r2d(float t){
  return mat2(cos(t),sin(t),-sin(t),cos(t));
}

float sdbox(vec3 p,vec3 s){
  vec3 d=abs(p)-s;
  return min(0.,max(d.x,max(d.y,d.z)))+length(max(d,vec3(0.0)));
}

float ease(float t){
  return 0.5+0.5*cos(PI*exp(-t*5.));
}

mat3 orthBas(vec3 z){
  z=normalize(z);
  vec3 up=abs(z.y)>.99?vec3(0,0,1):vec3(0,1,0);
  vec3 x=normalize(cross(up,z));
  return mat3(x,cross(z,x),z);
}

vec3 ifs(vec3 p,vec3 rot,vec3 s){
  mat3 b=orthBas(rot);
  for(int i=0;i<6;i++){
    s*=b;
    s*=0.56;
    p=abs(p)-abs(s);
    p.xy=p.x<p.y?p.yx:p.xy;
    p.yz=p.y<p.z?p.zy:p.yz;
  }
  return p;
}

vec3 noise(vec3 p,vec3 bas,float pump){
  mat3 b=orthBas(bas);
  vec4 sum=vec4(0);
  float warp=1.1;
  for(int i=0;i<5;i++){
    p*=b;
    p*=2.0;
    p+=sin(p.yzx);
    sum+=vec4(cross(sin(p.zxy),cos(p)),1);
    sum*=pump;
    warp*=1.3;
  }
  return sum.xyz/sum.w;
}

vec4 map(vec3 p){
  vec3 pt=p;
  pt.zx=r2d(time*.1)*pt.zx;
  pt.z-=.1*time;
  vec3 cell=lofi(pt,2.0)+1.0;
  pt-=cell;
  float heck=abs(pt.x)+abs(pt.y)+abs(pt.z);
  float clampbox=sdbox(pt,vec3(0.8));
  float ph=0.5*time+0.2*(cell.x+cell.y+cell.z);
  vec3 rot=mix(
    fs(vec3(1.4,2.1,3.5)+floor(ph)),
    fs(vec3(1.4,2.1,3.5)+floor(ph+1.)),
    ease(fract(ph))
  );
  vec3 sh=1.0+0.2*mix(
    fs(vec3(2.4,3.1,1.5)+floor(ph)),
    fs(vec3(2.4,3.1,1.5)+floor(ph+1.)),
    ease(fract(ph))
  );
  pt=ifs(pt,rot,sh);
  float d=sdbox(pt,vec3(.04));
  d=max(d,clampbox);
  //d+=0.002*noise(2.0*p,vec3(1),2.0).x;

  return vec4(d,1,min(abs(pt.x),abs(pt.z)),0);
}

vec3 nmap(vec3 p,vec2 d){
  return normalize(vec3(
    map(p+d.yxx).x-map(p-d.yxx).x,
    map(p+d.xyx).x-map(p-d.xyx).x,
    map(p+d.xxy).x-map(p-d.xxy).x
  ));
}

float aomap(vec3 p,vec3 n){
  float accum=0.0;
  for(int i=0;i<30;i++){
    vec3 pt=p+n*random()*randomHemisphere(n);
    float d=map(pt).x;
    accum+=smoothstep(0.0,-0.02,d)/30.0;
  }
  return 1.0-sqrt(accum);
}

void main(void) {
  vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
  vec2 p=uv*2.-1.;
  p.x*=resolution.x/resolution.y;
  
  //seed+=texture(iChannel0,8.0*uv).x;
  seed+=fract(time);
  
  float time2=time+0.02*random();

  vec3 ro=vec3(0,0,2);
  vec3 rd=normalize(vec3(p,-1.+.4*length(p)));
  rd.xy=r2d(time2*.1)*rd.xy;
  
  vec3 col=vec3(0);
  vec3 colRem=vec3(1);

  for(int iR=0;iR<2;iR++){
    float rl=1E-2;
    vec3 rp=ro+rd*rl;
    vec4 isect;
    
    for(int i=0;i<128;i++){
      isect=map(rp);
      rl+=isect.x*.6;
      rp=ro+rd*rl;
      
      if(abs(isect.x)<1E-3){break;}
    }
    
    float fog=exp(-0.04*rl);
    vec3 haha=0.5+0.5*sin(-2.0+3.0*exp(-rl)+vec3(0,2,4));
    haha+=vec3(0.2,0.5,1.1);
    col+=colRem*(1.0-fog)*4.0*haha;
    vec3 n=nmap(rp,vec2(0,1E-3));
    float f=1.0-clamp(dot(-rd,n),0.,1.);
    f=f*f*f*f*f;
    col+=colRem*f*4.0*haha;
    
    if(abs(isect.x)<1E-3){
      float ao=aomap(rp,n);
      col+=0.2*colRem*fog*vec3(ao);
      col+=vec3(0.1,1.0,0.2)*colRem*fog*smoothstep(0.001,0.0005,isect.z);
      colRem*=0.1+0.9*f;
      
      ro=rp+n*1E-2;
      rd=reflect(rd,n);
    }else{
      break;
    }
  }
  
  col=pow(col,vec3(.4545));
  col*=1.-length(p)*.3;
  col=vec3(
    smoothstep(0.04,0.92,col.x),
    smoothstep(-0.08,0.97,col.y),
    smoothstep(-0.2,1.03,col.z)
  );

  glFragColor = vec4(col,1);
}
