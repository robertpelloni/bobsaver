#version 420

// original https://www.shadertoy.com/view/WlySzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
      float t = time * 2.1;
    vec2 uv = gl_FragCoord.xy/resolution.y*2.;
  float u=uv.x;
  float v=uv.y;
  
  float l=length(uv-vec2(1.,1.));
  float d=distance(sin(t+uv),vec2(sin(l*10.+sin(u)+t),cos(l*5.)));
 
  float circles=sin(dot(sin(t)+10.,l*10.));
  
  float shape=circles-d;
  
  vec3 color=vec3(u,v,u*v+sin(t*3.)*.5+.5);
  
  vec3 col=vec3(shape+color*.6);
  
    glFragColor = vec4(col,1.0);
}
