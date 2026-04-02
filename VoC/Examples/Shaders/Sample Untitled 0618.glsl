#version 420

// original https://neort.io/art/c1507743p9f8fetmsrug

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
    p.z-=-time*2.;
    p.z=mod(p.z,4.)-2.0;
    for(int i=0;i<8;i++)
    {
        p.xy=pmod(p.xy,8.);
        p.y-=2.0;
    }
    return dot(abs(p),normalize(vec3(1,0,1)))-0.2;
}
void main(){
    vec4 fragColor = vec4(0.0);
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
      fragColor += 5./ix;
      fragColor += normalize(vec4(100,35,00,0))*10./ix;
    }
    glFragColor = fragColor;
    glFragColor.w = 1.0;
}
