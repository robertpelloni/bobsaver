#version 420

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

void main() {
  vec2 uv = vec2(0.5, 0.5) - gl_FragCoord.xy / resolution.y;
  float a  = time;
  float d = 1.0;
  float n = a * 0.1;
  float Z = 3.0;
  float sn = sin(n);
  float cn = cos(n);
  //eye position
  float v = 0.1;
  vec3 pos = vec3(0.5,0.5,time * 0.3);
  vec3 start = pos;
  vec3 dir    = normalize(vec3(uv.x * 1.25,uv.y,1.0));
  vec3 t = pos;
  
  //rotate direction
  dir = vec3(cn * dir.x + sn * dir.z, dir.y, cn * dir.z - sn * dir.x).xzy;
  dir.xzy = vec3(cn * dir.x + sn * dir.z, dir.y, cn * dir.z - sn * dir.x);
  
  //ite
  //for(int i = 7;i>0; i--)
  for(int i = 10;i>0; i--)
  {
    d /= Z;
    t = fract(t) * Z;
    int j = int(mod(dot(vec3(ivec3(t)), vec3(ivec3(t))), 4.0));
    if(j >= 2) {
      vec3  kk = vec3(0.0);
      if(dir.x > 0.0) kk.x = 1.0;
      if(dir.y > 0.0) kk.y = 1.0;
      if(dir.z > 0.0) kk.z = 1.0;
      t        = (kk - fract(t)) / dir;
      n        = min(min(t.x, t.y), t.z);
      pos     += dir * (n * d + 0.0001);
      t        = pos;
      d        = 1.0;
    }
  }
  
  //output distance.
  float cc = pow(n, 4.0) + length(pos - start) * 0.75;
  glFragColor = mix(vec4(cc, cc*0.7, cc*0.5, 1.0).yyxw, vec4(cc, cc*0.7, cc*0.5, 1.0).zyxw, sin(a * 0.3));
}
