#version 420

// original https://www.shadertoy.com/view/3scGD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define TAU 2. * PI

vec3 lookAt (vec3 eye, vec3 at, vec2 uv) 
{
  vec3 forward = normalize(at - eye);
  vec3 right = normalize(cross(forward, vec3(0,1,0)));
  vec3 up = normalize(cross(right, forward));
  return normalize(forward + right * uv.x + up * uv.y);
}

vec2 modA(vec2 p, float r)
{
  float a = atan(p.y,p.x);

  a = mod(a + PI, TAU/r) - PI;

  return length(p) * vec2(cos(a),sin(a));
}
//----------
float smin(float a,float b,float k)
{
  float h=clamp(.5+.5*(b-a)/k,0.,1.);
  return mix(b,a,h)-k*h*(1.-h);
}
//-----------
mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

float ease(float t)
{
  return floor(t) + sin(fract(t) * PI - PI / 2.) * .5 + .5;
}

float map(vec3 p)
{
  float dist = 1000.;
  //------------
  vec3 cp=p;
  float ti=time;
 for(float i=1.;i<5.;++i)//  фон с фигуркой 5
 {
    cp.y+=time*.0315;// движение вверх p.y-, вниз p.y+
    cp.y+=(sin(ti+cp.x)+cos(ti+cp.z))*1.13;//  фигурка
    dist=smin(length(cp)-1.285,dist,1.25);//  слияние амплитуды фигурки
    ti+=i*.2;
    cp*=.99;// FOV фигурки  близко-далеко 1.1
    cp.xz*=rot(ti*.3);//  вращение по xz
    cp.yz*=rot(ti*.3);//  вращение по yz
    cp.x+=.6;
 }
 //-----------

  float ra = sin(p.y) * .55 + .45 + .2;// спираль по y
  p.y -= time;// движение вверх p.y-, вниз p.y+
  p.xz *= rot(p.y * .5);
  p.xz = modA(p.xz, 5.);//  количество 3.
  p.z += 3.;//  глубина по z
  p.x += 4.5;//  ширина по x
  float cy = length(p.xz) - ra;
  dist = min(dist, cy);
  
  return dist;
}

  float cd = 0.;
  vec3 outPos;
  float ray(vec3 cp, vec3 rd)
{
  float st = 0.;
  for(;st < 1.; st += 1./ 64.)
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += rd * cd * .5;
  }

  outPos = cp;
  return st;
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(.01,.0);

  return normalize(vec3(
  map(p - e.xyy) - map(p + e.xyy),
  map(p - e.yxy) - map(p + e.yxy),
  map(p - e.yyx) - map(p + e.yyx)
  ));
}

void main(void)
{
  vec2 uv=vec2(gl_FragCoord.x/resolution.x,gl_FragCoord.y/resolution.y);
  uv-=.5;
  uv/=vec2(resolution.y/resolution.x,1);
  
 //----------------
 vec3 eye = vec3(0.,0.,-20.);
 vec3 rd = lookAt(eye, vec3(0.), uv);
 vec3 cp = eye;
 float st = ray(cp,rd);
 vec3 norm = normal(outPos);
 vec3 ld=normalize(vec3(-.5,-1.,1.));
 ld.xz*=rot(time*.1);
 float li = dot(norm, vec3(-1.,-1.,1.));// с какой стороны свет
 float li2=dot(normalize(vec3(1.,0.,1.)),norm);//  свет 2
 float f=pow(max(li,li2),2.);
 f=sqrt(f);
 vec4 col=vec4(norm,0.);
 col.xy*=rot(time*.5);
 col.yz*=rot(time*.75);
 col.xz*=rot(time*.125);
 col=abs(col);
 vec4 out_color=vec4(1.);
 out_color=mix(vec4(0.),col*1.5,f);
 glFragColor=vec4(out_color);
 //-----------
}
