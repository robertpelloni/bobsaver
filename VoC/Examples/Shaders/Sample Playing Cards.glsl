#version 420

// original https://neort.io/art/bp4kkvc3p9f2ibmm0rl0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define PI acos(-1.0)

float hash(vec2 uv){
  return fract(41531.16361 * sin(dot(uv,vec2(12.613,78.5316))));
}

mat2 rot(float a){
  float c = cos(a), s = sin(a);
  return mat2(c,s,-s,c);
}

float sdCircle(vec2 p,float r){
  return length(p) - r;
}

float sdBox(vec2 p, vec2 s){
  vec2 d = abs(p) - s;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdLine(vec2 p, vec2 a, vec2 b, float w){
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
  return length(pa - h * ba) - w;
}

float sdTriangleIsoscales(vec2 p,vec2 q){
  p.x = abs(p.x);
  vec2 a = p - q * clamp(dot(p,q)/dot(q,q),0.0,1.0);
  vec2 b = p - q * vec2( clamp(p.x/q.x,0.0,1.0), 1.0);
  float s = -sign(q.y);
  vec2 d = min( vec2( dot(a,a), s*(p.x*q.y-p.y*q.x) ),
                vec2( dot(b,b), s*(p.y-q.y)));
  return -sqrt(d.x)*sign(d.y);
}

float sdHeart(vec2 p,float s){
  p /=s;
  p.x = abs(p.x);
  float d = sdLine(p,vec2(-0.125,-0.125),vec2(0.25,0.25),0.25);
  return d;
}

float sdSpade(vec2 p,float s){
  p /= s;
  p.y = - p.y + 0.25;
  float h = sdHeart(p,1.0);
  float d = sdTriangleIsoscales(p - vec2(0.0,0.3),vec2(0.1,0.5));
  h =min(h,d);
  return h;
}

float sdDia(vec2 p, float s){
  p.x /= 0.7;
  p *= rot(PI * 0.25);
  float d = sdBox(p,vec2(s*0.4));
  return d;
}

float sdClub(vec2 p,float s){
  p /= s* 1.5;
  float d0 = sdCircle(p - vec2(0.0,0.2),0.2);
  float d1 = sdCircle(p - vec2(0.15,0.0),0.2);
  float d2 = sdCircle(p - vec2(-0.15,0.0),0.2);
  d0 = min(d0,min(d1,d2));
  p.y = -p.y;
  float d = sdTriangleIsoscales(p - vec2(0.0,0.1),vec2(0.05,0.25));
  d0 =min(d0,d);
  return d0;
}

float sdAce(vec2 p,float s){
  p /= s * 2.0;
    p.x = abs(p.x);
    float d = sdLine(p,vec2(-0.05,0.3),vec2(0.125,-0.25),0.025);
    float d1 = sdLine(p,vec2(0.0,-0.1),vec2(0.075,-0.1),0.0125);
    float b0 = sdBox(p - vec2(0.125,-0.25),vec2(0.05,0.0125));
    d = min(d,min(d1,b0));
    float b = sdBox(p - vec2(0.0,-0.375),vec2(0.25,0.125));
    d = max(d,-b);
  return d;
}

vec3 tex(vec2 uv){
  // Tileing
  uv *= 4.0;
  float time = mod(time * 2.0,15.0);

  // time = 12.0;
  float t0 = clamp(time,0.0,1.0);
  t0 = smoothstep(0.0,1.0,t0);
  float t1 = clamp(time - 1.0 ,0.0 ,10.0);
  float t2 = clamp(time - 10.0,0.0,1.0);
  t2 = smoothstep(0.0,1.0,t2);

  vec2 iuv0 = floor(uv);
  float h0 = floor(hash(vec2(iuv0.x)) * 3.0);
  
  uv.y += (t0 + t1 + t2)/(h0 + 1.0);
  
  vec2 iuv = floor(uv);
  iuv.y = mod(iuv.y,floor(12.0/(h0 + 1.0)));

  vec2 fuv = fract(uv) - 0.5;

  // Heart
  float d0 = sdHeart(fuv,0.55);
  // Dia
  float d1 = sdDia(fuv,0.5);
  // Spade
  float d2 = sdSpade(fuv,0.5);
  // Club
  float d3 = sdClub(fuv,0.5);
  // Ace
  float d4 = sdAce(fuv,0.5);

  // 各タイルのランダムな値
  float h = hash(iuv);
  // 最終的な距離関数
  float d = 1.0;
  // 最終的な色
  vec3 col = vec3(0.0);

  // ランダムな値によって出す柄を変える
  if(h < 0.225){
    d = min(d,d0);
  } else if(h >= 0.225 && h < 0.45){
    d = min(d,d1);
  } else if(h >= 0.45 && h < 0.675){
    d = min(d,d2);
  } else if(h >= 0.675 && h < 0.9){
    d = min(d,d3);
  } else {
    d = min(d,d4);
  }

  // 背景をぬるために柄部分だけ抜く
  float bg = max(0.0,-d);
  // 模様の描画
  vec3 c = vec3(smoothstep(0.001,0.0,d));

  // h < 0.5 がハートとダイア、h > 0.5はスペードとクラブなので
  // それで赤と黒を色分け
  c *= h < 0.5 ? vec3(1.0,0.0,0.0) : vec3(0.0,0.0,0.0);

  // 背景カラーを白塗り
  c += smoothstep(0.001,0.0, bg);
  return c;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec3 c = tex(uv);

    glFragColor = vec4(c, 1.0);
}
