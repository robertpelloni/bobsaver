#version 420

// original https://www.shadertoy.com/view/4lXyWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//----------------------------------------------------------------
// Fractaloscopic.glsl                    2017-09-22 by Gerd Platl
// Fractal Colors meets Koleidoscope...
// Switch to fullscreen, enjoy the koleidoscopic beauty and 
// explore undiscovered forms of appearance with your mouse.
// tags: fractal, koleidoscope, flower, colors, discover
//----------------------------------------------------------------

#define time time
#define resolution resolution

//----------------------------------------------------------------
// Koleidoscope by ackleyrc: https://www.shadertoy.com/view/llXcRl 
//----------------------------------------------------------------

const float NUM_SIDES = 3.0;  // set your favorite mirror factor here

const float PI = 3.14159265359;

const float KA = PI / NUM_SIDES;

//----------------------------------------------------------------
// transformation to koleidoscopic coordinates
//----------------------------------------------------------------
void koleidoscope(inout vec2 uv)
{
  // get the angle in radians of the current coords relative to origin (i.e. center of screen)
  float angle = atan (uv.y, uv.x);
  // repeat image over evenly divided rotations around the center
  angle = mod (angle, 2.0 * KA);
  // reflect the image within each subdivision to create a tilelable appearance
  angle = abs (angle - KA);
  // rotate image over time
  angle += 0.1*time;
  // get the distance of the coords from the uv origin (i.e. center of the screen)
  float d = length(uv); 
  // map the calculated angle to the uv coordinate system at the given distance
  uv = d * vec2(cos(angle), sin(angle));
}
//----------------------------------------------------------------
// equal to koleidoscope, but more compact 
//----------------------------------------------------------------
void smallKoleidoscope(inout vec2 uv)
{
  float angle = abs (mod (atan (uv.y, uv.x), 2.0 * KA) - KA) + 0.1*time;
  uv = length(uv) * vec2(cos(angle), sin(angle));
}
//----------------------------------------------------------------
void main(void)
{
  vec2 uv = 12.0*(2.0 * gl_FragCoord.xy / resolution.xy - 1.0);
  uv.x *= resolution.x / resolution.y;
  //uv.x += 2.*sin(2.*time);
  vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
      
  // koleidoscope(uv);
  smallKoleidoscope(uv);
    
  // Fractal Colors by Robert Schütze (trirop): http://glslsandbox.com/e#29611
  vec3 p = vec3 (uv, mouse.x);
  for (int i = 0; i < 44; i++)
    p.xzy = vec3(1.3,0.999,0.678)*(abs((abs(p)/dot(p,p)-vec3(1.0,1.02,mouse.y*0.4))));
  
  glFragColor = vec4(p,1.0);
}
