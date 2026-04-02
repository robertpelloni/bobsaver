#version 420

// original https://www.shadertoy.com/view/lsd3DS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Mandelbrot demo ported from Humus demo (http://humus.name/index.php?page=3D&ID=85)

// Calculate the position in the Mandelbrot (typically passed as a shader constant)
vec3 CalcOffset()
{
  float time = time * 1000.0;

  float tt = mod(time,8192.0);  
  
  float targetIndex = mod(time / 8192.0, 5.0);
  vec2 pos1 = vec2(+0.30078125, +0.02343750); 
  vec2 pos2 = vec2(-0.82421875, +0.18359375);   
    
  if(targetIndex > 1.0)
  {
    pos1 = pos2;
    pos2 = vec2(+0.07031250, -0.62109375);      
  }
  if(targetIndex > 2.0)
  {
    pos1 = pos2;      
    pos2 = vec2(-0.07421875, -0.66015625);            
  }
  if(targetIndex > 3.0)
  {
    pos1 = pos2;      
    pos2 = vec2(-1.65625000, +0.00000000);                  
  }
  if(targetIndex > 4.0)
  {
    pos1 = pos2;      
    pos2 = vec2(+0.30078125, +0.02343750);                  
  }
    
  float t1 = tt * (1.0 / 8192.0);
  float f = 4.0 * (t1 - t1 * t1);
  f *= f;
  f *= f;
  f *= f;
  f *= f;
  float s = t1;
  s = s * s * (3.0 - s - s);
  s = s * s * (3.0 - s - s);
  s = s * s * (3.0 - s - s);
  s = s * s * (3.0 - s - s);    
    
  return vec3(pos1.x - s * pos1.x + s * pos2.x,
              pos1.y - s * pos1.y + s * pos2.y,
              f + (1.0 / 8192.0));
}

void main(void)
{
  vec3 tex = CalcOffset();
  vec2 x = (gl_FragCoord.xy * vec2(2.0)/resolution.yy - vec2(1.0))*tex.z + tex.xy;
  vec2 y=x;
  vec2 z=y;
    
  float lw = 255.0;
  for(int w=0; w<255; w++)
  {
    if(y.x < 5.0)
    {   
      y=x*x;
      x.y*=x.x*2.0;
      x.x=y.x-y.y;
      x+=z;
      y.x+=y.y;

      lw-=1.0;
    }
  }
  glFragColor = sin(vec4(2.0,3.5,5.0,5.0) + (lw/18.0 + log(y.x) / 28.0)) / 2.0 + 0.5;
  glFragColor.w=1.0;
}

