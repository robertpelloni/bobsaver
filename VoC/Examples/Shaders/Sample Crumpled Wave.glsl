#version 420

// original https://www.shadertoy.com/view/3ttSzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    vec2 uv =  (2.0 * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);
   
    for(float i = 1.0; i < 8.0; i++){
    uv.y += i * 0.1 / i * 
      sin(uv.x * i * i + time * 0.5) * sin(uv.y * i * i + time * 0.5);
  }
    
   vec3 col;
   col.r  = uv.y - 0.1;
   col.g = uv.y + 0.3;
   col.b = uv.y + 0.95;
    
    glFragColor = vec4(col,1.0);
}
