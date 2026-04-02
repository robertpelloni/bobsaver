#version 420

// original https://www.shadertoy.com/view/7sf3z2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
|--------------------------------------------------------------------------
| Rémy Dumas
|--------------------------------------------------------------------------
|
| Twitter: @remsdms
| Portfolio: remydumas.fr
|
*/

/*
|--------------------------------------------------------------------------
| Map
|--------------------------------------------------------------------------
|
| ...
|
*/

float map(vec2 p) {
    return length(p) - 0.2;
}

/*
|--------------------------------------------------------------------------
| Main
|--------------------------------------------------------------------------
|
| Sandbox and sometimes something good
|
*/

void main(void)
{
  vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
  vec3 col;
  vec3 color = vec3(1.,1.,1.);

  for(float j = 0.0; j < 4.0; j++){
      for(float i = 1.; i < 8.0; i++){
          uv.x += (1.0 * (0.2 / (i + j) * sin(i * atan(time) * 2.0 * uv.y + (time * 0.1) + i * j)));
          uv.y+= (1.0 * (1.0 / (i + j) * cos(i * 0.6 * uv.x + (time * 0.25) + i * j)));
      }
      col[int(j)] = -1.0 * (uv.x * uv.y);
  }
  

  vec3 bg = vec3(1.,1.,1.);
  color = mix(
    col,
    bg,
    1.0-smoothstep(0.0,abs(sin(time*0.05)*3.0),map(uv))
  );   

  glFragColor = vec4(vec3(color), 1.);
}
