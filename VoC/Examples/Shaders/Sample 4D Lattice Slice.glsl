#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WdXBzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// 4D Lattice Slice
//
// Matthew Arcus, mla, 2020
//
// Slices through a 4 dimensional cubic lattice.
// <mouse x>: slice angle
// <mouse-y>: scale
//
////////////////////////////////////////////////////////////////////////////////

const float PI = 3.1415927;

mat4 qmat_left(vec4 q) {
  float x = q.x, y = q.y, z = q.z, t = q.w;
  return mat4( t, z,-y,-x, 
              -z, t, x,-y,
               y,-x, t,-z,
               x, y, z, t );
}

mat4 qmat_right(vec4 q) {
  float x = q.x, y = q.y, z = q.z, t = q.w;
  return mat4( t,-z, y,-x, 
               z, t,-x,-y,
              -y, x, t,-z,
               x, y, z, t );
}

vec4 qmul(vec4 p, vec4 q) {
  vec3 P = p.xyz, Q = q.xyz;
  return vec4(p.w*Q+q.w*P+cross(P,Q),p.w*q.w-dot(P,Q));
}

vec4 qrot(vec4 p, vec4 q, vec4 r) {
  p = qmul(q,p);
  p = qmul(p,r);
  return p;
}

void main(void) {
  vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
  float size = 5.0;
  float time = 0.1*time+0.1;
  float theta = 0.618*time;
  //if (mouse*resolution.xy.x > 0.0) {
  //  size *= exp((2.0*mouse*resolution.xy.y -resolution.y)/resolution.y);
  //  theta = PI*(2.0*mouse*resolution.xy.x-resolution.x)/resolution.x;
  //}
  uv *= size;
  float tq = time;
  float tr = theta;
  vec4 q = vec4(sin(tq)*vec3(1,0,0),cos(tq));
  vec4 r = vec4(sin(tr)*vec3(0,1,0),cos(tr));
  vec4 p = vec4(uv,0,0);
  mat4 qm = qmat_left(q)*qmat_right(r);
  float ds = fwidth(p.x);
  p = qm*p; // qrot(p,q,r);
  p = mod(p,2.0);
  vec4 dp = fract(p);
  dp = min(dp,1.0-dp);
  p = floor(p);
  int parity = int(dot(p,vec4(1)))%2;

  mat4x2 dm = transpose(mat2x4(qm));
  dp /= vec4(length(dm[0]),length(dm[1]),length(dm[2]),length(dm[3]));
  float d = min(min(dp.x,dp.y),min(dp.z,dp.w));
  vec3 color = vec3(smoothstep(-ds,+ds,parity==0?d:-d));
  color = mix(vec3(1,0,0),color,smoothstep(0.01,0.02+ds,d));
  color = pow(color,vec3(0.4545));
  glFragColor = vec4(color,1);
}
