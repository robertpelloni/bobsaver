#version 420

// original https://www.shadertoy.com/view/lslyRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{vec2 R = resolution.xy; 
vec2 u = gl_FragCoord.xy - R/2.; 
float a = 0.32; 
float b = 0.2; 
float d = 1.0125 / 32.; 
float c = 159. * d; 
const float pi = 3.14159265; 
float fi=atan(u.x,u.y); 
vec3 col = vec3(0.,0.,0.); 
for (float i=0.; i<pi; i+=pi/16.) 
{float temp1 = i + c*fi - time; 
float temp2 = i + d*fi + time; 
col += 0.0005 / abs(a + b*sin(temp1)*sin(temp2) - length(u)/(R.y/1.15));} 
glFragColor = vec4(col, 1.0);}
