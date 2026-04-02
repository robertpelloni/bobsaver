#version 420

// original https://www.shadertoy.com/view/Xd3BWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Noice function [0,1]
vec2 T = vec2(0.);
float No(float x, vec2 T){
return fract(9627.5*sin(7933.75*(x + 0.5 + T.x) + 297. + T.y));
}

vec4 Rancol(vec2 x){
return vec4(No(x.x + x.y,T), No(x.x*x.x+ x.y,T), No(x.x*x.x + x.y*x.y,T),1.);
}

//squaress
vec4 grid(vec2 uv, float t){
vec4 C1,C2;
uv *= 20.;
vec2 id = vec2(int(uv.x),int(uv.y));
uv.y += (5.*No(id.x*id.x, T) + 1.)*t*.4    ;
uv.y += No(id.x, T);
  id = vec2(int(uv.x), int(uv.y));
uv = fract(uv) - .5;

//if (id == vec2(1,10)){C1 = vec4(1.);}

float d = length(uv);
t *= 10.*No(id.x + id.y, T);
//if uv.x += No(id.x);(uv.x > .48 || uv.y > .48){C1 = vec4(1.);}

float r = .1*sin(t + sin(t)*.5)+.3;
  if (abs( uv.x)<r && abs(uv.y) < r){
  C2 = .5*Rancol(id + vec2(1.)) + vec4(.5);
  }
  if (abs(uv.x)>r+.07 || abs(uv.y)>r + .07){
  C2 += vec4(.7,.9,.8,1.);
  }
  return C2 + C1;
  }

void main(void) {
vec2 F = gl_FragCoord.xy;
T = resolution.xy.xy;
vec2 uv = F / resolution.xy;
uv.y *= resolution.y/resolution.x;
float t = time;
glFragColor = vec4(grid(uv, t));
}
