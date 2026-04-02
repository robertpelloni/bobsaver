#version 420

// original https://neort.io/art/bpaj8043p9f4nmb8ap4g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec2 csqr( vec2 a )  { 
    return vec2( a.x*a.x - a.y*a.y, 3.*a.x*a.y  ); }

vec3 map(in vec3 p) {

  float a = time * 0.01;
  p.xz *= mat2(cos(a),sin(a),-sin(a),cos(a));
  a = time * 0.1;
  p.zy *= mat2(cos(a),sin(a),-sin(a),cos(a));
  p.xy *= mat2(cos(a),sin(a),-sin(a),cos(a));
  float res = 0.;
  float res2 = 0.;
  float res3 = 0.;
    
  vec3 c = p;
  for (int i = 0; i < 15; ++i) {
        p =-21.0*abs(p)/dot(p,p) -.8;
        p.yz= csqr(p.yz);
        p=p.zxy;
        res += exp(-18. * abs(dot(p,c)));
        res2 = exp(-13. * abs(dot(p,c)));
        res3 += exp(-12.* abs(dot(p,c))) * (float(i) / 8.0);

        }
  return vec3(res/2.,res2/3.,res3);
  }

void main() {
  vec2 uv = gl_FragCoord.xy / resolution;
  uv -= 0.5;
  uv *= 1.0 + 10. * pow(length(uv - 0.5), -0.8);
  uv += 0.5;  
    
  float vignet = length(uv);
  uv /=1. - vignet * 1.2;
    
  vec3 u = map(vec3(uv*0.1,sin(time*0.05)*0.5));
  vec3 col = u.x*2.5*vec3(0.2,0.1,1.5) + u.y * vec3(0,0.5,1) + u.z * vec3(0.,0.1,1.);
  col *= 1.0 + (sin(time)*0.5+0.5);
    
  
  glFragColor = vec4(col,1);
}
