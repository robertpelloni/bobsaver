#version 420

// original https://www.shadertoy.com/view/NsBXDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
 vec2 uv = gl_FragCoord.xy/resolution.xy*10.;
 
 for (float i = 1.; i < 15.; i++)
  {
    vec2 uv2 = uv;
    uv2.x += sin(time*.25)*1.25/ i* sin(i *  uv2.y + time * 0.55);
    uv2.y +=  cos(time*.2)*2./i* cos(i * uv2.x + time * 0.35 ); 
    uv = uv2;
  }
  
 float r = abs(sin(uv.x))+.5;
 float g =abs(sin(uv.x+2.))-.2;
 float b = abs(sin(uv.x+4.));   
 vec3 col = vec3(r,g,b);   
 
 glFragColor = vec4(col, 1.0);
}
