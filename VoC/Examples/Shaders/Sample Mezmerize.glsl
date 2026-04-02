#version 420

// original https://neort.io/art/c6jope43p9f0jhbh6ik0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

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
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    float frequency = 4.0;
    float speed = 0.15;
    uv *= frequency;
    float d = length(uv) - time * speed * 4.0 + snoise(uv) * 0.12;
    float ff = fract(d);
    float a = step(0.5, sin(atan(uv.y, uv.x)) * 0.5 + 0.5);
    float f = step(0.5, ff);
    float f2 = step(0.5, fract((sin(atan(uv.y, uv.x + snoise(uv) * 0.05) + floor(d) - time * speed * 0.5) * 0.5 + 0.5) * 6.0));
    float f3 = step(0.5, fract((sin(atan(uv.y, uv.x + snoise(uv) * 0.1) + floor(d) + time * speed * 0.9) * 0.5 + 0.5) * 14.0));
    
    float n = step(0.6, snoise(uv * 1000000.0 + time));
    float noiseShadow = n * fract(length(uv) - time * speed * 5.0);
    
    vec3 bgColor = vec3(0.9, 0.2, 0.1);
    vec3 color1 = vec3(0.2, 0.2, 0.2);
    vec3 color2 = mix(vec3(0.9, 0.9, 0.5), vec3(0.9, 0.7, 0.0), noiseShadow);
    vec3 color3 = vec3(0.5, 0.0, 0.5);
    vec3 color = mix(bgColor, color1, f);
    color = mix(color, color2, f2);
    color = mix(color, color3, f3);
    color = mix(color2, color, step(0.4, length(uv)));

    glFragColor = vec4(color, 1.0);
}
