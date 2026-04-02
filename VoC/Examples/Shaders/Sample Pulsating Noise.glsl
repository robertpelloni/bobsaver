#version 420

// original https://www.shadertoy.com/view/XlyXRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

precision highp float;
  
const float PI = 3.14159265359;

float random(float p){
      return fract(sin(p) * 10000.0);
} 
  
float noise(vec2 p){
    float t = time / 2000.0;
    if(t > 1.0) t -= floor(t);
    return random(p.x * 14. + p.y * sin(t) * 0.5);
}

vec2 sw(vec2 p){
      return vec2(floor(p.x), floor(p.y));
}
  
vec2 se(vec2 p){
      return vec2(ceil(p.x), floor(p.y));
}
  
vec2 nw(vec2 p){
      return vec2(floor(p.x), ceil(p.y));
}
  
vec2 ne(vec2 p){
      return vec2(ceil(p.x), ceil(p.y));
}

float smoothNoise(vec2 p){
      vec2 inter = smoothstep(0.0, 1.0, fract(p));
      float s = mix(noise(sw(p)), noise(se(p)), inter.x);
      float n = mix(noise(nw(p)), noise(ne(p)), inter.x);
    return mix(s, n, inter.y);
}

mat2 rotate (in float theta){
      float c = cos(theta);
      float s = sin(theta);
    return mat2(c, -s, s, c);
}

float circ(vec2 p){
    float r = length(p);
    r = log(sqrt(r));
    return abs(mod(4.0 * r, PI * 2.0) - PI) * 3.0 + 0.2;
}

float fbm(in vec2 p){
    float z = 2.0;
    float rz = 0.0;
    vec2 bp = p;
    for(float i = 1.0; i < 6.0; i++){
        rz += abs((smoothNoise(p) - 0.5)* 2.0) / z;
        z *= 2.0;
        p *= 2.0;
    }
    return rz;
}

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy - 0.5;
    p.x *= resolution.x / resolution.y;
    p *= 4.0;
    float rz = fbm(p);
    p /= exp(mod(time * 2.0, PI));
    rz *= pow(abs(0.1 - circ(p)), 0.9);
    vec3 col = vec3(0.2, 0.1, 0.643);
      glFragColor = vec4(col, 1.0) / rz; 
}
