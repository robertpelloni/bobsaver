#version 420

// original https://neort.io/art/c1errgk3p9f8fetmuk40

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
float map(vec3 p)
{
    p.xy*=rot(time*.3);
    p.yz*=rot(time*.2);
    for(int i=0;i<8;i++)
    {
        p.xy = pmod(p.xy,6.);
        p.y-=2.;
        float n=11.;
        p.yz = pmod(p.yz,abs(mod(time*0.1+n/2.,n)-n/2.)+1.);
        p.z-=3.;
    }
    return dot(abs(p),normalize(vec3(1,0,1)))-.1;
}
void main(){
    vec4 display = vec4(0.0);
    vec2 uv=(gl_FragCoord.xy-.5*resolution)/resolution.y;
    vec3 rd=normalize(vec3(uv,1));
    vec3 p=vec3(0,0,-70);
    float d=1.,ix;
    for(int i=0;i<99;i++){
      p+=rd*(d=map(p));
      ix++;
      if (d<.001){break;}
    }
    if(d<.001) {
      display += 6./ix;
      display += normalize(vec4(0,60,100,0))*16./ix;
    }
    display.w = 1.0;
    glFragColor = display;
}
