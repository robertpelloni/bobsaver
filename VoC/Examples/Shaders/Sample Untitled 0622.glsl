#version 420

// original  https://neort.io/art/c188sak3p9f8fetmtb2g

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define TAU atan(1.)*8.
vec2 pmod(vec2 p, float n)
{
  float a=mod(atan(p.y, p.x),TAU/n)-.5 *TAU/n;
  return length(p)*vec2(sin(a),cos(a));
}
float map(vec3 p){
  p.xy*=rot(time*.1);
  p.xz*=rot(time*.2);
  float s=1.;
  for(int i=0;i<4;i++){
    p=abs(p)-1.3;
    if(p.x<p.y)p.xy=p.yx;
    if(p.x<p.z)p.xz=p.zx;
    if(p.y<p.z)p.yz=p.zy;
    p.xy*=rot(time*0.02);
    //p.zy*=rot(time*0.02);
    //p.xz*=rot(time*0.02);
  }
  return length(p.xy)-.08;
}
void main(){
    vec4 fragColor = vec4(0.0);
    vec2 uv=(gl_FragCoord.xy-.5*resolution)/resolution.y;
    vec3 rd=normalize(vec3(uv,1));
    vec3 p=vec3(0,0,-18);
    float d=1.,ix;
    for(int i=0;i<99;i++){
      p+=rd*(d=map(p));
      ix++;
      if (d<.001){break;}
    }
    if(d<.001) {
      fragColor += 1./ix;
      fragColor += normalize(vec4(4,5,5,0))*9./ix;
    }
    glFragColor = fragColor;
    glFragColor.w = 1.0;
}
