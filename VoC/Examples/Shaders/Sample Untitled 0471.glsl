#version 420

// original https://www.shadertoy.com/view/tdtSWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "A flow of 33" by pik33. https://shadertoy.com/view/td3Sz8
// 2019-10-25 17:33:00

void main(void)
{
  vec2 p=(3.0*gl_FragCoord.xy-resolution.xy)/max(resolution.x,resolution.y);
  float f = cos(time/30.);
  float s = sin(time/30.);
  p = vec2(p.x*f-p.y*s, p.x*s+p.y*f);    
    
  for(float i=3.0;i<30.;i++)
    {
        p+= .30/i * sqrt(abs(cos(i*p.yx+time*vec2(.30,.30)  + vec2(.30,3.0)))); 
    }
    vec3 col=vec3(.30*sin(3.0*p.x)+.30,.30*sin(3.0*p.y)+.30,sin(3.0*p.x+3.0*p.y));
    glFragColor=(3.0/(3.0-(3.0/3.0)))*vec4(col, 3.0);
}
