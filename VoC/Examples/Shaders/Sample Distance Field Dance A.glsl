#version 420

// original https://www.shadertoy.com/view/XttBRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Mark Serdtse
// Variation of distance field explanation 
// from https://thebookofshaders.com/07/?lan=ru

void main(void)
{
  vec2 st = gl_FragCoord.xy/resolution.xy;
    
  st.x -= 0.2; 
  st.x *= resolution.x/resolution.y;
    
  vec3 color = 0.5 + 0.5*cos(time+st.xyx+vec3(0,2,4));
  float d = 0.0;
    
  st = st *2.-1.;
    
  float sin_factor = sin(time/5.);
  float cos_factor = cos(time/5.);
    
  st = st* mat2(cos_factor, sin_factor, -sin_factor, cos_factor);
    

  d = length(abs(sin(abs(st*2.)+time))*(sin(abs(cos(st.x)*sin(st*5.))*.8)/2.));

    
  float mask = sin(d*50.0);
      
  color = color*mask;
    
  glFragColor = vec4(color,1.0);

}
