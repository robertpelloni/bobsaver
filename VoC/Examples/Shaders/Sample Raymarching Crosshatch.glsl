#version 420

// original https://neort.io/art/bpm59pc3p9fbkbq83qlg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float pi = acos(-1.0);
const float pi2 = pi*2.;
mat2 rot (float a){
  float c = cos(a),s = sin(a);
  return mat2(c,s,-s,c);
  }

vec2 pmod(vec2 p, float r) {
    float a =  atan(p.x, p.y) + pi/r;
    float n = pi2 / r;
    a = floor(a/n)*n;
    return p*rot(-a);
}

float rand(float n){
    return fract(sin(n)*19273.18364638);
}

float sdbox(vec3 p,vec3 s){

    p = abs(p)-s;
    return length (max(p,0.0))+min(max(p.x,max(p.y,p.z)),0.0);
}

float dist(vec3 p){
  
  float s = floor(time);
  float r = 0.0;
  if(s/2.0>=0.0){
     r = -sin(time);
  }else{
    r = cos(time);
  }
    p.z *= (r);
    p.xy *= rot(0.5);
    p.zy *= rot(0.5);
    p.y = mod(p.y,3.0)-1.5;
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.1,2.5,0.1);
    float d = length(p.xy)-0.00;
    for (int i = 0;i<10; i++){
      p = abs(p)-1.0;
      p.xz *= rot(s);
      float d1 = length(p.xy)-0.005;
      float d2 = length(p.xz)-0.005;
      d1 = min(d1,d2);
      // d = d1;
      d = min(d1,d);
    }
    return abs(d);
}
vec3 hsv(vec3 rgb){
  return ((clamp(abs(fract(rgb.x+vec3(0,2,1)/3.)*6.-3.)-1.,0.,1.)-1.)*rgb.y+1.)*rgb.z;
}

void main (void){
    vec2 p = (gl_FragCoord.xy * 2. -resolution) /min(resolution.x, resolution.y);
    vec3 ca = vec3(0.,0.,-2.5);
    ca.xz *= rot(time);
    float sc = 2.5;
    vec3 ray = normalize (vec3(p,sc));
    float depth = 0.0;
    vec3 col1 = vec3 (0.0);
    float ac = 0.0;
    vec3 rp = vec3(0.0);
    for(int i = 0; i < 100; i++){
      rp = ca+ray*depth;
      float d = dist(rp);
      d = max(abs(d),0.001);
        ac += pow(exp(-d*5.),5.0);
      depth += d*0.5;
    }
    col1 = (vec3(ac*0.01));
    col1 /= hsv(normalize(rp));
    glFragColor = vec4(col1,1.0);

}

