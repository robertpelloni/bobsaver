#version 420

// original https://www.shadertoy.com/view/sdtXWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float plot(vec2 uv, float y){
return smoothstep(y-0.05,y,uv.y)-smoothstep(y,y+0.05,uv.y);
}

float plotc(vec2 uv, float y){ //ta funkcja jest tylko do czarnego środka potrzebna
return smoothstep(y-1.,y+1.,uv.y);
}

void main(void) {
vec2 uv = gl_FragCoord.xy / resolution.xy;
uv = uv*2.-vec2(1.,1.);
uv.x = uv.x*resolution.x/resolution.y;
vec2 uva = vec2(atan(uv.x,uv.y), length(uv));
vec3 col;
  float t = time;
  float p;
  float off = -2.1;
  //float p = 3.*sin(t*0.3)*cos(t*0.5)*2.;
  p = 3.; //można różne p, generalnie to ilość płatków, przy p = 0.08 wychodzi spirala choć trochę nierówna jeszcze
  //p = 0.08;
  for (int i = 0; i < 20; i++){
  col += vec3(plot(uva-(fract(t)+off),sin((uva.x-sin(t))*p))); //odkomentuj lub zakomentuj dla dodatkowego bujania
  col += vec3(plot(uva-(fract(t)+off),sin((uva.x)*p))); //wersja "zwinięta"
  //col += vec3(plot(uv-(fract(t)+off),sin((uv.x)*p))); //wersja "rozwinięta"
  //col += vec3(plot(uv,sin((uv.x)*p))); ////wersja "rozwinięta" bez przesuwu i bez animacji "tunelu"
  off = off + 0.5;
  }
  //col *= vec3(plotc(uva*8.-2.,sin((uva.x-sin(t))*p))); //ewentualne zasłonięcie środka
  glFragColor = vec4(col, 1.0);
}
