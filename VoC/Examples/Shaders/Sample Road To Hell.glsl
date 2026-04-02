#version 420

// original https://www.shadertoy.com/view/Wst3Wn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float obj(vec3 p)
{
  vec3 pp = p;
  pp.z = mod(p.x, 110.)-55.;//  структура
  float d=  -abs(p.x-1.)+63.;
  return d;
}

float obj2(vec3 p)
{
  float d = length(p.xy-vec2(1.+cos(p.z),0.+sin(p.z)))-.21;//  толщина спирали  .21
  return d;
}

float map(vec3 p)
{
  float d = dot(cos(p.xyz), sin(p.zxy))+1.;
  d += cos(p.z*10.)*.1;
  d = min(d, obj(p));
  d = min(d, obj2(p));

  return d*.8;//  глубина .8
}

vec3 normal(vec3 p)
{
  vec3 n;
  vec2 eps = vec2(0.01,0.);
  n.x = map(p) - map(p+eps.xyy);
  n.y = map(p) - map(p+eps.yxy);
  n.z = map(p) - map(p+eps.yyx);

  return normalize(n);
}

mat2 rotate(float v)
{
  float a = cos(v);
  float b = sin(v);
  return mat2(a,b,-b,a);
}

vec3 raymarch(vec3 ro, vec3 rd)
{
  vec3 p = ro;

  for(int i=0; i<64; i++)
  {
    float d = map(p);
    p += rd * d;
  }

  return p;
}

vec3 shade( vec3 ro, vec3 rd, vec3 p, vec3 n)//  color
{
  vec3 ld = normalize(vec3(.1,1.,-.5));
  vec3 col = vec3(0.);

  col = vec3(1.) * max(0., dot(n,ld))*.43;//                              яркость белого света .3
  col+=mix(vec3(0.7882, 0.098, 0.1529),vec3(0.0902, 0.8196, 1.0),rd.y)*length(p-ro)*.05;//  цвет градиента по rd.y

  return col;
}

void main(void)
{
  vec2 uv=vec2(gl_FragCoord.x/resolution.x,gl_FragCoord.y/resolution.y);
  uv-=.5;
  uv/=vec2(resolution.y/resolution.x,1);
  
    vec3 ro = vec3(1.,0.,-time);//  -time туда, +time обратно
    vec3 rd = normalize(vec3(uv*2.,-1.));//  uv*2 растянуть, -1. расширить
    vec3 p = raymarch(ro,rd);//  рэймарш
    vec3 n = normal(p);
    vec3 col = shade(ro, rd, p, n);//  цвет градиента и свет

  vec4 out_color=vec4(1.);
  out_color = vec4(col, 1.);
  glFragColor=vec4(out_color);
}
