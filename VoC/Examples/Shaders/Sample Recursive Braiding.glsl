#version 420

// original https://www.shadertoy.com/view/ssVfzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time 1. * time
#define ZPOS -100. + 50. * time

float PI = acos(-1.);

mat2 rot2d(float a){
  float c = cos(a), s = sin(a);
  
  return mat2(c, s, -s, c);
}

float cyl(vec3 p, vec3 c){
  return length(p.xy - c.xy) - c.z;
}

vec3 thread(vec3 p, float m, float r, float n, float xm, float ym, float i) {
    p.z += (i * 2. * PI) / (m * n);
    p.x += xm * sin(p.z * m);
    p.y += ym * sin(p.z * m * (n - 1.));
    
    return p;
}

float recbraid(vec3 p, float m, float r) {
    float d = 10.;
    float n1 = 3.;
    float n2 = 3.;
    float n3 = 5.;
    float xm = 1.;
    float ym = 1.;

    for (float i = 0.; i < n1; i += 1.) {
        vec3 p1 = thread(p, m * .5, r, n1, 20., 20., i);
        
        for (float j = 0.; j < n2; j += 1.) {
            vec3 p2 = thread(p1, m, r, n2, 10., 10., j);
            
            for (float k = 0.; k < n3; k += 1.) {
                vec3 p3 = thread(p2, m * 4.5, r, n3, 2., 1., k);
                
            
                d = min(d, cyl(p3, vec3(0, 0, r)));
            }
        }
    }

    return d;    
}

float map(vec3 p) {
    float d = 1000.;
    float z = p.z;
    
    p.xy *= rot2d(time * .2);
    vec3 shift = vec3(0, -45, 0);
    shift.xy *= rot2d(time * .2);

    d = min(d, recbraid(p - shift, .025 , .5));
    
    return d;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

  vec3 col = vec3(0);
  vec3 ro = vec3(0, 0., ZPOS);
  vec3 rd = normalize(vec3(uv.x, uv.y, 1.));
  rd.yz *= rot2d(-.3);

  float d = 0.;
  vec3 glow = vec3(0);

  for (int i = 0; i < 100; i++) {
    vec3 p = ro + d * rd;
    float ds = map(p);
    
    if (ds < 0.01 || ds > 100.) {
      break;
    }
    d += ds * .7;
  }
  
  vec3 p = ro + d * rd;
  vec2 e = vec2(0.01, 0);
  vec3 n = normalize(map(p) - 
    vec3(
      map(p - e.xyy),
      map(p - e.yxy),
      map(p - e.yyx)
    )
  );

  vec3 lp = ro;
  vec3 tl = lp - p;
  vec3 tln = normalize(tl);
  float dif = dot(tln, n);
  
  col = vec3(dif);
  glFragColor = vec4(col, 1.);
}
