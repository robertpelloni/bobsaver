#version 420

// original https://www.shadertoy.com/view/XtKXWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Checkerboard Flight
//
// I've always loved this kind of effects
//
// Made from scratch on my phone when I was on vacation using an app on Android called ShaderBox
// Tried to keep the code as readable as possible.

// Objects
float plane(float p, float dist){
  return p-dist;
}

// Textures
vec3 checkboard(vec2 p,float size){
  p*=size;
  vec2 f=fract(p.xy)-0.5;
  return vec3(f.x*f.y>0.0?1.0:0.0);
}

// Distance function
float objdistance(vec3 p){
   return min(plane(p.y,-2.0),plane(-p.y,-1.0));
   //return min(plane(sin(p.z)*0.3+sin(p.x+time*8.0)*0.3+p.y,-2.0),plane(-p.y,-1.0));
}

// Object Color
vec3 objcolor(vec3 p){
  return checkboard(p.xz,0.4);
}

void main(void) {
    
  vec2 uv=gl_FragCoord.xy/resolution.xy-0.5;
  uv.x*=resolution.x/resolution.y;

  //Camera
  vec3 lookat=vec3(0.0,-2.0,-time*16.0);
  vec3 cam=vec3(sin(time*2.0)*4.0,0.0,10.0)+vec3(0.0,0.0,lookat.z);
  vec3 up=vec3(sin(time*2.0+3.14)*0.5,1.0,0.0);

  float camdist=2.0;
  float camsize=2.0;
  float maxdist=50.0;
  float preci=0.001;

  vec3 v=cam-lookat;
  vec3 camx=normalize(cross(up,v))*camsize;
  vec3 camy=normalize(cross(v,camx))*camsize;

  vec3 campoint=cam-normalize(v)*camdist+
      camx*uv.x+
      camy*uv.y;

  vec3 ray=normalize(campoint-cam);

  //Ray marching
  vec3 p=campoint;
  float d=maxdist;
  float s=0.0;
  for(int i=0;i<64;i++){
      d=objdistance(p);
      s+=d;
      if (d<preci) break;
      if (s>maxdist) break;
      p=campoint+ray*s;
  }

  float fadeout=max(maxdist-s,0.0)/maxdist;
  glFragColor = vec4(objcolor(p)*fadeout, 1.0);
}
