#version 420

// original https://neort.io/art/c0odlfk3p9f9t0pjahc0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float hash(float n){
  return fract(43153.5466 * sin(n * 12.516));
}

float hash(vec2 n){
  return fract(43153.64513 * sin(dot(n,vec2(12.435,78.434))));
}

float noise(float n){
  float i = floor(n);
  float f = fract(n);
  
  float u = smoothstep(0.0,1.0,f);
  return mix(hash(i),hash(i+1.),u);
}

vec2 n2(float n){
  return vec2(noise(n),noise(n + 536.531));
}

vec2 hash2(vec2 n){
  return vec2(hash(n),hash(n + vec2(53.6,61.1)));
}

float voronoi(vec2 p){
  vec2 i = floor(p);
  vec2 f = fract(p);
  
  vec2 res = vec2(8.0);
  for(int x = -1; x <= 1; x++){
    for(int y = -1; y <= 1; y++){
      vec2 n = vec2(x,y);
      vec2 hp = hash2(n + i);
      vec2 np = n + hp - f;
      //float l = length(np);
      float l = max(abs(np.x),abs(np.y));
      if(l < res.x){
        res.y = res.x;
        res.x = l;
      } else if(l < res.y){
        res.y = l;
      }
    }
  }
  res = sqrt(res);
  return res.y - res.x;
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec2 p0 = p;
    float t = time;
    float ft = fract(t);
    float it = floor(t);
    
    vec2 n = n2(it + pow(clamp(ft * 2.0,0.0,1.0),1.5));
    p += n * 5.0;
  
    float v = voronoi(p);
    float v2 = voronoi(p * 2.0 + vec2(10.24,61.6));

    vec3 col = vec3(pow(smoothstep(0.01,0.0,v) + smoothstep(0.05,0.0,v2) * 0.7,3.1));
    col = mix(vec3(0.1,0.1,0.2),vec3(0.6,0.9,1.0),col.r);
    col *= smoothstep(2.,0.0,length(p0));

    glFragColor = vec4(col, 1.0);
}
