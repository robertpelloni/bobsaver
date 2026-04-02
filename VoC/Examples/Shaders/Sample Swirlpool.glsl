#version 420

// original https://www.shadertoy.com/view/dsG3Rm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rotation(angle) mat2(cos(angle), -sin(angle), sin(angle), cos(angle));

float PI = 3.14159256;
float TAU = 2.0*3.14159256;

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

float circleSDF(vec2 coords, float rad, vec2 offset){
  return (length(coords-offset) - rad)-.00;
}

float circleSDF2(vec2 coords, float rad, vec2 offset){
  return abs(length(coords-offset) - rad)-.001;
}

void main(void) {
   vec2 uv = ( gl_FragCoord.xy - .5* resolution.xy ) /resolution.y;
   float a = (PI)*pow((1.4-pow(length(uv),.5)),3.5);
   uv *= rotation(PI/3. + a*a/2.);   
  
   float d = pow(length(uv),1.5);
   float modVal = .1;
   
   uv += vec2(-time*modVal, 0.);
   uv = mod(uv,modVal);
   
   vec3 col = vec3(0.);
   
   float dd = map(d, 0., 1.25, .015, 0.);  
   
   float cSDF = circleSDF(uv, .04-pow(dd,.95), vec2(modVal/2.0,modVal/2.0));
   col += 1.5*d*smoothstep(.006,-.006,cSDF);  
   
   float cSDF2 = circleSDF2(uv, .05-pow(dd,.95), vec2(modVal/2.0,modVal/2.0));
   col += 1.5*d*smoothstep(.006,-.006,cSDF2); 
   glFragColor = vec4(col, 1.0);
}
