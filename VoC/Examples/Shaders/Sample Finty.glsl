#version 420

// original https://www.shadertoy.com/view/tdcGRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float o(vec3 p)
{
  return cos(p.x) + cos(p.y*.5) + cos(p.z) + cos(p.y*20. + time)*.1;//  бочки в небе
}

float water( vec3 p)
{
  float d = p.y;// + texture(iChannel1, p.xz*.1+vec2(time*.01)).r*.1;//+ texture(iChannel1, p.xz*.1-vec2(time*.05)).r*.1;//вода
  d = min(d, mix(length(p-vec3(0.,1.,time+2.5)) - 1., length(p.xy-vec2(sin(p.z),1.+cos(p.z))) - .5, cos(time)*.45+.5));//финтифлюшка
  return d;
}

float map( vec3 p)
{
  float d = min(o(p), water(p));
  return d;
}

vec3 rm( vec3 ro ,vec3 rd)
{
  vec3 p = ro;
  for(int i=0; i<64; i++)
  {
    float d = map(p);
  p += rd *d;
  }
return p;
}

vec3 normal( vec3 p)
{
  vec2 eps = vec2(0.01, 0.);
  vec3 n;
  n.x = map(p) - map(p+eps.xyy);
  n.y = map(p) - map(p+eps.yxy);
  n.z = map(p) - map(p+eps.yyx);
  return normalize(n);
}

vec3 shade( vec3 ro, vec3 rd, vec3 n, vec3 p)
{
  vec3 col = vec3(0.);
  col += vec3(1.) * max(0., dot(n, normalize(vec3(1.,1.,1.))))*.5;
  vec3 fog = mix(vec3(cos(time)*.5+.5, .7, .5), vec3(0.,.7,1.5), rd.x) * (length(p-ro)*.05 );;

  col += fog;
  return col;
}

mat2 rot( float v)
{
  float a = 1.;
  float b = sin(v)*0.1;
  return mat2( a,-b,b,a);
}
void main(void)
{
  vec2 uv=vec2(gl_FragCoord.x/resolution.x,gl_FragCoord.y/resolution.y);
uv-=.5;
uv/=vec2(resolution.y/resolution.x,1);

  vec3 ro = vec3( 0., 1., time);
  vec3 rd = normalize( vec3(uv, 1.) );
  rd.xy = rot(time*.91) * rd.xy;
  vec3 p = rm(ro ,rd);
vec3 n = normal(p);

  vec3 col = shade(ro,rd,n,p);
  for(int i=0; i<3; i++)
  if(water(p)<.1)
  {
    rd = reflect(  rd, n);
    p += rd*.1;
  ro = p;
    p = rm(ro,rd);
    n = normal(p);
    col = vec3(0.5,.47,1.) * shade(ro,rd,n,p);
  }
  vec4 out_color=vec4(1.);
  out_color=vec4(col,1.);
  glFragColor=vec4(out_color);
}
