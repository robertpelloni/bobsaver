#version 420

// original https://www.shadertoy.com/view/MdjBW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592654

float random(vec2 st) {
  return fract(
      sin(
          dot(st.xy,vec2(12.9898, 78.233))
          ) * 43758.5453123);
}

float noise(vec2 st) {
  vec2 i = floor(st);
  vec2 f = fract(st);

  float ll_corner = random(i);
  float lr_corner = random(i + vec2(1.0,0.0));
  float ul_corner = random(i + vec2(0.0,1.0));
  float ur_corner = random(i + vec2(1.0,1.0));

  vec2 u = smoothstep(0.0, 1.0, f);

  return mix(ll_corner, lr_corner, u.x) +
      (ul_corner - ll_corner)*u.y*(1.0 - u.x) +
      (ur_corner - lr_corner)*u.x*u.y;
}

float fbm(vec2 st) {
  float val = 0.0;
  float amp = 1.0;
  val += noise(st); st *= 2.0;
  val += 0.5000*noise(st); st *= 2.0;
  val += 0.2500*noise(st); st *= 2.0;
  val += 0.1250*noise(st); st *= 2.0;
  val += 0.0625*noise(st); st *= 2.0;

  return val / 0.9375;
}

float fbmWarp2(in vec2 st, out vec2 q, out vec2 r) {
  q.x = fbm(st);
  q.y = fbm(st + vec2(4.7, 1.5));

  r.x = fbm(st + 4.0*q + vec2(1.4, 9.1));
  r.y = fbm(st + 4.0*q + vec2(8.7, 2.9));
  return fbm(q + st);
}

vec3 hsb2rgb( in vec3 c ){
  vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                           6.0)-3.0)-1.0,
                   0.0,
                   1.0 );
  rgb = rgb*rgb*(3.0-2.0*rgb);
  return c.z * mix(vec3(1.0), rgb, c.y);
}

vec3 hsb2rgb(float h, float s, float b) {
  return hsb2rgb(vec3(h,s,b));
}

float uSin(float x) {
  return 0.5*sin(x) + 0.5;
}

float uCos(float x) {
  return 0.5*cos(x) + 0.5;
}

void main(void) {
  vec2 st = gl_FragCoord.xy / resolution.xy;
  st = 2.0*st - 1.0;
  st.x *= resolution.x / resolution.y;

  vec3 color = vec3(0.0);

  float a = atan(st.y, st.x);
  float rad = length(st);

  float ss = 0.5 + 0.5*sin(3.0*time);
  float anim = 1.0 + 0.4*ss*(1.0 - rad);
  rad *= anim;

  a += 0.15*sin(fbm(10.0*st)) + 0.97;

  float flowerR = 0.35 + 0.28*sin(8.0*a);
  float flowerR2 = 0.35 + 0.28*sin(8.0*a);
  float petalR = 0.35 + 0.28*sin(8.0*a + PI);
  float petalR2 = 0.35 + 0.28*sin(8.0*a + PI);
  flowerR2 += 0.2*sin(fbm(10.0*st + vec2(0.4,3.7)));
  petalR2 += 0.2*sin(fbm(10.0*st + vec2(0.13,7.7)));

  flowerR *= uSin(2.0*time/5.)*anim;
  petalR *= uSin(2.0*time/2.)*anim;

  flowerR2 *= uCos(2.0*time/3.)*anim;
  petalR2 *= uCos(2.0*time/7.)*anim;

  if (rad <= flowerR) {
    color = vec3(0.0);
    flowerR = rad / flowerR;
    vec2 q;
    vec2 r;
    float f = fbmWarp2(15.0*st, q, r);
    color = mix(color, hsb2rgb(0.45,0.99,0.99), f);

    f = fbm(vec2(4.0*a, 7.0*flowerR));
    color = mix(color, hsb2rgb(0.55,0.99,0.99), f);

    color = mix(color, hsb2rgb(0.95,0.7,0.2 + length(q)), smoothstep(0.0,1.3,flowerR));
  }
  if (rad <= petalR) {
    petalR = rad / petalR;
    vec2 q;
    vec2 r;
    float f = fbmWarp2(25.0*st, q, r);
    color += hsb2rgb(0.65,f,0.95);

    f = fbm(vec2(8.0*a, 3.0*petalR));
    color = mix(color, hsb2rgb(0.6,0.99,0.99), f);

    color = mix(color, vec3(0.9,0.8,0.3), smoothstep(0.0,1.0,petalR));
    color = mix(color, vec3(0.9,0.6,0.7), smoothstep(0.0,1.5,flowerR));
  }
  if (rad <= flowerR2) {
    color = vec3(0.0);
    flowerR2 = rad / flowerR2;
    vec2 q;
    vec2 r;
    float f = fbmWarp2(9.0*st, q, r);
    color += hsb2rgb(0.15,f,0.95);

    a += 0.15*sin(f);
    f = fbm(vec2(8.0*a, 9.0*flowerR2));
    color = mix(color, hsb2rgb(0.0,0.99,0.99), f);

    color = mix(color, hsb2rgb(0.8,0.9,r.x), smoothstep(0.0,1.3,petalR));
    color = mix(color, hsb2rgb(0.1,0.9,length(q)), smoothstep(0.0,1.3,flowerR));
    color = mix(color, hsb2rgb(0.5,0.9,f), smoothstep(0.0,1.5,flowerR2));
  }
  if (rad <= petalR2) {
    petalR2 = rad / petalR2;
    vec2 q;
    vec2 r;
    float f = fbmWarp2(5.0*st, q, r);
    color += hsb2rgb(0.15,f,0.95);

    a += 0.15*sin(f);
    f = fbm(vec2(9.0*a, 3.0*petalR2));
    color = mix(color, hsb2rgb(0.6,0.99,0.99), f);

    color = mix(color, vec3(0.2,0.9,0.8), smoothstep(0.0,1.0,petalR));
    color = mix(color, hsb2rgb(0.12,1.0,f), smoothstep(0.0,1.3,petalR2));
    color = mix(color, vec3(0.9,0.6,r.x), smoothstep(0.0,1.5,flowerR));
    color = mix(color, vec3(0.9,0.6,length(q)), smoothstep(0.0,1.5,flowerR2));
  }

  glFragColor = vec4(color, 1.0);
}
