#version 420

// original https://www.shadertoy.com/view/tt33DS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time  time

float torus (vec3 p, vec2 r,float sp)
{

  p.yz *= mat2(cos(1.57),-sin(1.57),sin(1.57),cos(1.57)); 
  p.xy *= mat2(cos(time*mix(-sp,sp,sin(time)*0.015)),-sin(time*mix(-sp,sp,sin(time)*0.015)),sin(time*mix(-sp,sp,sin(time)*0.015)),cos(time*mix(-sp,sp,sin(time)*0.015)));
  float x = length(p.xz) - r.x;
  return length(vec2(x,p.y)) - r.y;   
}

float trace (vec3 o, vec3 r)
{
  float t = 0.0;
  for(int i = 0;i < 100;i++)
  {
      vec3 p = o+r*t;
      float d0 = torus(p-vec3(0,0,0),vec2(0.1,0.1),0.0);
      float d1 = torus(p-vec3(0,0,0),vec2(0.5,0.15),1.0);
      float d2 = torus(p-vec3(0,0,0),vec2(1.0,0.15),1.0);
      d1 = min(d1,d0);
      d1 = min(d1,d2);
      float dx;
      float tt = 0.25;
      float tx = 1.0;
      for(int i = 1; i < 20;i++)
      {
        dx = torus(p-vec3(0,0,0),vec2(tx,0.15),1.5+tt);
        d1 = min(d1,dx);
        tt += 0.07;
        tx += 0.5;
      }
      
      
      t += d1*0.25;
  }
  return t;
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
      uv -= 0.5;
      uv /= vec2(resolution.y / resolution.x, 1.0);

      vec3 r = normalize(vec3(uv,1.0));

      vec3 o = vec3(0.0,0.0,-25);
      float t = trace(o,r); 
  
      float fog = 1.0/(1.0+t*t*0.001);

    glFragColor = vec4(vec3(fog)*vec3(0.0,0.0,1.0),1.0);
}
