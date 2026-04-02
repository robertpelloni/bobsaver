#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592
#define TAU 6.28318

float surface(float d, float s) {
    return 1. + 0.05 * sin(d*400.*(1.+s));
}

float arm(vec2 pixel, vec2 krakenPos, float direction, float len, float waviness) {
    
  vec2 delta = pixel - krakenPos;
  float l = length(delta);
  float a = atan(delta.y, delta.x);

  // Wave
  direction += cos(l * 22.*l  - time * 2.) * waviness;
  
  float baseSize = 1.0;
  return (mod(abs(mod(a+TAU/4., TAU) - mod(direction, TAU)), TAU) - (len - l)*baseSize) / 5.;
}

float kraken(vec2 pixel, vec2 krakenPos) {
  float krakenSize = 0.2 + cos(time*1.7)*0.02;
  
  float b = distance(krakenPos, pixel) - krakenSize;
  //if (b <= 0.) return b;
    
  float arms = 8.0;  
  float dist = b;    
  for (int i = 1; i <= 8; i++) {
    dist = min(dist, arm(pixel, krakenPos, float(i) * TAU / arms - time/3., 0.5, .1 * abs(sin(time/9.)*3.)));
  }
  
  return dist;
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main( void )
{
  vec2 pos = (gl_FragCoord.xy * 2.0 - resolution)/max(resolution.x, resolution.y);
  float wave = 0.0;

  // Sky color by default
  vec3 c = mix(vec3(.7, 0.9,0.8), vec3(.4, .6,.9), pos.y+0.5);
  c *= 1. + 0.3 * surface(pos.y, 3.-pos.y*3.);    
    
  for (int j = 1; j <= 15; j+=1) {    
    float i = float(j);
      float x = rand(vec2(i, i+1.0));
      float wavephase = 2.0*x*13.3*PI+i;
      //float wavephase = 0.0;
      float t = time*(6.-i*.1);    
      float wavetime = 0.0;
      float waveSize = 0.025;
      float waveAmp = max(0.0,waveSize - i*0.0016);
    
      float k = 2.0*PI/waveSize;
      float waveshort = 5.0+i;    
      float wavestokes = ((1.0-1.0/16.0*pow((k*waveSize),2.0))*cos(pos.x*waveshort+t+wavephase) + 0.5*k*waveSize*cos(2.0*waveshort*pos.x+t+wavephase));
      
      float wave = waveAmp*pow(wavestokes,1.0)+sin(t+x*12.2)*0.01/i+(i*(0.06-i*0.0009)-0.5);     
      
      if (j > 4) {
              float kr = kraken(pos, vec2(0.0, -0.2));
          if (kr < 0.0) {
              c = vec3(0.1+kr*2., 0.4-kr*0.5, 0.3+kr);
              c *= surface(kr, .5);  
              break;
          }
      }
      if (pos.y < wave) {
            c = mix(vec3(0.0,0.1,0.2), vec3(0.6, 0.6+i/60., 0.9), 0.05*i);
        c *= surface(pos.y - wave, i/8.);  
        break;
      }
  }

//  if (visibleWave > 0.) c = mix(vec3(0.0,0.1,0.2), vec3(0.6, 0.75, 0.9), visibleWave);

  //c.g = visibleWave / 1.0;
    
  glFragColor = vec4(c, 1.0);

}
