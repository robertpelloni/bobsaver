#version 420

// original https://neort.io/art/bptf57c3p9fefb924v70

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

float sdCube(vec3 p, vec3 s){
  p = abs(p)-s;
  return length(max(p,0.));
}

float sdTube(vec2 p, float r){
  return length(p) - r;
}

float h12(vec2 p){
  return fract(sin(dot(p,vec2(12.5314,23.125)))*43561.5215);
}

vec3 hsv2rgb(float h, float s, float v){
  return mix(vec3(1.),clamp(abs(fract(vec3(1.,1./3.,2./3.)+h)*6.-3.)-1.,0.,1.),s)*v;
}

vec4 map(vec3 p){
  vec3 q = p;
  p.x += .5;
  p.xz = fract(p.xz+.5)-.5;
  vec3 p1 = q;
  p1.x += .5;

  vec2 p1i = p1.xy;
  //p1i.x += .5;
  p1i = floor(p1i);
  p1.z += time*(h12(p1i)-.5)*4.;
  p1 = fract(p1)-.5;

  return vec4(hsv2rgb(q.z*.02,1.-.2*(q.y+.5),1.),min(sdTube(p.xz,-.01),sdCube(p1,vec3(.04))));
}

vec3 glow(vec3 ro,vec3 rd){
  vec3 rp = ro;
  float d;
  vec4 m;
  vec3 a;
  for(int i=0;i<32;i++){
    m = map(rp);
    d = m.w;
    a += exp(-d*50.)*m.rgb;
    rp += d * rd * .9;
    if(d < .001)break;
  }
  m = map(rp);
  return a.rgb;
}

void main(void){
  vec2 p = (2.*gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);
  vec3 color = vec3(0.);
  vec3 cp = vec3(.2*time,0.,.2*time);
  vec3 ww = vec3(0.,0.,1.);
  vec3 uu = normalize(cross(ww,vec3(0.,1.,0.)));
  vec3 vv = normalize(cross(uu,ww));
  float sd = 3. - length(p);
  vec3 rd = normalize(uu*p.x+vv*p.y+ww*sd);
  vec3 ro = cp+rd;

  color = glow(ro,rd);

  glFragColor = vec4(color,1.);
}
