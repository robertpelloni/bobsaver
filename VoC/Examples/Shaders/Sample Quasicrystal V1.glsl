#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wtKSRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// by natpbs
// suggested usage: click the 'pause' button
// and drag the mouse around on the canvas

//#define DRAW_GRID
//#define FAST_VERSION
//#define DEBUG

struct vec5 {
 vec2 a;
 vec3 b;
};

struct mat5 {
 mat2 a; mat2x3 b;
 mat3x2 c; mat3 d;
};

const float tau = 2.*acos(-1.);
const float a = sqrt(2./5.);
const float b = 2.*acos(-1.)/5.;
const mat5 B = mat5(
 a * mat2(
  1.,cos(b),
  0.,sin(b)
 ),
 a * mat2x3(
  cos(2.*b),cos(3.*b),cos(4.*b),
  sin(2.*b),sin(3.*b),sin(4.*b)
 ),
 a * mat3x2(
  1.,cos(2.*b),
  0.,sin(2.*b),
  sqrt(.5),sqrt(.5)
 ),
 a * mat3(
  cos(4.*b),cos(b),cos(3.*b),
  sin(4.*b),sin(b),sin(3.*b),
  sqrt(.5),sqrt(.5),sqrt(.5)
 )
);

vec3 offset3;
vec5 offset5;

vec5 fiveFromTwo(vec2 p2) {
 vec5 p5 = vec5(
  B.a * p2,
  B.b * p2
 );
 return p5;
}

vec5 fiveFromThree(vec3 p3) {
 vec5 p5 = vec5(
  B.c * p3,
  B.d * p3
 );
 return p5;
}

vec2 twoFromFive(vec5 p5) {
 vec2 p2 = p5.a * B.a + p5.b * B.b;
 return p2;
}

vec3 threeFromFive(vec5 p5) {
 vec3 p3 = p5.a * B.c + p5.b * B.d;
 return p3;
}

vec5 snapToGrid(vec5 p) {
 // note that floor(x+.5)
 p.a = floor(.5 + p.a);
 p.b = floor(.5 + p.b);
 return p;
}

vec5 getNeighbor(vec5 p, int k) {
 float sig = (k&1) == 0 ? 1. : -1.;
 k >>= 1;
 if (k<2) {
  p.a[k] += sig;
 } else {
  p.b[k-2] += sig;
 }
 return p;
}

bool isInWindow(vec5 p5) {
 vec3 p = threeFromFive(p5);
    p -= offset3;
 const vec3 base[5] = vec3[](
  vec2(1,0) * B.c,
  vec2(0,1) * B.c,
  vec3(1,0,0) * B.d,
  vec3(0,1,0) * B.d,
  vec3(0,0,1) * B.d
 );
    for (int i=0; i<4; i++) {
        for (int j=i+1; j<5; j++) {
            vec3 n = normalize(cross(base[i],base[j]));
            float d = abs(dot(p,n));
            float t = 0.;
            for (int k=0; k<5; k++) {
                if (k==i || k==j) {
                    continue;
                }
                t += abs(dot(base[k],n));
            }
            if (d > .5*t) {
                return false;
            }
        }
    }
 return true;
}

float drawPoint(vec2 p, vec2 q) {
 float d = distance(p,q);
 d = smoothstep(-.1,0.,-d);
 return d;
}

float drawLine(vec2 p, vec2 a, vec2 b) {
 vec2 ap = p - a;
 vec2 ab = b - a;
 float t = dot(ap,ab) / dot(ab,ab);
 t = clamp(t,0.,1.);
 vec2 q = a + t * ab;
 float d = distance(p,q);
 d = smoothstep(-.03,0.,-d);
 return d;
}

float drawGrid(vec5 p, vec5 q) {
 vec2 a = abs(p.a - q.a);
 vec3 b = abs(p.b - q.b);
 float d = max(
  max(a.x,a.y),
  max(b.x,max(b.y,b.z))
 );
 d = smoothstep(.48,.5,d);
 return d;
}

void main(void) {
 glFragColor = vec4(vec3(0),1);
 vec2 p2 = (gl_FragCoord.xy - .5*resolution.xy) / resolution.x;
 p2 *= 16.;
 vec5 p5 = fiveFromTwo(p2);
    //if (mouse*resolution.xy.z > 0.) {
        offset3 = vec3(
            1. * (mouse*resolution.xy.xy - .5*resolution.xy) / resolution.x,
            0);
        //);
        offset5 = fiveFromThree(offset3);
        p5.a += offset5.a;
        p5.b += offset5.b;
    //} else {
    //    offset3 = vec3(0);
    //    offset5 = vec5(vec2(0),vec3(0));
    //}
 vec5 q5 = snapToGrid(p5);
 vec2 q2 = twoFromFive(q5);
 vec3 q3 = threeFromFive(q5);
 float d = length(q3);
 glFragColor.r += drawPoint(p2,q2);
 int count = 0;
 for (int j=0; j<10; j++) {
  vec5 r5 = getNeighbor(q5,j);
  if (isInWindow(r5)) {
   count++;
   vec2 r2 = twoFromFive(r5);
   glFragColor.r += drawPoint(p2,r2);
   glFragColor.b += drawLine(p2,q2,r2);
   #ifndef FAST_VERSION
   for (int k=0; k<10; k++) {
       if ((k|1)==(j|1) && (k&1) != (j&1)) {
           continue;
       }
    vec5 s5 = getNeighbor(r5,k);
    if (isInWindow(s5)) {
     vec2 s2 = twoFromFive(s5);
     glFragColor.r += drawPoint(p2,s2);
     glFragColor.b += drawLine(p2,r2,s2);
    }
   }
   #endif
  }
 }
    #ifdef DRAW_GRID
        glFragColor.rgb += .4*drawGrid(p5,q5);
    #endif
    #ifdef DEBUG
 if (!isInWindow(q5)) {
  glFragColor.rb = vec2(1.);
 }
 count = 0
  | ((count & 1) << 4)
  | ((count & 2) << 1)
  | ((count & 4) >> 1)
  | ((count & 8) >> 5);
 glFragColor.rgb += float(count) / 64.;
    #endif
}
