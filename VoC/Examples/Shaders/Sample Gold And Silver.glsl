#version 420

// original https://www.shadertoy.com/view/tss3Rs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Shader coded live on twitch (https://www.twitch.tv/nusan_fx)
You can disable the FRINGE effect with the define below.
You can also lower the STEPS if too slow
*/
                             
#define FRINGE 1
#define STEPS 100

#define time (time*0.3)
//float time = texture(texFFTIntegrated, 0.01).x*0.2;

float sph(vec3 p, float r) {
  return length(p)-r;
}

float cyl(vec2 p, float r) {
  return length(p)-r;
}

float box(vec3 p, vec3 r) {
  vec3 ap=abs(p)-r;
  return length(max(vec3(0), ap)) + min(0.0, max(ap.x,max(ap.y,ap.z)));
}

mat2 rot(float a) {
  float ca=cos(a);  
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float smin(float a, float b, float h) {
  float k=clamp((a-b)/h*0.5+0.5,0.0,1.0);
  return mix(a,b,k) - k*(1.0-k)*h;
}

float rnd(float t) {
  return fract(sin(t*843.231)*8631.1423);
}

float curve(float t, float d) {
  float g=t/d;
  return mix(rnd(floor(g)), rnd(floor(g)+1.0), pow(smoothstep(0.0,1.0,fract(g)),10.0));
}

float mat=0.0;

float map(vec3 p) {

  vec3 bp=p;

  float t = time*0.17;

  for(int i=0; i<5; ++i) {
    float t1 = curve(t+float(i)*0.42,0.4) * 2.0;
    p-=0.1+0.1*float(i)+t1*0.1;
    p.xy *= rot(t1*0.7);
    p.yz *= rot(t1);
    p=abs(p);
    p-=0.2;
  }
  vec3 rp=p;

  float t1 = curve(t+98.7424,0.7) * 3.0;
  p-=0.3 - t1*.1;
  p.xy *= rot(t1*0.7);
  p.yz *= rot(t1);
  p-=0.2;

  float trans=box(rp, vec3(0.5));
  float opa=box(p, vec3(0.05+curve(time, 1.2)*0.2));
  opa = min(opa, cyl(rp.xy,0.05));
  opa = smin(opa, sph(bp, 7.0), -3.0);
  //opa = 10000;

  
  trans = max(trans, -opa+.02);
  opa = max(opa, -trans+.02);

  mat=0.0;
  if(trans>opa) mat=1.0;

  return min(trans, opa);
}

vec3 norm(vec3 p) {
  vec2 off=vec2(0.01,0);
  return normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
}

void cam(inout vec3 p) {
  float t1=time*0.3 + curve(time, 0.7)*3.0;
  p.zx *= rot(t1);
  p.zy *= rot(t1*1.2);
}

vec3 ref(vec3 r) {
  float px = pow(1.0-abs(fract(abs(r.x)*10.0)-0.5)*2.0, 3.0);
  float py = pow(1.0-abs(fract(abs(r.y)*10.0)-0.5)*2.0, 3.0);
  vec3 col = vec3(1,0.8,0.2)*px;
  //col = mix(col, vec3(1,1.0,1.4)*0.7, py);
  return col*0.5;
}

vec2 mir(vec2 uv, float a) {
  uv *= rot(a);
  uv.x = abs(uv.x);
  return uv;
}

vec4 color(vec2 uv)
{
  float fsize=1.0;
  #if FRINGE
      float fringe = fract(floor(gl_FragCoord.y/fsize)*fsize/3.0);
      vec3 fcol = 1.0-abs(fringe*3.0-vec3(0,1,2));
      fcol = mix(fcol, vec3(1), 0.5);
  #else
    float fringe = 0.5;
    vec3 fcol=vec3(0.8);
  #endif
  float cx = (curve(time, 0.7)-0.5)*7.0;
  float cy = (curve(time, 0.8)-0.5)*3.0;

  vec3 s=vec3(cx,cy,-10);
  vec3 r=normalize(vec3(-uv,0.6 + curve(time, 0.3)));

  cam(s);
  cam(r);

  vec3 col = vec3(0);

  vec3 p=s;
  float dd=0.0;
  float side=sign(map(p));
  vec3 prod = vec3(1.0);
  int i=0;
  for(i=0; i<STEPS; ++i) {
    float d=map(p)*side;
    if(d<0.001) {
      
      vec3 n=norm(p)*side;
      vec3 l = normalize(vec3(-1));

      if(dot(l,n)<0.0) l=-l;

      vec3 h = normalize(l-r);

      float opa = mat;
      vec3 diff=mix(vec3(1), vec3(1,0.8,0.2), mat);
      vec3 diff2=mix(vec3(1), vec3(1,0.7,0.0), mat);
      float spec=mix(0.2, 1.5, mat);
      float fresnel = pow(1.0-max(0.0,dot(n,-r)),5.0);
      
      col += max(0.0, dot(n,l)) * (spec*(pow(max(0.0,dot(n,h)),50.0) * 0.5 + 0.5*diff2*pow(max(0.0,dot(n,h)),12.0)  )) * diff * prod;
      
      vec3 back = ref(reflect(r,n))*0.5*fresnel;
      col += back;

      side = -side;
      d = 0.01;
      r = refract(r,n,1.0 - 0.05*side*(0.5+0.5*fringe));
      prod *= fcol*0.9;
      if(opa>0.5) {
        /*vec3 back = ref(r)*1.0*fresnel;
        col = mix(col, back, prod);*/
        prod=vec3(0);
        break;
      }
    }
    if(dd>100.0) {
      dd=100.0;
      break;
    }
    p+=r*d;
    dd+=d;
  }
  if(i>99) {
    prod=vec3(0);
  }

  vec3 back = ref(r);
  col = mix(col, back, prod);
  //col *= 3;

  //col *= 3*pow(1-length(uv),0.7);
  vec2 auv = abs(uv)-vec2(0.5,0.0);
  col *= vec3(2.0*pow(1.0-clamp(pow(length(max(vec2(0),auv)),3.0),0.0,1.0),10.0));

  #if 1
    col = smoothstep(0.0,1.0,col);
    col = pow(col, vec3(0.4545));
  #endif
  
  //col = vec3( step(curve(uv.x, 0.04), uv.y*5) );
  //col = fcol;

  return vec4(col,1);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

  vec4 col = color(uv);

  glFragColor = vec4(col.xyz, 1);
}
