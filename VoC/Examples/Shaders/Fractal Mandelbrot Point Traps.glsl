#version 420

// original https://www.shadertoy.com/view/7tGGzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float MAX_ITERATIONS = 50.0;
const vec2 CENTER = vec2(-0.5, 0);
const float INFINITY = 10000000000.; // 1./0.; dividing by zero seems to give infinity in WebGL2 outside shadertoy

vec3 hsl2rgb(float h, float s, float l) {
  float hp = 6. * mod(h,1.);
  float c = s - s * abs(2.*l - 1.);
  float x = c - c * abs(mod(hp,2.) - 1.);
  float m = l - c/2.;
  if      (hp <= 1.) return vec3(c,x,0) + m;
  else if (hp <= 2.) return vec3(x,c,0) + m;
  else if (hp <= 3.) return vec3(0,c,x) + m;
  else if (hp <= 4.) return vec3(0,x,c) + m;
  else if (hp <= 5.) return vec3(x,0,c) + m;
  else               return vec3(c,0,x) + m;
}

void main(void) {
    vec2 coord = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    vec2 z = vec2(0, 0);
    vec2 c = coord + CENTER;
     
    vec2 trap = vec2(
      sin(time/1.3),
      sin(time/1.7)
    );    
    float trapDistance = INFINITY;

    float i = 0.0;
    while (i < MAX_ITERATIONS) { 
      z = vec2(z.x*z.x - z.y*z.y, 2.*z.x*z.y) + c;

      trapDistance = min(trapDistance, length(z - trap));
      
      if (length(z) > 4.) break;
      i++;
    }

    if (i >= MAX_ITERATIONS) {
      glFragColor = vec4(0,0,0,1);      
    } 
    else {  
      float escapeSpeed = (i - log2(log(length(z)))) / MAX_ITERATIONS;
      float trapDistance = min(trapDistance, 1.);
      glFragColor = vec4(
        hsl2rgb(
          escapeSpeed + time/10.,          
          .7,
          1. - trapDistance
        ),
        1
      );     
    }
}
