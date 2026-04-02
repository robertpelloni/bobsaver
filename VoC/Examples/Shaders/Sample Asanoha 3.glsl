#version 420

// original https://neort.io/art/biml34s3p9f9psc9obs0

// Asanoha
// author: @amagitakayosi

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141503
#define SQRT3 1.7320508

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
     return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v)
  {
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //   x0 = x0 - 0.0 + 0.0 * C.xxx;
  //   x1 = x0 - i1  + 1.0 * C.xxx;
  //   x2 = x0 - i2  + 2.0 * C.xxx;
  //   x3 = x0 - 1.0 + 3.0 * C.xxx;
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

// Permutations
  i = mod289(i);
  vec4 p = permute( permute( permute(
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients: 7x7 points over a square, mapped onto an octahedron.
// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
  //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
                                dot(p2,x2), dot(p3,x3) ) );
}

vec2 rot(vec2 p, float t) {
  float c = cos(t), s = sin(t);
  return mat2(c, -s, s, c) * p;
}

vec2 getCenter(vec2 p) {
  mat2 skew = mat2(1. / 1.1457, 0, 0.5, 1);
  mat2 inv = 2. * mat2(1., 0, -0.5, 1. / 1.1457);

  // Position in grid cells
  vec2 cellP = fract(skew * rot(p, PI / 6.0));

  vec2 p3;

  if (cellP.y > cellP.x)
  {
    cellP = inv * cellP;
    vec2 p2 = cellP - vec2(-2., 0);
    if (length(p2) < 2.) {
      p3 = p2;
    }
    else {
      p3 = cellP;
    }
  }
  else {
    cellP = inv * cellP;
    vec2 p2 = cellP + vec2(-1, SQRT3 *1.01);

    if (length(p2) < 2.) {
      p3 = p2;
    }
    else {
      p3 = cellP;
    }
  }

  p3 = rot(p3, -PI / 6.0);

  return p - p3;
}

void main( void ) {
  vec2 p = (gl_FragCoord.xy * 2. - resolution) / min(resolution.x, resolution.y);
  vec4 c = vec4(0, 0, 0, 1);

  // base texture
  vec4 base = vec4(0);
  base +=
      snoise(vec3(p * 3., time * .2)) * .7 +
      snoise(vec3(p * 20., time * .1)) * .4;
  base += vec4(.9, .6, .2, .7);
  c += base;

  // Draw asanoha
  mat2 skew = mat2(1. / 1.1457, 0, 0.5, 1);
  mat2 inv = 2. * mat2(1., 0, -0.5, 1. / 1.1457);
  vec2 p2 = skew * p * 6.;
  vec2 fp2 = floor(p2);
  p2 = fract(p2);

  if (p2.y < p2.x) {
    p2 = p2.yx;
    c.r += .04;
  }

  // 三角形の重心の座標
  vec2 tc = (vec2(0, 1) + vec2(0) + vec2(1)) / 3.;

  // 重心からの距離。skewを解除
  vec2 cellP = inv * (p2 - tc);

  // 重心からの角度を得る
  float a = atan(cellP.x, cellP.y) + PI; // 0 to 2PI
  // a += time + fp2.x + fp2.y; // 時間でアニメーション

  float lines = 0.;
    
  // 三角形を描く。
  vec2 cp  = cellP;
  if (a < PI * 2. / 3.) { cp = rot(cp, PI * 2. / 3.); }    
  else if (a < PI * 4. / 3.) { cp = rot(cp, -PI * 2. / 3.); }
  else { cp = rot(cp, -PI * 2. / 3.); }
    
  lines += smoothstep(.5, .56, cp.y - abs(cp.x) * .07);    
    
  // 角度で線を引く。
  // 線幅は中心からの距離に応じて変える
  float a2 = fract(a / (2. / 3. * PI));
  float l = length(cellP);
//  float w = .1 - l * .08; // ほんとはこっちの方がきれい
  float w = .1 - l * .092; // 端っこに何か出ていい感じになったのでこっちで
  lines += 1. - smoothstep(.0, w, a2) * smoothstep(1., 1. - w, a2);
    
  c *= lines;
    
  // 三角形ごとにノイズかける
  float cn = snoise(vec3(fp2 *3., time * .1));
  c.rgb *= 1. + cn;    
    
  // 中心からの距離で波打たせてみる
  c *= sin(l * 2. + time + cn * 3.) + .2 + .4;
    
  // 透明の処理
  c = mix(vec4(0,0,0,1), c, c.a);    
    
  glFragColor = c;
}
