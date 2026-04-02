#version 420

// original https://neort.io/art/bp4igrk3p9f2ibmm0qn0

uniform vec2  resolution;
uniform vec2  mouse;
uniform float time;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float rect(vec2 p ){
  return step(p.x,0.95) * step(0.05,p.x) * step(p.y,0.95) * step(0.05,p.y);
}

float hash(vec2 p){
  return fract(45666.5316 * sin(dot(p,vec2(12.661,67.2651))));
}

float noise(vec2 p){
  vec2 i = floor(p);
  vec2 f = fract(p);

  float a0 = hash(i + vec2(0.0,0.0));
  float a1 = hash(i + vec2(1.0,0.0));
  float a2 = hash(i + vec2(0.0,1.0));
  float a3 = hash(i + vec2(1.0,1.0));

  vec2 u = smoothstep(0.0, 1.0,f);

  return mix(mix(a0,a1,u.x),mix(a2,a3,u.x),u.y);
}

mat2 rot(float a){
  float c= cos(a),s = sin(a);
  return mat2(c,s,-s,c);
}

float beat = 60.0/140.0;

float PI = acos(-1.0);

void main(){
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x,resolution.y);
    
     
    p *= rot(- PI / 3.0);

    p.y -= 0.1 * time;

float h = 0.0;
 vec2 ip = floor(p) ;
 float t = time * beat;
float count = 0.0;

for(int i= 0 ; i < 5; i++){
  p *= 2.0;
   h = noise(floor(p) + ip + t);
   p = fract(p);
   if(h < 0.75){
     count = float(i);
     break;
   }
}

    vec3 c = vec3(rect(p));

    c *= hash(vec2(count/5.0 + 1.0));

    c = mix(vec3(0.0,0.1,0.3),vec3(0.1,0.5,0.9),c.x);
    glFragColor = vec4(c,1.0);
  }
