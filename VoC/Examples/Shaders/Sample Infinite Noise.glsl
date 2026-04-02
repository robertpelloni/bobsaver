#version 420

// original https://www.shadertoy.com/view/3dlSDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  
                      0.366025403784439, 
                     -0.577350269189626,
                      0.024390243902439); 
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

  i = mod289(i);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
    + i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

// Above noise is from https://github.com/hughsk/glsl-noise/blob/master/simplex/2d.glsl

#define MAX_ITER 3

vec2 trans(vec2 uv) {
    // float timeF = pow(2.0, time * 0.7);
    float timeF = pow(2.0, mod(time * 0.7, float(MAX_ITER)) + float(MAX_ITER) * 4.0);
    vec2 m = (mouse*resolution.xy.xy - resolution.xy / 2.0) / resolution.xx;
    if (mouse*resolution.xy.xy==vec2(0) ) m = vec2(0);
    return (uv - m) * timeF + m;
}

float infNoise(vec2 uv_raw, float baseFreq, vec2 eye_raw, float lodSpeed) {
    
    vec2 uv = trans(uv_raw);
    vec2 eye = trans(eye_raw);
    
    float lodLevel = length(eye - uv) * lodSpeed;
    uv *= baseFreq;
    float f = 0.0;
    float t = 3.0 -(log(lodLevel) / log(2.0));
    int i = int(floor(t)) - MAX_ITER;
    int rou = 0;
    float l = t - floor(t);
    f += (1.0 - l) * snoise(uv * pow(2.0, float(i - 1)));
    for (; i < int(floor(t)); ++i) {
        f += snoise(uv * pow(2.0, float(i)));
        rou++;
    }
    f += l * snoise(uv * pow(2.0, float(i)));
    return f / float(MAX_ITER);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.0) / resolution.xx;
    vec2 m = (mouse*resolution.xy.xy - resolution.xy / 2.0) / resolution.xx;
    if (mouse*resolution.xy.xy==vec2(0) ) m = vec2(0);
    glFragColor.xyz = vec3(infNoise(uv, 2.0 , m, 1.0) * 0.5 + 0.5);
}
