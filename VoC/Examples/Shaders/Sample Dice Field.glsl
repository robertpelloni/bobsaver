#version 420

// original https://www.shadertoy.com/view/WtlGWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//ACME Labs rainbow colors
vec3[ 5] rbow = vec3[5]
  ( vec3(1., .0  , 0.)
  , vec3(1., .553, 0.)
  , vec3(1., .859, 0.)
  , vec3(0., .839,  .098)
  , vec3(0., .624, 1.)
  );

// positions of all the dimples in the dice
vec3[21] dips = vec3[21]
  // one
  ( vec3( 0.,    0.,    0.31)
  // two
  , vec3( 0.31,  0.15,  0.15)
  , vec3( 0.31, -0.15, -0.15)
  // three
  , vec3( 0.15,  0.31,  0.15)
  , vec3( 0.,    0.31,  0.  )
  , vec3(-0.15,  0.31, -0.15)
  // four
  , vec3( 0.15, -0.31,  0.15)
  , vec3(-0.15, -0.31,  0.15)
  , vec3( 0.15, -0.31, -0.15)
  , vec3(-0.15, -0.31, -0.15)
  // five
  , vec3(-0.31,  0.,    0.  )
  , vec3(-0.31, -0.15, -0.15)
  , vec3(-0.31, -0.15,  0.15)
  , vec3(-0.31,  0.15, -0.15)
  , vec3(-0.31,  0.15,  0.15)
  // six
  , vec3( 0.15, -0.15, -0.31)
  , vec3( 0.15,  0.,   -0.31)
  , vec3( 0.15,  0.15, -0.31)
  , vec3(-0.15, -0.15, -0.31)
  , vec3(-0.15,  0.,   -0.31)
  , vec3(-0.15,  0.15, -0.31)
  );

vec3 rotate (vec3 p, vec3 r) {
  mat3x3 rotX = mat3x3(
    1, 0,         0,
    0, cos(r.x), -sin(r.x),
    0, sin(r.x), cos(r.x)
  );
  mat3x3 rotY = mat3x3(
    cos(r.y),  0, sin(r.y),
    0,         1, 0,
    -sin(r.y), 0, cos(r.y)
  );
  mat3x3 rotZ = mat3x3(
    1, 0,         0,
    0, cos(r.z), -sin(r.z),
    0, sin(r.z), cos(r.z)
  );
  return rotX * rotY * rotZ * p;
}

float sphere (vec3 p, float radius) {
  return length(p) - radius ;
}

float box (vec3 p, vec3 c) {
  vec3 q = abs(p) - c;
  return min(0., max(q.x, max(q.y,q.z))) - 0.02 + length(max(q,0.));
}

float map (vec3 p) {
  vec3 b = floor(mod(p, 15.) / 3.);
  p = mod(p, 3.) - 1.5;

  // rotate each dice a bit differently
  p = rotate(p, vec3(time * 0.3 + b.x, time * 0.7 + b.y, time * 0.111 + b.z));
  float s = sphere(p, 0.45);
  float c = box(p,vec3(0.29));
  float dice = max(s,c);
  
  //short circuting for better performance
  if (dice > 0.001) return dice;
 
  float d = sphere(p + dips[0], 0.06);
  for (int i = 1; i <= 21; i++) {
    d = min(d, sphere(p + dips[i], 0.06));
  }
  return max(dice, -d);
}

vec3 get_normal (vec3 p) {
  vec2 eps = vec2(0.0001, 0.);
  return normalize( vec3(
    map(p+eps.xyy) - map(p-eps.xyy),
    map(p+eps.yxy) - map(p-eps.yxy),
    map(p+eps.yyx) - map(p-eps.yyx)
  ) );
}

float diffuse (vec3 n, vec3 l) {
   return dot(n, normalize(l))*.5+.5;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
  
  //mat2x2 rot = mat2x2(cos(time),-sin(time),sin(time),cos(time));
  //uv = rot * uv;
  
  //vec3 ro = vec3(.0, .0, -3.0);
  vec3 ro = vec3(mod(time * 2.5,15.), sin(time * 0.5)*1.5, -3.0);
  vec3 p = ro;
  vec3 rd = normalize (vec3(uv,1.));
  float shad = 0.;
  bool hit = false;
  
  for (float i = 0.; i < 100.; i++) {
    float d = map(p);
    if (d < 0.001) {
      shad = 1. - i / 100.;
      hit = true;
      break;
    }
    p += d * rd;
    if (p.z > 21.) break;
  }
  
  float t = length(ro-p);
  
  vec3 color;
  if (hit) {
    vec3 n = get_normal(p);
    vec3 l = vec3(.5, 2., -2.);
    int boxNum = int(mod(floor(p.x / 3. + p.y / 3. + p.z / 3.),5.));
 
    vec3 b = floor(mod(p, 15.) / 3.);
    p = mod(p, 3.) - 1.5;
    p = rotate(p, vec3(time * 0.3 + b.x, time * 0.7 + b.y, time * 0.111 + b.z));
    float d = sphere(p + dips[0], 0.06);
    for (int i = 1; i <= 21; i++) {
      d = min(d, sphere(p + dips[i], 0.06));
    }
    if (d < 0.001) { color = vec3(0.3,0.3,0.3); }
    else           { color = rbow[boxNum]; }

    color = mix(color, color * 0.5, vec3(diffuse(n,l)));
  }
  else {color = vec3(.0);}
  color = mix(color, vec3(.15,.15,.3), 1. - exp(-.005*t*t));
  
  glFragColor = vec4(color, 1);
}
