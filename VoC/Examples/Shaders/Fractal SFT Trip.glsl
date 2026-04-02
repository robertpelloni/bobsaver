#version 420

// original https://www.shadertoy.com/view/WlXyR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//SFT trip
#define time time
#define rez resolution.xy

vec2 cmul(vec2 a, vec2 b){return mat2(a,-a.y,a.x)*b;}

const int CYC=4;//only 4 real orbit points
const float fCYC=4.;
vec2 O[CYC];
void FillOrb(vec2 Z){
  vec2 Z0=Z;
  for(int i=0;i<CYC;i++){
    O[i]=Z;
    Z=cmul(Z,Z)+Z0;
  }
}
float mndfk(vec2 dZ){//fake mandelbrot using sft math from K.I.Martin
  vec2 Z,dC=dZ;
  float iters=24.+time*8.,i=0.,m=dot(dZ,dZ);
  for(i=0.;i<iters;i+=1.){
    Z=O[int(mod(i,fCYC))];
    dZ=2.*cmul(Z,dZ)+cmul(dZ,dZ)+dC;
    m=dot(dZ,dZ);
    if(m>40.0)break;
  }
  return (iters-i+1.33*log(log(m)))/iters;
}
void main(void) {
  vec2 uv=.5*(2.0*gl_FragCoord.xy-rez)/rez.x;
  FillOrb(vec2(-.9,0.26)+vec2(0.05,0.01)*sin(time*0.1*exp(-time*.0001)));
  float zoom=exp(-time*.5);
  float a=mndfk(uv*zoom);//just one long zoom
  uv+=vec2(0.01);
  //float a2=mndfk(uv*zoom),a3=a2-a;a=(a+a2)*.5;
  vec4 O=vec4(mix(vec3(-0.25),vec3(2.5+sin(a*100.0),cos(a*1000.)*1.5,2.),a),1);
  O+=mix(vec4(0),vec4(1.,.9,0,0),fwidth(a)*2.);//pow(a3,2.)*20.);
  glFragColor=O;
}
