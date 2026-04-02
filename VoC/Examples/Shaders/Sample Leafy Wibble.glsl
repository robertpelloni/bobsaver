#version 420

// original https://www.shadertoy.com/view/3dcyDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A Green Leafy thing :)

float wave(vec2 p)
{
  float v = sin(p.x + sin(p.y) + sin(p.y * .43));
  return v*v;
}
 
float get(vec2 p,float t)
{
  mat2 rot = mat2(0.5, 0.86, -0.86, 0.5);
  float v = wave(p);
  p.y += t;
  p *= rot;
  v += wave(p.yx);
  p.y += t * .17;
  p *= rot;
  v += wave(p.xy);
  v = abs(1.5 - v);
  v+=pow(abs(sin(p.x+v)),18.0);
  return v;
}

void main(void)
{
       vec2 uv = (resolution.xy - 2.0*gl_FragCoord.xy)/resolution.y;
    float t = time;
    float scale =14.0;
    float speed = .3;
    uv.y += sin(fract(t*0.1+uv.x)*6.28)*0.05;    // wibble
    uv.xy += t*0.08;                    // scroll
    vec2 p = uv*scale;
    //p.y+= 1.0/p.y*p.y;
      float v = get(p,t*speed);
      v = smoothstep(-3.5,3.5,v);
    vec3 col = vec3(.29, 0.86, 0.4);
    glFragColor = vec4(col*v*v, 1.0);

}
