#version 420

uniform vec2 resolution;
uniform float time;
uniform vec3 mouse;

out vec4 glFragColor;
 
vec3 trans(vec3 p)
{
  return mod(p - vec3(cos(time), sin(time), fract(time)*2.)*4., 8.0)-4.0;
}
 
float lengthN(vec3 v, float n)
{
  vec3 tmp = pow(abs(v), vec3(n));
  return pow(tmp.x+tmp.y+tmp.z, 1.0/n);
}
 
float distanceFunction(vec3 pos)
{
  return lengthN(trans(pos), 4.0) - 1.0;
}
 
vec3 getNormal(vec3 p)
{
  const float d = 0.0001;
  return
    16384.* abs
    (
      vec3
      (
        distanceFunction(p+vec3(d,0.0,0.0))-distanceFunction(p+vec3(-d,0.0,0.0)),
        distanceFunction(p+vec3(0.0,d,0.0))-distanceFunction(p+vec3(0.0,-d,0.0)),
        distanceFunction(p+vec3(0.0,0.0,d))-distanceFunction(p+vec3(0.0,0.0,-d))
      )
    );
}
 
void main() {
  vec2 pos = (gl_FragCoord.xy*2.0 -resolution) / resolution.y;
 
  vec3 camPos = vec3(0.0, 0.0, 3.0) + mouse;
  vec3 camDir = vec3(0.0, 0.0, -1.0);
  vec3 camUp = vec3(0.0, 1.0, 0.0);
  vec3 camSide = cross(camDir, camUp);
  float focus = sin(time)*.1 + 0.2;
 
  vec3 rayDir = normalize(camSide*pos.x + camUp*pos.y + camDir*focus);
 
  float t = 0.0, d=0.0;
  vec3 posOnRay = camPos;
 
  for(int i=0; i<64; ++i)
  {
    d = distanceFunction(posOnRay);
    t += d;
    posOnRay = camPos + t*rayDir;
  }
 
  vec3 normal = getNormal(posOnRay);
  if(abs(d) < 0.001)
  {
    glFragColor = vec4(normal, 1.0);
  }else
  {
    glFragColor = vec4(0.0);
  }
}
