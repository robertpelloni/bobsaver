#version 420

// original https://www.shadertoy.com/view/NlyXDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float p2(float x){ return x*x; }
float p3(float x){ return x*x*x; }
float p4(float x){ return x*x*x*x; }
float s2(float x){ return (2.0-x)*x; }
float s3(float x){ return x*x*x-3.0*x*(x-1.0); }
float s4(float x){ return 4.0*x-6.0*x*x+4.0*x*x*x-x*x*x*x; }
float e1(float x){ return 3.0*x*x-2.0*x*x*x; }
float ei1(float x){ return 2.0*x*x*x-3.0*x*x+2.0*x; }

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

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec2 scale = vec2(4.0, 1.5);
    vec2 offset = vec2(0.0, -0.5) * time;

    vec2 scale2 = vec2(6.0, 1.8);
    vec2 offset2 = vec2(0.0, -0.7) * time;
    
    vec2 distort = vec2(sin(p2(uv.y*0.7) * 11.0 - time*3.5)*0.07, 0.0);
    vec2 distort2 = vec2(sin(p2(uv.y*0.8) * 17.0 - time*2.5)*0.03, 0.0);
    
    float mask = sin(uv.x*3.14)* sin((1.0-uv.y)*1.56);
    
    float gray = snoise((uv + distort) * scale + offset)*0.5+0.5;
    float gray2 = snoise((uv + distort2) * scale2 + offset2)*0.5+0.5;
    

    gray *= smoothstep(0.0, 0.7, gray2);
    gray += p2(1.0-uv.y)*0.7;
    gray = e1(clamp(gray,0.0,1.0));

    gray *= mask;
    gray = smoothstep(0.1, 0.7, gray);
    vec3 color = vec3(s3(gray),e1(gray),p3(gray));

    glFragColor = vec4(color,1.0);
    
}
