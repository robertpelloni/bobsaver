#version 420

// original https://www.shadertoy.com/view/tssXzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Shader coded live on twitch (https://www.twitch.tv/nusan_fx)
You can lower the MARCH_STEPS if too slow, or put CURLYHAIR to 0

The shader was made using Bonzomatic.
You can find the original shader here: http://lezanu.fr/LiveCode/ScaryHairy.glsl
*/

#define MARCH_STEPS 100
#define CURLYHAIR 1

#define time time

float PI = acos(-1.0);

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float smin(float a, float b, float h) {

  float k=clamp((a-b)/h*0.5+0.5,0.0,1.0);
  return mix(a,b,k)-k*(1.0-k)*h;
}

vec3 rotrep(vec3 p, float rep, float off) {
  vec2 rp=vec2(atan(p.z,p.x)/(2.0*PI), length(p.xz));
  rp.x = (fract(rp.x*rep-0.5+off)-0.5)/rep;
  return vec3(cos(rp.x*2.0*PI)*rp.y,p.y,sin(rp.x*2.0*PI)*rp.y);
}

float rotid(vec3 p, float rep, float off) {
  vec2 rp=vec2(atan(p.z,p.x)/(2.0*PI), length(p.xz));
  return floor(rp.x*rep-0.5+off);
}

vec3 tmin(vec3 a, vec3 b) {
  return a.x<b.x?a:b;
}

vec3 curly(vec3 p, float hole, float freq, float offset) {

  
  vec3 rp = rotrep(p, freq, offset);
  float off = fract(sin(rotid(p, 30.0, 0.0)*780.4)*7842.25)*12.0;
  
  rp.xz *= rot(sin(rp.y*10.0+off)*0.01);

  vec3 dp = p;
  dp.y = max(-dp.y, 0.0);
  float dec = 1.0-length(normalize(dp).xz);
  float wid = 1.1 + sin(p.y*5.0+off*42.57)*0.3;
    
  vec3 cyl = vec3(length(rp.xz-vec2((1.0-dec)*1.49,0.0))-0.1*wid,atan(rp.z,rp.x)*1.0,rp.y);
  cyl.x = smin(cyl.x, -1.85-p.y, -0.8);
  cyl.x = smin(cyl.x, -5.9+p.y, -4.8);
  cyl.x = smin(cyl.x, -hole,-.7);

  return cyl;

}

vec3 hairbase(vec3 p, float r) {
  vec3 lp = p;
  lp.y = max(0.0,-lp.y);

  
  float edge = atan(p.z,p.x)/(2.0*PI);
/*
  p.x += sin(edge*3)*.1;
  //p.x -= sin(p.y*6.8)*.1;
  p.y += sin(p.x*30)*.01;
  p.y += sin(p.z*13)*.03;
*/
  float sp = length(lp)-r;
  float d = abs(sp)-0.05;
  
  
  vec3 ph = p;
  ph.y = max(0.0,0.8-ph.y);
  float hole = (length(ph.xy)-0.5);
  hole = max(hole, p.z);
  
  d = smin(d,-1.9+p.y + (sin(edge*50.0)+sin(edge*108.0)*0.5+sin(edge*138.0)*0.45)*0.3, -.3);

  d = smin(d,-hole,-.9);

  vec3 res = vec3(d, atan(p.z,p.x), p.y/r);
#if CURLYHAIR
  res = tmin(res, curly(p, hole, 15.0, 0.0));
  res = tmin(res, curly(p, hole, 35.0, 0.5));
  res = tmin(res, curly(p, hole, 13.0, 0.27));
#endif  
  return res;
}

float sph(vec3 p, float r) {
  return length(p)-r;
}

vec3 body(vec3 p) {

  vec3 cp2 = p;
  cp2.y += sin(cp2.x*PI*5.0)*0.1;
  cp2.x -= clamp(cp2.x,-0.3,0.3);  
  
  vec3 cp3 = p-vec3(-0.0,0.4,-1.5);
  cp3.y -= clamp(cp3.y,-0.1,0.1);  
  //cp3.yz *= rot(-0.2);
  
  p.x = smin(p.x, -p.x, 0.3);
  
  float b1 = sph(p,1.5);
  b1 = smin(b1, sph(p-vec3(0,1,-0.3),1.2), 0.5);
  b1 = smin(b1, -sph(p-vec3(-0.6,0.3,-1.8),0.4), -0.4);
  b1 = smin(b1, sph(p-vec3(-0.45,0.3,-1.2),0.15), 0.05);

  b1 = smin(b1, sph(p-vec3(-0.1,0.7,-1.6),0.1), 0.15);
  b1 = smin(b1, sph(cp3,0.1), 0.2);
  
  b1 = smin(b1, -sph(cp2-vec3(0.0,1.3,-1.3),0.1), -0.2);

  vec3 cp = p;
  cp.y -= clamp(cp.y-2.0,0.0,1.0);
  b1 = smin(b1, sph(cp-vec3(0,2,0.1),0.7), 0.2);
  return vec3( b1, 0, 0);
}

