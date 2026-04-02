#version 420

// original https://www.shadertoy.com/view/7ttGR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 fluid(vec2 uv1){
 vec2 uv = uv1;
 float t = time;
 for (float i = 1.; i < 15.; i++)
  {
    uv.x -= (t+sin(t+uv.y*i/1.5))/i;
    uv.y -= cos(uv.x*i/1.5)/i;
  }
  return uv;
}

void main(void)
{
 vec2 uv = gl_FragCoord.xy/resolution.xy*10.;
 uv = fluid(uv);
 float r = abs(sin(uv.x))+.5;
 float g =abs(sin(uv.x+2.+time*.2))-.2;
 float b = abs(sin(uv.x+4.));   
 vec3 col = vec3(r,g,b);   
 
 glFragColor = vec4(col, 1.0);
}
