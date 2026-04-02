#version 420

// original https://www.shadertoy.com/view/3t2BWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Simplex 2D noise
//
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v){
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

void main(void) {
  vec2 uv = gl_FragCoord.xy / resolution.xy;
  uv.x *= resolution.x / resolution.y;

  vec3 color = vec3(0.0);

  // sinewave on UV
  uv.y += sin(uv.x * 5.0 + time* 3.3) * 0.05 * cos(uv.x) * 0.3;

  // move UV over time
  uv.x += time * 0.09;
  uv.y += time * 0.04;

  // Make a grid
  vec2 gv = fract(uv*7.0);

  // Remap GV from [0..1] to [-1..1]
  gv.x = gv.x * 2.0 - 1.0;
  gv.x = abs(gv.x);

  // Distort uv.y
  gv.y += gv.x * 0.4;
  gv.y -= 0.1;
  
  // Define the colors of the bands
  vec3 col1 = vec3(0.3882, 0.102, 0.502);
  vec3 col2 = vec3(0.6588, 0.0784, 0.5137);
  vec3 col3 = vec3(1.0, 0.2, 0.7);
  
  // Adding the bands
  if (gv.y <= 0.19)
    color += col1 * (1.0 - smoothstep(0.0, 0.19, gv.y) * 0.5);

  if (gv.y > 0.19 && gv.y <= 0.53)
    color += col2 * (1.0 - smoothstep(0.34, 0.53, gv.y) * 0.5);

  if (gv.y > 0.53 && gv.y <= 0.86)
    color += col3 * (1.0 - smoothstep(0.67, 0.86, gv.y) * 0.5);

  if (gv.y > 0.86)
    color += col1 * (1.0 - smoothstep(1.0, 1.19, gv.y) * 0.5);

  if (gv.y > 1.19 && gv.y <= 1.53)
    color = col2 * (1.0 - smoothstep(1.34, 1.53, gv.y) * 0.5);
    
  float noise = snoise(uv*3.3 - vec2(time*0.7, time*1.4)) * 0.5 + 0.5;
  
  // Playing around with color values
  color.rg -= gv.x*0.3;
  color.rg -= min(0.35, max(0.6, gv.x)) * 1.2;
  color.r = pow(color.r, 4.5 * noise);
  color.g = pow(color.r, 9.5 * noise);
  color.b = pow(color.b, 2.5 * noise);

  glFragColor = vec4(color, 1.0);
}
