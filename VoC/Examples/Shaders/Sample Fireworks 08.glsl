#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(float val, float seed)
{
  return cos(val * sin(val * seed) * seed);
}

float distance2( in vec2 a, in vec2 b)
{
  return dot(a - b, a - b);
}

mat2 rr = mat2(cos(1.0), -sin(1.0), sin(1.0), cos(1.0));

vec3 drawParticles(vec2 pos, vec3 particolor, float time, vec2 cpos, float gravity, float seed, float timelength)
{
  vec3 col = vec3(0.0);
    
  vec2 pp = vec2(1.0, 0.0);
    
    float rho = 12./(resolution.y*resolution.y);
    
  for (float i = 1.0; i <= 64.0; i++)
  {
    float d = rand(i, seed);
      
    float fade = (i / 64.0) * time;
      
    vec2 particpos = cpos + time * pp * d;
      
    pp = rr * pp;
      
    col = mix(particolor / fade, col, smoothstep(0.0, rho*(1.+cos(i)*0.5), distance2(particpos, pos)));
  }
    
  col *= smoothstep(0.0, 1.0, (timelength - time) / timelength);

  return col;
}

vec3 drawFireworks(float time, vec2 uv, vec3 particolor, float seed)
{
  vec3 col = vec3(0.0);
    
  float duration = 1.0;
    
  col = drawParticles(
            uv, 
        particolor, 
        mod(time, duration), 
        vec2(rand(ceil(time / duration), seed), -0.5), 
        0.5, 
        ceil(time / duration),
        seed);
    
  return col;
}

void main(void)
{
  vec2 uv = 1.0 - 2.0 * gl_FragCoord.xy / resolution.xy;
    
  uv.x *= resolution.x / resolution.y;
    
  vec3 col = vec3(0.0, 0.0, 0.0);
    
  col += drawFireworks(time,       uv, vec3(1.0, 0.1, 0.1), 1.);
  //col += drawFireworks(time + 2.0, uv, vec3(0.0, 1.0, 0.5), 2.);
  //col += drawFireworks(time + 4.0, uv, vec3(1.0, 1.0, 0.1), 3.);

  glFragColor = vec4(col, 1.0);
}
