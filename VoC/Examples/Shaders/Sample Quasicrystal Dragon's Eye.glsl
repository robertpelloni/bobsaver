#version 420

// original https://www.shadertoy.com/view/wdXfz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI          3.141592654
#define TAU         (2.0*PI)
#define LAYERS      6
#define FBM         3
#define LIGHTNING   3
#define DISTORT     1.4
#define TIME        time
#define TTIME       (TAU*TIME)

float wave(float theta, vec2 p) {
  return (cos(dot(p,vec2(cos(theta),sin(theta)))));
}

float noise(vec2 p, float time) {
  float sum = 0.;
  float a = 1.0;
  for(int i = 0; i < LAYERS; ++i)  {
    float theta = float(i)*PI/float(LAYERS);
    sum += wave(theta, p)*a;
    a*=DISTORT;
  }

  return abs(tanh(sum+1.0+0.75*cos(time)));
}

float fbm(vec2 p, float time) {
  float sum = 0.;
  float a = 1.0;
  float f = 1.0;
  for(int i = 0; i < FBM; ++i)  {
    sum += a*noise(p*f, time);
    a *= 2.0/3.0;
    f *= 2.31;
  }

  return 0.45*(sum);
}

vec3 lightning(vec2 pos, float offset) {
  vec3 col = vec3(0.0);
  vec2 f = vec2(0);
         
  const float w=0.15;
          
  for (int i = 0; i < LIGHTNING; i++) {
    float time = TIME + 0.5*float(i);   
    float d1 = abs(offset * w / (0.0 + offset - fbm((pos + f) * 3.0, time)));
    float d2 = abs(offset * w / (0.0 + offset - fbm((pos + f) * 2.0, 0.9 * time + 10.0)));
    col += vec3(clamp(d1, 0.0, 1.0) * vec3(0.1, 0.5, 0.8));
    col += vec3(clamp(d2, 0.0, 1.0) * vec3(0.7, 0.5, 0.3));
  }
          
  return (col);
}

vec3 postProcess(vec3 col, vec2 q) {
  col=pow(clamp(col,0.0,1.0),vec3(0.75)); 
  col=col*0.6+0.4*col*col*(3.0-2.0*col);  // contrast
  col=mix(col, vec3(dot(col, vec3(0.33))), -0.4);  // satuation
  col*=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);  // vigneting
  return col;
}

void rot(inout vec2 p, float a) {
  float c = cos(a);
  float s = sin(a);
  p = vec2(p.x*c + p.y*s, -p.x*s + p.y*c);
}

vec3 normal(vec2 p, float time) {
  vec2 v;
  vec2 w;
  vec2 e = vec2(0.00001, 0);
  
  vec3 n;
  n.x = fbm(p + e.xy, time) - fbm(p - e.xy, time);
  n.y = 2.0*e.x;
  n.z = fbm(p + e.yx, time) - fbm(p - e.yx, time);
  
  return normalize(n);
}

vec3 dragonEye(vec2 p) {
  vec2 pp = 10.0*p;

  rot(p, -0.75); 
  p *= vec2(1.1/tanh(1.0 + length(p)), 1.0);
  float l = length(p);
  
  float dd = 0.2 + 0.65*(-0.5 + 1.75*(0.5 + 0.5*cos(3.0*l-TTIME/12.0)))*tanh(1.0/((pow(l, 4.0) + 2.0)));
  dd *= smoothstep(9.0, 12.0, TIME-l*2.0);
  vec3 col = vec3(0.0);
  float f = fbm(pp, TIME*0.1);
  vec3 ld = normalize(vec3(p.x, 0.5, p.y));
  vec3 n = normal(pp, TIME*0.1);
  float diff = max(dot(ld, n), 0.0);
  col += vec3(0.5, 1.0, 0.8)*pow(diff, 20.0)/(0.5+dot(p, p));
  col += lightning(pp, dd);
  col *= pow(vec3(f), vec3(1.5, 5.0, 5.0));
//  col += -0.1+0.3*vec3(0.7, 0.2, 0.4)*vec3(tanh((pow(0.6/f, 10))));
  return col;
}

void main(void) {
  vec2 q = gl_FragCoord.xy/resolution.xy;    
  vec2 p = -1.0 + 2.0*q;

  p.x *= resolution.x/resolution.y;    
  
  vec3 col = dragonEye(p);
  
  col = postProcess(col, q);

  col *= smoothstep(0.0, 4.0, TIME);
  
  glFragColor = vec4(col, 1.0);  
}