float mat = 0.0;
vec3 map(vec3 p) {
  vec3 h = hairbase(p, 1.5);
  vec3 b = body(p);
  mat=(b.x<h.x)?1.0:0.0;
  return tmin(h, b);
}

float mapx(vec3 p) {
  return map(p).x;
}

float mapz(vec3 p) {
  return map(p).z;
}

vec3 norm(vec3 p) {
  vec2 off=vec2(0.01,0);
  return normalize(mapx(p)-vec3(mapx(p-off.xyy), mapx(p-off.yxy), mapx(p-off.yyx)));
}

vec3 tangent(vec3 p) {
  vec2 off=vec2(0.01,0);
  return normalize(mapz(p)-vec3(mapz(p-off.xyy), mapz(p-off.yxy), mapz(p-off.yyx)));
}

float noise(vec2 uv) {
  vec2 iuv=floor(uv);
  vec2 fuv=fract(uv);
  fuv=smoothstep(0.0,1.0,fuv);
  vec2 st=vec2(7,877);
  vec2 m = dot(iuv,st)+vec2(0,st.y);
  vec2 val = mix(fract(sin(m)*7584.522), fract(sin(m+st.x)*7584.522), fuv.x);
  return mix(val.x,val.y, fuv.y);
}

float fractal(vec2 uv) {
  float d=0.0;
  for(int i=0; i<5; ++i) {
    float s=pow(2.0,float(i));
    d+=noise(uv*s)/s;
  } 
  return d*0.5;
}

void cam(inout vec3 p) {
  float t1=time*0.3;
  p.xz *= rot(t1);
  p.xy *= rot(sin(t1*1.3)*0.5);
  //p.yz *= rot(0.9);
  //p.xz *= rot(sin(time)*0.9);
}

float hair(vec3 tang, vec3 h, float power) {
  float cosang = dot(tang, h);
  float sinang = sqrt(1.0-cosang*cosang);
  float spechair = pow(sinang, power);
  return spechair;
}

vec3 light(vec3 l, vec3 p, vec3 r, vec3 n, vec2 tex, vec3 tang, float curmat) {
  float rand = fractal(tex*vec2(150,3));
  vec3 h = normalize(l-r);

  vec3 col = vec3(0);

  vec3 haircol = vec3(1,0.5,0.1);

  vec3 diff = haircol * 0.3;

  float aodist=0.2;
  float ao = clamp(mapx(p+n*aodist)/aodist,0.0,1.0);
  //ao = pow(ao, 3);

  if(curmat<0.5) {
    float spechair1 = hair(normalize(tang + n * (rand-0.3) * 1.0), h, 100.0);
    float spechair2 = hair(normalize(tang + n * (rand-0.7) * 1.0), h, 10.0);
    col = max(0.0, dot(n,l)*0.7+0.3) * (diff + spechair1 + spechair2 * haircol) * ao;
  } else {
  
    vec3 eyep = p;
    eyep.x=-abs(eyep.x);
    float disteye = sph(eyep-vec3(-0.45,0.3,-1.2),0.15);
    float eye = step(disteye, 0.03);

    float spec = pow(max(0.0,dot(n,h)),6.0);
    float spec2 = pow(max(0.0,dot(n,h)),50.0);

    
    if(eye>.0) {
      col = vec3(1)*max(0.0, dot(n,l)*0.7+0.3) * step(0.007,disteye);
    } else {
      float fade = clamp((-p.y+2.7)*1.0,0.0,1.0);
      col = max(0.0, dot(n,l)*0.7+0.3) * (vec3(1.0,0.7,0.5) * (1.0 + spec) + 0.2*spec2) * ao * fade;
    }
    
  }
  return col;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

  vec3 s = vec3(0.0,0.7,-5);
  vec3 r = normalize(vec3(-uv, 0.8+sin(time*0.7)*0.2));

  cam(s);
  cam(r);

  vec3 p=s;
  float dd=0.0;
  
  for(int i=0; i<MARCH_STEPS; ++i) {
    float d=mapx(p);
    if(d<0.001) {
      break;
    }
    if(dd>100.0) {
      dd=100.0;
      break;
    }
    p+=r*d*0.7;
    dd+=d*0.7;
  }
  float curmat = mat;

  vec3 n = norm(p);
  vec3 tang = tangent(p);
  vec3 bin = normalize(cross(n,tang));
  tang = normalize(cross(n,bin));

  vec2 tex = map(p).yz;

  float fog = 1.0-clamp(dd/100.0,0.0,1.0);

  vec3 col = vec3(0);

  vec3 l = normalize(vec3(-1));
  vec3 l2 = normalize(vec3(1.3,-0.7,0.5));
  vec3 l3 = normalize(vec3(0.7,-0.7,0.5));
  
  col += light(l, p, r, n, tex, tang, curmat) * fog;
  col += light(l2, p, r, n, tex, tang, curmat) * fog * vec3(0.7,0.5,0.8);
  //col += light(l3, p, r, n, tex, tang, curmat) * fog * vec3(0.3,0.7,0.5);
  
  
  //col = vec3(fractal(uv*10));

  glFragColor = vec4(col, 1);
}
