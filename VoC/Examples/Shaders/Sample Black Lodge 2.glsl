#version 420

// original https://www.shadertoy.com/view/NsKSW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float trn(float x){
  float ret=0.;
  ret = abs(x - floor(x+.5))*2.;
  return ret;
}

void main(void) {
  vec2 xy = gl_FragCoord.xy;
  vec2 uv = xy/resolution.xy;  
  vec3 col = vec3(1., 1., 1.);
  float band = 50.;
  float bandrp = 30.;
  float pro = (1.+uv.y);
  vec4 w = vec4(-.006*pow((1.+uv.y),5.), .2, band*2., 0.);
  bool flr =
  mod(xy.x +
      w.z*trn(w.y*time + w.x*xy.y + w.a),
      band*2.)
   >= band;
  vec4 v = vec4(0.01*(.5-uv.x), 1., bandrp*sin(time)*(1.-uv.y), 0.);
  bool drp =
  mod(xy.x +
    v.z*sin(v.y*time + v.x*xy.y + v.a),
    bandrp*2.)
  >= bandrp;
  if(uv.y<.5){
    if(flr){
      col*=0.2;
    }else{
      col=vec3(1.);
    }
    col*=(.5-uv.y)*2.;
    col.gb*=1.-uv.y;
  }else{
    if(drp){
      col*=0.7;
    }else{
      col=vec3(1.);
    }
    col.gb*=pow(1.-uv.y, 2.);
   col*=uv.y-.45;
  }
  glFragColor = vec4(col, 1.0);
}
