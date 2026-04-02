#version 420

// original https://www.shadertoy.com/view/Wd2Gzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Shader coded live on twitch (https://www.twitch.tv/nusan_fx)
You can disable the BLUR effect at the top.
You can also lower the STEPS or the QUALITY if too slow

The blur effect has been added after the stream, and floor texture has been moved from SDF to "normal map" to gain framerate.
*/
            

#define BLUR 1
#define STEPS 80
#define QUALITY 4

#define time time

float sph(vec3 p, float r) {
  return length(p) - r;
}

float cyl(vec2 p, float r) {
  return length(p) - r;
}

float box(vec3 p, vec3 s) {
  vec3 ap=abs(p)-s;
  return length(max(vec3(0.0), ap)) + min(0.0, max(ap.x,max(ap.y,ap.z)));
}

float box(vec2 p, float s) {
  vec2 ap=abs(p)-s;
  return length(max(vec2(0.0), ap)) + min(0.0, max(ap.x,ap.y));
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
  return fract(sin(t*732.496)*5653.352);
}

vec3 rnd(vec3 t) {
  return fract(sin(t*732.496)*5653.352);
}

float csize = 15.0;

float mat = 0.0;
float at = 0.0;
float map(vec3 p) {

  p.y = abs(p.y+5.0)-10.0;

  float d = 10000.0f;
  for(int i=0; i<QUALITY; ++i) {
    vec3 off = float(i)*vec3(0.3,0.0,0.7);
    vec3 size = vec3(2.0+float(i)*0.1);
    vec3 rotp = p;
    float t1 = float(i)+0.2;
    rotp.xy *= rot(t1);
    rotp.yz *= rot(t1*0.7);
    vec3 rp = (fract((rotp-off)/size-0.5)-0.5)*size;
    float s = box(rp, vec3(0.5,1.0,0.3)*2.0);
    d = min(d, s);
  }

  vec3 cp = p;
  
  cp.xz = (fract((cp.xz)/csize-0.5)-0.5)*csize;

  float f2 = 0.3;
  //f2 = texture(texNoise, p.xz * 0.05).x;
  float f = 0.5-p.y + f2 * 2.0;

  //d = smin(d, f*5-5, -5.0);
  d = smin(d, cyl(cp.xz, 5.0), -3.0);

  d = smin(d, -30.0-p.y, -30.0);
 
  d = min(d, cyl(cp.xz,1.0));
  

  d = max(d,0.1-f);
  //if(d<0) {
    at += 0.5 * abs(d) * max(0.5-d,0.0);
  //}
  

  mat = d<f?1.0:0.0;
  return min(d, f);
}

vec3 norm(vec3 p) {
  vec2 off=vec2(0.01, 0);
  return normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
}

vec3 floornorm(vec2 p) {
  vec2 off=vec2(0.005, 0);
  float center=0.0;//texture(iChannel0, p).x;
  return vec3(0.0);//-normalize(vec3(center - texture(iChannel0, p-off.xy).x, 0.3, center - texture(iChannel0, p-off.yx).x));
}

vec3 fog(vec3 r, float dd) {
  return vec3(0.5,0.3,1) * 0.02 * exp(dd*0.06);
}

void main(void)
{
  vec2 uv = gl_FragCoord.xy/resolution.xy;
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

  float loop=0.2;
  float t1 = 0.4*fract(time*loop)/loop + rnd(floor(time*loop))*175.532;

  vec3 motion = vec3(0);
  motion.z += t1*10.0;

  vec3 s=vec3(0,-7.0,-6);
  s.xz *= rot(t1*0.7);
  s.xz -= 2.0;
  s.xz *= rot(t1*0.3);
  s += motion;
  vec3 t=vec3(0.0,-6.0 - sin(t1*0.8)*2.0,0) + motion;
  vec3 cz = normalize(t-s);
  vec3 cx = normalize(cross(cz, vec3(0,1,0)));
  vec3 cy = normalize(cross(cz,cx));
  //vec3 r=normalize(vec3(-uv, 1));
  vec3 r=normalize(uv.x*cx + uv.y*cy + cz);

  vec3 col = vec3(0);

  vec3 l = normalize(-vec3(0.4,0.7,1.0));

  vec3 p=s;
  float dd=0.0;
  float side=sign(map(p));
  float prod=1.0;
  for(int i=0; i<STEPS; ++i) {
    float d=map(p) * side;
    if(d<0.001) {
      float curmat = mat;
      vec3 n=norm(p) * side;
      vec3 h=normalize(l-r);

      if(mat<0.5) n=floornorm(p.xz * 0.03);
      
      float curid = dot(floor((p.xz)/csize-0.5), vec2(0.3,1.5));
      vec3 crys = vec3(0.2, 0.4,0.7);
      float t2 = rnd(curid*124.453) * 12.75;
      crys.xy *= rot(t2);
      crys.yz *= rot(t2*0.7);
      crys = abs(crys);
      vec3 base = mix(vec3(1,0.7,0.5)*1.5, crys, mat);
      float spec = mix(0.1,1.0, mat);
      float dnh = max(0.0,dot(n,h));
      float f=pow(1.0-max(0.0,dot(n,-r)), 3.0);
      float sky = -n.y*0.5+0.5;
      col += at*crys*0.2;
      //col += sky * pow(f,0.8) * vec3(0.5,0.3,1) * 0.2 * base;
      col += max(0.0, dot(n, l)) * (0.2*f + 0.4*pow(dnh,spec*7.0) + 3.0*pow(dnh,spec*30.0)) * base * 30.0 / max(1.0,dd*dd);
      col += fog(r, dd) * prod;
      
      if(mat<0.5) break;
      //if(prod<0.1) break;

      side = -side;
      prod = 0.8;
      d = 0.03;
      r = refract(r,n, 1.0+side*0.05);
#if BLUR
      vec3 blur = normalize(rnd(p)-0.5)*.01;
      r += blur;
#endif
    }
    if(dd>100.0) {
      dd=100.0;
      break;
    }
    p+=r*d;
    dd+=d;
  }
  col += fog(r, dd) * prod;

  //col = pow(col, vec3(0.4545));

  glFragColor = vec4(col, 1);
}
