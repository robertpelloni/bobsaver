#version 420

// original https://www.shadertoy.com/view/Nty3W1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI         3.14159265358979
#define SAMPLES    2048
#define ITERATIONS 4

float Sign(vec2 p, vec3 abc, float t)
{
  float a  = abc.y * t;
  float b  = abc.z + t;
  float e  = exp(-abc.x * t);
  
  vec2  A  = vec2(e     , -abc.x * e     );
  vec2  B  = vec2(cos(a), -abc.y * sin(a));
  vec2  C  = vec2(sin(b),          cos(b));
  
  vec2  q0 = vec2(A.x * B.x            , A.x * C.x            );
  vec2  q1 = vec2(A.y * B.x + A.x * B.y, A.y * C.x + A.x * C.y);
  vec2  pq = p - q0;
  
  return sign(dot(pq, q1));
}

vec3 Func(vec2 p, vec3 abc, float t)
{
  float a  = abc.x, aa = a * a;
  float b  = abc.y, bb = b * b;
  float c  = abc.z, cc = c * c;
  float d  = exp(-a * t);
  vec2  e  = vec2(sin(b * t), cos(b * t));
  vec2  f  = vec2(sin(t + c), cos(t + c));
  
  vec3  A  = vec3(d  , -a * d  ,  aa * d  );
  vec3  B  = vec3(e.y, -b * e.x, -bb * e.y);
  vec3  C  = vec3(f.x,      f.y, -     f.x);
  
  vec2  q0 = vec2(A.x * B.x                             , A.x * C.x                             );
  vec2  q1 = vec2(A.y * B.x +      A.x * B.y            , A.y * C.x +      A.x * C.y            );
  vec2  q2 = vec2(A.z * B.x + 2. * A.y * B.y + A.x * B.z, A.z * C.x + 2. * A.y * C.y + A.x * C.z);
  vec2  pq = p - q0;
  
  return vec3(dot(pq, q1), dot(pq, q2) - dot(q1, q1), length(pq));
}

float Lissajous(vec2 p, vec3 abc)
{
  float dt, t, s0, s1, dist;
  vec3  func;
  int   i, j;
  
  dt   = 64. * PI / float(SAMPLES - 1);
  s0   = Sign(p, abc, 0.);
  dist = Func(p, abc, 0.).z;
  
  for(i = 1; i < SAMPLES; ++i)
  {
    s1 = Sign(p, abc, float(i) * dt);
    
    if(s0 == s1)
      continue;
    
    s0   = s1;
    func = Func(p, abc, t = (float(i) - .5) * dt);
   
    for(j = 0; j < ITERATIONS; ++j)
      func = Func(p, abc, t -= func.x / func.y);
    
    if(func.z < dist)
      dist = func.z;
  }
  
  return dist;
}

void main(void)
{
    vec2 r = resolution.xy * .5;
    vec2 p = (gl_FragCoord.xy - r)/r.y;

    float intensity = 2e-3 / Lissajous(1.1 * p, vec3(1./81., 2./3., time));
    float gamma     = pow(intensity, 1.0/2.2);
    
    glFragColor = vec4(vec3(0., gamma, 0.), 1.);
}
