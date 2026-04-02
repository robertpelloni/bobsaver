#version 420

// original https://www.shadertoy.com/view/tdt3RX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
// Normalized pixel coordinates (from 0 to 1)
vec2 uv = gl_FragCoord.xy/resolution.xy;

// Time varying pixel color
float x = gl_FragCoord.x/100.0;
float phase = time*1.0;

float ass = 0.0;
float arr[10];

arr[0] = -0.55;
arr[1] = 0.77;
arr[2] = 0.15;
arr[3] = -0.45;
arr[4] = -0.3;
arr[5] = 0.42;
arr[6] = 0.433;
arr[7] = -0.13;
arr[8] = 0.55;
arr[9] = 0.65;

for(float i=0.0; i<10.0; i+=1.0){
float k = pow(2.0, i);
ass += sin(time + arr[int(i)] * x ) * sin((x+ arr[int(i)] * phase)*k/2.0) / k / 4.0;
}

vec3 col = vec3(sin(time), distance(vec2(0, 0), gl_FragCoord.xy)/500.0, 0);

float val = 1.0- pow(abs(0.55 + sin(gl_FragCoord.y*1.0 + 0.567)*0.05 - uv.y), 1.0) * (ass + 0.4)/(sin(time*2.0 + 1.11*x)*0.5+1.0)*32.0 ;
float val1 = 1.0- pow(abs(0.5 + sin(gl_FragCoord.y*1.123 + 1.111)*0.05 - uv.y), 1.0) * (ass + 0.4)/(sin(time*2.0 - 2.0*x)*0.5+1.0)*32.0 ;
float val2 = 1.0- pow(abs(0.45 + sin(gl_FragCoord.y*0.984 + 5.123)*0.05 - uv.y), 1.0) * (ass + 0.4)/(sin(time*5.1 - 0.67*x)*0.5+1.0) *32.0;
if(val > 0.0 || val1 > 0.0 || val2 > 0.0){
col = vec3 (1.0 - val, 1.0 - val1, 1.0 - val2);
}
else
col = vec3(0.0, 0.0, 0.0);

// Output to screen
glFragColor = vec4(col,1.0);
}
