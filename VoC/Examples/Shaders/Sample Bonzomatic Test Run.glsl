#version 420

// original https://www.shadertoy.com/view/WtSXRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 rep(vec3 p, vec3 q)
{
  return mod(p,q)-0.5*q;
}

float box(vec3 p, vec3 q)
{
  vec3 d = abs(p)-q;
  return length(max(d,0.0));
}

float sphere(vec3 p, float r)
{
  return length(p)-r;
}

vec2 cmin(vec2 a, vec2 b)
{
  return a.x < b.x ?a:b;
}

vec2 dist(vec3 p)
{
  vec2 s =vec2(sphere(p+vec3(0.,0.,-3.),0.3),0.);
  
  vec3 id = vec3(p.x/1.,(p.y/2.),(p.z/2.));
  p = rep(p+vec3(0.5+sin(id.z+id.y), sin(id.y)*4.,cos(id.z)*2.),vec3(6.,2.,2.));
  vec2 b = vec2(box(p+vec3(0.0), vec3(0.8)),id.x+id.y);
  
  vec2 sum =cmin(s,b);
  return b;
}
vec3 light(vec3 rd,vec3 p)
{
  vec2 eps=vec2(0.,0.1);
  vec2 d1 = dist(p+eps.yxx);
  vec2 d2 = dist(p-eps.yxx);
  vec2 d3 = dist(p+eps.xyx);
  vec2 d4 = dist(p-eps.xyx);
  vec2 d5 = dist(p+eps.xxy);
  vec2 d6 = dist(p-eps.xxy);
  
  vec3 n = normalize( vec3(d1.x-d2.x, d3.x-d4.x, d5.x-d6.x));
  
  float m =max(0.,dot(-rd,n));
  vec3 di = vec3(m);
  di = vec3(1.);
  return di;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

  uv*=2.;
  uv -= 1.;
  uv /= vec2(resolution.y / resolution.x, 1);
  
  vec3 target = vec3(sin(time), cos(time)*0.0+10.5+time*5., cos(time*.3));
  vec3 cam = vec3(0.,time*5.,-1.*sin(time*0.4));
  float fov =0.2;
  
  vec3 forward = normalize(target - cam);
  vec3 up = normalize( cross(forward, vec3(0.,1.,0.)));
  vec3 right = normalize( cross(forward, up));
  vec3 raydir = normalize( uv.x*right+uv.y*up+ fov*forward);
  
  
  vec3 col = vec3(0.);
  float t=0.0;
  for(int i=0;i<10000;i++)
  {
    vec3 p = raydir*t+cam;
    vec2 d=dist(p);
    t+=d.x;
    if(d.x <0.00001)
    {
      col=vec3(1.);
      float f = max(0.,(10.-t)/10.);
      col=light(raydir, p)*abs(vec3(sin(d.y*2.+1.),sin(d.y+3.),sin(d.y*.3)))*f;
      break;
    }
    if(t>100.)
    {
      break;
    }
  }  
  
  glFragColor = vec4(col, 1.);
}

