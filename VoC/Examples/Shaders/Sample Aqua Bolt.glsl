#version 420

// original https://www.shadertoy.com/view/wlcfR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

Daily shader ! 
water, cubes and two cilinders + reflection & refraction.

Gracias a toda la comunidad por enseñarme y apoyarme
a seguir adelante con el aprendizaje, motivarme
a participar y a promover este lindo desafio que
representa realizar código en vivo, a pesar de 
no conocer a nadie, se siente el apoyo :)

-----
Esta wea la hizo lechuga yera license.
-----

*/
struct obj{
  float d;
  vec3 s, l;
};
#define time mod(time, 50.)

float light;
float rand(float x){
  return fract(sin(x)*324.2343);
}

float smin(float a, float b, float k){
  float h = max(k-abs(a-b), 0.)/k;
  return min(a, b)-pow(h, 3.)*k*(1.0/6.0);
}
#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))

float sb(vec3 p, vec3 s){
  vec3 q = abs(p)-s;
  return max(max(q.z, q.y), q.x);
}

float rand(vec2 uv){
  return fract(sin(dot(uv, uv.yx)*3766424.23423));
}
float w, mirror;
obj map(vec3 p){
  vec3 p1 = p;
  p1.x += sin(p1.z*.135345+time)*2.;
  p1.y += sin(p1.z*.3345+time)*2.;
  
  vec3 p2 = p;
  p2.y += sin(p2.z*.135345+time*.5)*2.45634234;
  p2.x += sin(p2.z*.25345+time*.125)*2.234;
  
  float cil = smin(length(p1.xy)-.3455, length(p2.xy)-.6575675, 6.)*.55;
  float d = cil;
  float alt = 10.5;
  float water = max(-p.y+alt+sin(p.x*.5454566567+time)*sin(p.y*.35345+time)*sin(p.z*.35642545+time)*.25-.25, 0.);
  float roof = max(p.y+alt+sin(p.x*.446456+time)*sin(p.y*.567567+time)*sin(p.z*.434234234+time)*.25-.25, 0.);
  d = min(d, water);
  d = min(d, roof);
//  w = water;
  w = min(water, roof);
  light += .1/(3.+cil*cil);
  
  vec3 p3 = p;
  p3.x = abs(p3.x)-15.;
  //p3.x -= 20.;
  const float rep = 11.;
  p3.xz = (fract(p3.xz/rep-.5)-.5)*rep;
  //p3.xz *= rot(time*0.001+id);
 
  float strs = sb(p3, vec3(5., 40., 5.));
  //w = min(w, -strs);
  
  mirror = 5.+strs;
  
  if(d < cil)
      d = max(d, strs);
  //else d = min(d, strs);
  return obj(d, vec3(0.3324234234, 0.4564674767, 0.567567567567), vec3(0.234234,.45345345, .5677567));
}

void main(void)
{
  vec2 uv = gl_FragCoord.xy/resolution.xy;//vec2(gl_gl_FragCoord.xy.x / v2Resolution.x, gl_gl_FragCoord.xy.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

  float fov = 1.;
  float mx = sin(time*.4)*60., my = (sin(time)*2.5)+.5;
  vec3 s = vec3(.000001+mx, -4.000001, -50.),
  t = vec3(0.-mx,-my, 0.),
  
  rz = normalize(t-s),
  rx = normalize(cross(rz, vec3(0., 1., 0.))),
  ry = normalize(cross(rz, rx)),
  r = normalize(rx*uv.x+ry*uv.y+rz*fov);
  s.z += time*20.;
  //r = normalize(vec3(-uv, 1.));
  vec3 col = vec3(0.), p=s;
  float i = 0.;
  const float MAX = 100.;
  obj o;
  const vec2 e = vec2(0.01, 0.);
  vec3 n;
  for(; i< MAX; i++){
    o = map(p);
    float d = o.d;
    if(abs(d) < 0.001){
      n = normalize(d-vec3(map(p-e.xyy).d, map(p-e.yxy).d, map(p-e.yyx).d));
      if(w < 0.5){
        r = refract(n, r, .01);
        d +=17.;
      }
      else if(mirror > 0.5){
        r = reflect(n, r);
        d+=20.;
        d*=1.5;
      }
      else break;
    }
    p+=d*r;
  }
  col += mix(vec3(.1-i/MAX), o.s, o.l);
  col = smoothstep(0., 1., col);
  col += light*vec3(0., 0.456456, 0.456456);
  col *= 1.-max(length(p-s)/100., 0.);
  glFragColor = vec4(col, 1.);
}
