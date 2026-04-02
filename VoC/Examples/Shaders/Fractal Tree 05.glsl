#version 420

// original https://www.shadertoy.com/view/tl3GR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define line(uv) length(uv - vec2(clamp(uv.x, 0.0, 0.25), 0.0))
#define rot(ang) mat2(cos(ang), sin(ang), -sin(ang), cos(ang))

#define s  (1.0 / resolution.y)

vec3 fractal(vec2 uv)
{
    float scale = 1.0;
    vec3 col = vec3(0.0);
    for(int i = 0; i < 9; ++i){
           uv.y = abs(uv.y);        
        uv.x -= 0.25;
        uv *= 2.0;
        scale *= 2.0;
        float ang = (3.14159 / 4.0) + sin(time) * 0.01 * float(i - 1);
        uv *= rot(ang);
        col += smoothstep(s, 0.0, line(uv) / scale);
    }
    return col;
}

void main(void)
{
    
   vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
   vec3 col = vec3(0.0);
    
   uv.y += 1.0;
   uv *= 0.25;
  
      
   uv.y += sin(uv.x * 100. + time * 0.2) * 0.003;
   uv *= rot(3.14159 / 2.0 + sin(time) * 0.04);
   col += smoothstep(s, 0.0, line(uv)); 
   col += fractal(uv);
      
    
   glFragColor = vec4(col,1.0);
}
